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
- **catalogo_itens** — catálogo compartilhado da plataforma (ex: "Ração para
  Cães", "Banho e Tosa", "Consulta Veterinária Geral"), com `tipo_negocio`,
  `tipo` (produto/serviço) e `categoria`. É mantido pela equipe direto no SQL
  Editor (RLS só permite leitura, sem policy de escrita). Cada linha aqui é o
  que o tutor pede no catálogo; cada parceiro cria uma ou mais **ofertas**
  (`itens`) apontando pra uma linha daqui.
- **categorias** — agrupam os itens de um parceiro, no cardápio *dele* (ex: ele
  pode juntar vários itens do catálogo compartilhado numa categoria
  "Promoções"). Diferente da `categoria` fixa em `catalogo_itens`, que é do
  marketplace como um todo.
- **itens** — a oferta de um parceiro pra um item do catálogo compartilhado
  (`catalogo_item_id`, ver abaixo), com preço, descrição e prazo próprios;
  opcionalmente pertence a uma categoria do cardápio do parceiro
  (`categoria_id`, nullable). Um parceiro não pode ter duas ofertas pro mesmo
  item do catálogo (`unique (parceiro_id, catalogo_item_id)`).
- **complementos** — opcionais de um item (ex: "Embalagem para presente"), com nome,
  preço e disponibilidade próprios.
- **pedidos** — compra de produto ou agendamento de serviço. No modelo broadcast,
  nasce **sem** `parceiro_id`/`item_id`/`valor_total` definidos (ficam `null`) — só
  são preenchidos quando um parceiro aceita. Guarda `catalogo_item_id` (o que foi
  pedido) desde a criação, usado pra achar os parceiros elegíveis.
- **pedido_candidatos** — quais parceiros foram notificados de um pedido em aberto
  (uma linha por parceiro elegível), com status `pendente` ou `recusado`.
- **avaliacoes** — nota do tutor sobre um pedido concluído; um trigger recalcula a
  nota média do parceiro e marca o pedido como `avaliado`.

## Catálogo por item (não por parceiro)

`catalogo.html` tem duas abas: **"Por item"** (padrão) mostra o catálogo
compartilhado agrupado por categoria, com "a partir de R$ X" e quantos
parceiros oferecem aquele item com os filtros atuais; **"Por parceiro"** é a
navegação antiga, pra quem quer ver o cardápio completo de um estabelecimento
específico. As duas levam ao mesmo fluxo de pedido (a caixa "Fazer pedido"),
só que "por item" o tutor nunca escolhe um parceiro antes de pedir — o que é o
próprio ponto do modelo broadcast (pedir "o quê", não "de quem").

## O modelo de despacho "broadcast"

Ao criar um pedido, o tutor não escolhe um parceiro específico — o pedido fica "em
aberto", com o `catalogo_item_id` do que foi pedido. O sistema então (função
compartilhada `criarPedidoBroadcast` em `js/app.js`, usada tanto por
`catalogo.html` quanto por `parceiro.html`):

1. Busca todas as ofertas (`itens`) desse mesmo `catalogo_item_id`, disponíveis,
   de parceiros do **bairro do próprio tutor** (do perfil dele, não do parceiro
   cuja página ele calhou de visitar — antes da reformulação do catálogo
   compartilhado, a elegibilidade comparava texto livre de nome e usava o
   bairro do parceiro visitado, o que só funcionava bem partindo da página de
   um parceiro).
2. Cria uma linha em `pedido_candidatos` para cada uma (todas notificadas ao
   mesmo tempo — "quem aceitar primeiro, leva").
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
