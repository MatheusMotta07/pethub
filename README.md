# PetHub: protótipo navegável (MVP)

Protótipo do marketplace pet descrito no trabalho de Negócios Digitais (Univille, 2026):
tutores pedem produtos e agendam serviços (veterinário, banho e tosa, hospedagem, cuidador)
com parceiros de Joinville/SC, com perfil do pet centralizado, avaliações e despacho em
broadcast (o pedido vai a todos os parceiros elegíveis ao mesmo tempo; quem aceitar primeiro
atende).

Stack: HTML/CSS/JS puro (sem build step) + [Supabase](https://supabase.com) (auth + Postgres),
seguindo o mesmo padrão do projeto `mapa-clientes`.

> Contexto completo do projeto (negócio, arquitetura, design, histórico de decisões,
> deploy) está registrado em [`docs/00-indice.md`](docs/00-indice.md).

## Como rodar

1. **Crie um projeto no Supabase** (gratuito) em https://supabase.com/dashboard.
2. Abra o **SQL Editor** do projeto e rode o conteúdo de [`supabase-setup.sql`](supabase-setup.sql)
   inteiro. Ele cria as tabelas, as políticas de RLS e o trigger de nota média.
3. (Opcional) Rode [`seed-exemplo.sql`](seed-exemplo.sql) para popular o catálogo com
   3 parceiros de exemplo (pet shop, veterinário e cuidador) e poder testar o lado do
   tutor sem precisar cadastrar parceiros manualmente.
4. Em **Project Settings > API**, copie a *Project URL* e a *anon public key*.
5. Edite [`config.js`](config.js) e cole os dois valores.
6. Sirva a pasta como site estático (os arquivos usam `fetch`/módulos do Supabase via CDN,
   então precisa de um servidor local, não abrir o `.html` direto com `file://`). Por exemplo:
   ```powershell
   npx serve .
   ```
   ou qualquer outro servidor estático (Live Server do VS Code, `python -m http.server`, etc.).
7. Acesse a página e crie uma conta de **tutor** e uma de **parceiro** para testar os dois lados.

## Fluxo coberto pelo MVP

- **Tutor**: cadastro → perfil do pet (vacinas/alergias/rotina) → catálogo (filtra por tipo de
  negócio, bairro, busca e nota) → página do parceiro (compara itens, preço e avaliações) →
  pedido de produto ou agendamento de serviço → acompanhamento de status em "Meus pedidos" →
  avaliação após conclusão.
- **Parceiro**: cadastro com tipo de negócio e documento (CNPJ/CRMV) → painel com métricas
  (pedidos pendentes, nota média, avaliações) → cadastro/pausa/exclusão de itens → aceitar ou
  recusar pedidos recebidos, iniciar atendimento e concluir.
- **Broadcast (quem aceitar primeiro, leva)**: ao pedir, o tutor cria um pedido "em aberto" (sem
  parceiro definido ainda) e o sistema notifica (`pedido_candidatos`) todos os parceiros do
  mesmo tipo de negócio e bairro que têm aquele item disponível. O primeiro que clicar em
  "Aceitar" fecha o pedido (define parceiro/item/valor); a checagem é atômica no banco (via RLS
  condicionada a `status = 'pendente'`), então mesmo que dois parceiros aceitem quase ao mesmo
  tempo, só o primeiro UPDATE tem efeito; o segundo vê a mensagem de que o pedido já foi
  aceito. Recusar só tira aquele parceiro da disputa; o pedido segue em aberto para os demais.

## O que é mock/simplificado neste protótipo

- **Pagamento**: não há gateway real; o pedido é "confirmado" direto, sem cobrança.
- **Roteamento por região**: simplificado para "mesmo bairro", sem geolocalização real.
- **Verificação de CNPJ/CRMV**: o campo é salvo, mas a validação (`verificado = true`) não é
  automática: hoje só é marcada manualmente no banco (seria uma tela de admin em uma v2).
- **Lembretes de recompra/vacina**: citados no Canvas e no Business Model, mas ainda não
  implementados nesta versão (próximo passo natural do roadmap).
- **Destaque pago / plano premium do parceiro**: fontes de receita do Canvas, fora do escopo
  deste MVP de validação de fluxo.

## Estrutura

```
pethub/
├── index.html          landing page
├── auth.html           login / cadastro (tutor ou parceiro)
├── catalogo.html        lista de parceiros com filtros
├── parceiro.html        detalhe do parceiro, itens, pedido/agendamento, avaliações
├── meus-pedidos.html     pedidos do tutor + avaliação
├── painel.html           painel do parceiro (itens + pedidos)
├── perfil.html           dados pessoais, pets (tutor) ou dados do negócio (parceiro)
├── config.js             credenciais do Supabase (edite com as suas)
├── supabase-setup.sql    schema (inclui pedido_candidatos p/ broadcast) + RLS + trigger de nota média
├── seed-exemplo.sql      dados de exemplo opcionais
├── css/style.css
└── js/
    ├── supabase-client.js
    └── app.js            helpers compartilhados (toast, navbar, auth guard, formatação)
```

Equipe: Carlos Brazão · Jorge Dutra · Juliana Seemann · Lorenzo Poncio · Matheus Motta ·
Univille, Negócios Digitais, 2026.
