# Deploy e infraestrutura

← [[00-indice|Índice]]

## Código

- Repositório: [github.com/MatheusMotta07/pethub](https://github.com/MatheusMotta07/pethub)
  (**privado**).
- Branch única: `master`. Sem CI configurado — o próprio deploy da Vercel é o
  "teste" de que o build estático sobe sem erro.

## Hospedagem (Vercel)

- Projeto: `matheus-motta2/pethub`, conectado ao repositório do GitHub — todo
  `git push` para `master` dispara automaticamente um novo deploy de produção.
- Site é estático (sem build step, sem framework), detectado automaticamente pela
  Vercel.
- **URL de produção:** <https://pethub-univille.vercel.app> (domínio customizado,
  vinculado ao projeto — acompanha deploys futuros automaticamente).
- Aliases antigos que continuam ativos: `pethub-alpha.vercel.app`,
  `pethub-matheus-motta2.vercel.app`.
- Deploy inicial foi feito via Vercel CLI (`npx vercel`), autenticado por device
  code (o usuário confirmou o login no próprio navegador — o agente não tem acesso
  a credenciais de conta).

## Banco de dados (Supabase)

- Projeto: "PetHub", ref `emzqbsfllzmevvxfmwez`.
- Schema completo em `supabase-setup.sql` na raiz do projeto — é a fonte única de
  verdade; rodar o arquivo inteiro no SQL Editor de um projeto Supabase novo recria
  todas as tabelas, políticas de RLS, triggers e o bucket de Storage.
- `seed-exemplo.sql` (opcional) popula o catálogo com parceiros de exemplo pra
  testar o lado do tutor sem precisar cadastrar parceiros manualmente.
- Migrações aplicadas diretamente no banco em produção foram feitas via SQL Editor
  do painel do Supabase (acessado pelo navegador), sempre com o script
  correspondente também salvo em `supabase-setup.sql` para manter os dois em sincronia.

## Como publicar uma mudança

1. Editar os arquivos estáticos (`*.html`, `css/style.css`, `js/*.js`) e, se
   necessário, `supabase-setup.sql`.
2. Se houve mudança de schema: aplicar o SQL correspondente no projeto Supabase real
   (SQL Editor), **antes ou junto** de publicar o front-end que depende dela.
3. `git add` → `git commit` → `git push` para `master`.
4. A Vercel detecta o push e publica automaticamente; não é preciso rodar `vercel
   --prod` manualmente depois do primeiro deploy.

## Credenciais

- `config.js` guarda `SUPABASE_URL` e a `anon key` pública — segura por design do
  Supabase (toda proteção real vem das políticas de RLS, não do sigilo da chave),
  por isso pode ficar versionada no repositório mesmo sendo privado.
