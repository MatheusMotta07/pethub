# Arquitetura técnica e modelo de dados

← [[00-indice|Índice]]

## Stack

- **Front-end:** HTML/CSS/JS puro, sem build step e sem framework (mesmo padrão do
  projeto irmão `mapa-clientes`, na mesma pasta de trabalho). Os arquivos usam
  `fetch`/módulos do Supabase via CDN, então precisam ser servidos por um servidor
  estático (não abrir o `.html` direto com `file://`).
- **Back-end:** [Supabase](https://supabase.com) — Postgres + Auth + Storage, tudo
  acessado do navegador via a `anon key` pública, protegido por Row Level Security
  (RLS). Não existe servidor de aplicação próprio.
- **Hospedagem:** Vercel (site estático), ver [[05-deploy-e-infraestrutura]].

## Modelo de dados

Tabelas principais (schema completo e atualizado em `supabase-setup.sql`, que é a
fonte única de verdade — rodar inteiro em um projeto Supabase novo recria tudo):

- **profiles** — um por usuário autenticado, `tipo` = `'tutor'` ou `'parceiro'`.
- **pets** — perfil do pet (vacinas, alergias, rotina, `foto_url`), pertence a um
  tutor; é o mesmo perfil reaproveitado em qualquer parceiro escolhido.
- **parceiros** — pet shops, veterinários, hospedagem, cuidadores; tem
  `tipo_negocio`, `bairro`, nota média, documento (CNPJ/CRMV).
- **categorias** — agrupam os itens de um parceiro (ex: "Rações", "Banho e tosa").
- **itens** — produto ou serviço oferecido por um parceiro; opcionalmente pertence a
  uma categoria (`categoria_id`, nullable).
- **complementos** — opcionais de um item (ex: "Embalagem para presente"), com nome,
  preço e disponibilidade próprios.
- **pedidos** — compra de produto ou agendamento de serviço. No modelo broadcast,
  nasce **sem** `parceiro_id`/`item_id`/`valor_total` definidos (ficam `null`) — só
  são preenchidos quando um parceiro aceita.
- **pedido_candidatos** — quais parceiros foram notificados de um pedido em aberto
  (uma linha por parceiro elegível), com status `pendente` ou `recusado`.
- **avaliacoes** — nota do tutor sobre um pedido concluído; um trigger recalcula a
  nota média do parceiro e marca o pedido como `avaliado`.

## O modelo de despacho "broadcast"

Ao criar um pedido, o tutor não escolhe um parceiro específico — o pedido fica "em
aberto". O sistema então:

1. Busca todos os parceiros do mesmo `tipo_negocio` e `bairro` que têm aquele item
   disponível.
2. Cria uma linha em `pedido_candidatos` para cada um (todos notificados ao mesmo
   tempo — "quem aceitar primeiro, leva").
3. "Aceitar" é um `UPDATE` em `pedidos` **condicionado a `status = 'pendente'`**
   (`.eq("status", "pendente")`), preenchendo `parceiro_id`/`item_id`/`valor_total` e
   mudando o status para `aceito`.
4. Como a condição do `UPDATE` já exige o status antigo, só o **primeiro** `UPDATE`
   que ainda encontra `status = 'pendente'` tem efeito — os demais parceiros, ao
   tentar aceitar depois, recebem de volta zero linhas afetadas e sabem que
   "esse pedido já foi aceito por outro parceiro". Não existe lock explícito: a
   corrida é resolvida pelo próprio banco.
5. "Recusar" só marca aquele parceiro como `recusado` na sua candidatura — o pedido
   continua em aberto para os demais (sem repasse manual, já foi oferecido a todos).

## RLS e o problema da recursão

Toda política de RLS que precisaria reconsultar uma tabela que depende dela mesma
(ex: a policy de `pedidos` reconsultando `pedido_candidatos`, que por sua vez
reconsulta `pedidos`) dispara o erro `infinite recursion detected in policy for
relation X`.

**Padrão de solução usado:** funções `security definer` (rodam como dono da tabela,
não disparam RLS de novo) — `tutor_e_dono_do_pedido`, `eh_candidato_do_pedido`,
`eh_candidato_pendente_do_pedido`. Qualquer policy nova que precise de uma checagem
cruzada parecida deve seguir esse mesmo padrão em vez de tentar resolver com
subqueries diretas.

Categorias, itens e complementos **não** precisaram desse padrão — a checagem de
dono é direta (`parceiro_id in (select id from parceiros where profile_id =
auth.uid())`, ou um hop a mais para complementos via `item_id`), porque não há
referência circular entre essas tabelas.

## Storage (upload de arquivos)

Um bucket público: **`pet-fotos`** (fotos de pets, path
`<tutor_id>/<pet_id>-<timestamp>.ext`). Políticas de insert/update/delete
restringem cada tutor à sua própria pasta (`storage.foldername(name)[1] =
auth.uid()::text`); leitura é pública (bucket `public = true`).

> **Bug conhecido e contornado:** fazer upload com `upsert: true` para sobrescrever
> o mesmo caminho estava sendo barrado pela RLS (`new row violates row-level
> security policy`, 403/AccessDenied) mesmo com as policies corretas — a causa raiz
> não foi aprofundada. Um upload simples (sem upsert, caminho novo) funcionava
> normalmente. A solução adotada foi gerar sempre um nome de arquivo novo
> (`<pet_id>-<timestamp>.ext`) em vez de reusar o mesmo caminho, evitando o upsert
> por completo. A foto antiga fica órfã no bucket — aceitável para um protótipo.

## Ambiente de desenvolvimento

- Servidor local: `python -m http.server 8787`, configurado como `pethub-dev` em
  `.claude/launch.json` (na raiz de `Dev I`, não dentro de `pethub/`).
- Projeto Supabase: org do usuário, nome "PetHub", ref `emzqbsfllzmevvxfmwez`.
- Credenciais (URL + anon key) ficam em `config.js` — a anon key é segura por design
  do Supabase (protegida por RLS), por isso pode ficar em um arquivo versionado.
