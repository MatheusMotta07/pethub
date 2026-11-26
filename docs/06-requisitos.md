# Requisitos funcionais e não funcionais

← [[00-indice|Índice]]

Levantamento de requisitos a partir do que está implementado e documentado em
[[01-visao-geral-e-negocio|visão geral]] e [[02-arquitetura-e-dados|arquitetura]].
Serve como referência pra avaliar cobertura em [[07-casos-de-teste|casos de teste]]
e como material de apoio pra justificar escopo num pitch.

## Requisitos funcionais (RF)

### Autenticação e perfil

| ID | Descrição |
|----|-----------|
| RF01 | O sistema deve permitir que um novo usuário se cadastre como **tutor** ou **parceiro**, informando e-mail e senha (Supabase Auth). |
| RF02 | O sistema deve permitir login e logout do usuário cadastrado. |
| RF03 | O sistema deve criar um registro em `profiles` vinculado ao usuário autenticado, guardando o `tipo` (`tutor` ou `parceiro`). |
| RF04 | O sistema deve permitir que um parceiro cadastre dados do estabelecimento: `tipo_negocio`, bairro e documento (CNPJ/CRMV). |

### Perfil do pet (lado tutor)

| ID | Descrição |
|----|-----------|
| RF05 | O tutor deve poder cadastrar um pet com nome, espécie, raça, data de nascimento, vacinas, alergias e rotina. |
| RF06 | O tutor deve poder editar qualquer um desses campos depois de criado o pet. |
| RF07 | O tutor deve poder enviar (upload) uma foto real do pet, exibida como avatar em "Meu perfil". |
| RF08 | O perfil do pet deve ser único e reaproveitado em qualquer pedido, independente do parceiro escolhido. |

### Catálogo (lado parceiro)

| ID | Descrição |
|----|-----------|
| RF09 | O parceiro deve poder criar, editar, pausar e excluir itens (produtos ou serviços) do seu catálogo. |
| RF10 | O parceiro deve poder agrupar itens em categorias (ex.: "Rações", "Banho e tosa"). |
| RF11 | O parceiro deve poder cadastrar complementos por item (opcionais com nome, preço e disponibilidade próprios). |
| RF12 | O tutor deve poder navegar o catálogo filtrando por bairro e tipo de negócio do parceiro. |

### Pedidos e despacho (modelo broadcast)

| ID | Descrição |
|----|-----------|
| RF13 | Ao criar um pedido, o tutor não escolhe um parceiro específico; o pedido nasce em aberto (sem `parceiro_id`/`item_id`/`valor_total`). |
| RF14 | O sistema deve notificar **simultaneamente** todos os parceiros do mesmo `tipo_negocio` e `bairro` que oferecem aquele item, criando uma linha em `pedido_candidatos` para cada um. |
| RF15 | Um parceiro deve poder **aceitar** um pedido pendente; o primeiro aceite válido preenche `parceiro_id`/`item_id`/`valor_total` e muda o status para `aceito`. |
| RF16 | Ao aceitar, o pedido deve deixar de estar disponível para os demais parceiros candidatos (sem repasse manual, pois já foi oferecido a todos). |
| RF17 | Um parceiro deve poder **recusar** um pedido; a recusa marca apenas a própria candidatura, sem afetar a disponibilidade para os demais. |
| RF18 | O tutor deve poder acompanhar o status do pedido ("Meus pedidos"): pendente, aceito, concluído, avaliado. |

### Avaliação

| ID | Descrição |
|----|-----------|
| RF19 | O tutor deve poder avaliar (nota) um pedido concluído. |
| RF20 | O sistema deve recalcular automaticamente a nota média do parceiro a cada nova avaliação e marcar o pedido como `avaliado`. |

### Conteúdo ilustrativo

| ID | Descrição |
|----|-----------|
| RF21 | As telas iniciais (landing e login/cadastro) devem exibir um carrossel navegável com fotos ilustrativas de pets, deixando claro que não são pets reais cadastrados. |

## Requisitos não funcionais (RNF)

| ID | Categoria | Descrição |
|----|-----------|-----------|
| RNF01 | Segurança | Todo acesso a dados deve respeitar Row Level Security (RLS) no Postgres/Supabase, garantindo que um usuário só leia/altere seus próprios dados (pets, pedidos, itens do próprio parceiro). |
| RNF02 | Segurança | Checagens cruzadas entre tabelas com referência circular (`pedidos` ↔ `pedido_candidatos`) devem usar funções `security definer`, evitando recursão infinita de política. |
| RNF03 | Segurança | Credenciais de banco (anon key) podem ficar versionadas porque a proteção real é a RLS, não o sigilo da chave; nenhum segredo de maior privilégio deve ser exposto no front-end. |
| RNF04 | Confiabilidade / concorrência | A disputa por um pedido em aberto entre múltiplos parceiros deve ser resolvida de forma atômica pelo próprio banco (`UPDATE` condicionado a `status = 'pendente'`), sem lock explícito e sem permitir que dois parceiros aceitem o mesmo pedido. |
| RNF05 | Usabilidade | A interface deve comunicar visualmente o estado do pedido (pendente = carimbo tracejado, aceito/concluído = carimbo sólido), reforçando a mecânica de negócio em vez de ser decoração neutra. |
| RNF06 | Usabilidade | O fluxo deve ser navegável ponta a ponta nos dois lados do marketplace (tutor e parceiro) sem necessidade de treinamento prévio. |
| RNF07 | Desempenho | Por ser front-end estático sem build step, as páginas devem carregar rapidamente mesmo em conexões simples, sendo servidas diretamente por CDN estática (Vercel). |
| RNF08 | Portabilidade / compatibilidade | O front-end deve funcionar nos principais navegadores modernos e ser responsivo (mobile e desktop), já que tutores e parceiros podem acessar de qualquer dispositivo. |
| RNF09 | Disponibilidade | O deploy deve ser automático a cada `git push` para `master`, mantendo o ambiente de produção sempre sincronizado com o repositório. |
| RNF10 | Manutenibilidade | O schema do banco deve ter uma única fonte de verdade versionada (`supabase-setup.sql`), capaz de recriar todas as tabelas, políticas e o bucket de Storage em um projeto Supabase novo. |
| RNF11 | Armazenamento | Uploads de foto de pet devem evitar conflito de RLS usando sempre um nome de arquivo novo por envio (`<pet_id>-<timestamp>.ext`), em vez de sobrescrever (`upsert`) o mesmo caminho. |

## Fora de escopo neste MVP (mocks conscientes)

Já levantado em [[01-visao-geral-e-negocio]], mas vale repetir aqui como limite dos
requisitos acima, útil pra responder perguntas de plateia num pitch:

- Pagamento real (gateway) — pedido é confirmado sem cobrança.
- Geolocalização real — roteamento simplificado para "mesmo bairro".
- Verificação automática de CNPJ/CRMV — hoje é marcação manual no banco.
- Lembretes de recompra/vacina — previstos no roadmap, não implementados.
- Destaque pago / plano premium do parceiro — fonte de receita do Canvas, fora do MVP.
