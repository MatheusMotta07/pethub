# Casos de teste

← [[00-indice|Índice]]

Casos de teste derivados dos requisitos em [[06-requisitos|requisitos funcionais e
não funcionais]]. Divididos em dois grupos: **casos de teste de usuário** (ponto de
vista de quem usa, cenário Dado/Quando/Então) e **casos de teste de software**
(ponto de vista técnico/QA, cobrindo regras de negócio e os pontos de atenção já
registrados em [[02-arquitetura-e-dados|arquitetura]] e
[[04-historico-de-decisoes|histórico de decisões]]).

## Casos de teste de usuário

Formato Dado/Quando/Então, pensado pra validação manual do fluxo navegável (o
próprio objetivo do MVP, ver [[01-visao-geral-e-negocio]]).

### CTU-01 — Cadastro de tutor e do primeiro pet

- **Dado** que sou uma pessoa nova no PetHub,
- **Quando** eu me cadastro como tutor e preencho nome, espécie, raça, data de
  nascimento, vacinas, alergias e rotina do meu pet,
- **Então** devo ver o pet salvo em "Meu perfil", com os dados exatamente como
  preenchi.

### CTU-02 — Edição completa do pet

- **Dado** que já tenho um pet cadastrado,
- **Quando** eu abro a edição em "Meu perfil" e altero qualquer campo (incluindo
  espécie, raça, vacinas, alergias ou rotina, não só nome/foto),
- **Então** as mudanças devem ser salvas e refletidas imediatamente na tela.

### CTU-03 — Upload de foto do pet

- **Dado** que estou editando meu pet,
- **Quando** eu envio uma foto nova,
- **Então** o avatar circular do pet deve atualizar para a nova foto, sem erro de
  permissão.

### CTU-04 — Tutor navega o catálogo por bairro

- **Dado** que quero um serviço de banho e tosa no meu bairro,
- **Quando** eu filtro o catálogo por tipo de negócio e bairro,
- **Então** devo ver apenas parceiros compatíveis com o filtro.

### CTU-05 — Tutor faz um pedido (produto)

- **Dado** que encontrei um item disponível no catálogo,
- **Quando** eu confirmo o pedido,
- **Então** o pedido deve aparecer em "Meus pedidos" com status **pendente**
  (carimbo tracejado), sem eu precisar escolher um parceiro específico.

### CTU-06 — Tutor agenda um serviço

- **Dado** que quero agendar um banho e tosa,
- **Quando** eu escolho o serviço e confirmo,
- **Então** o agendamento deve seguir o mesmo fluxo de despacho de um pedido de
  produto (broadcast para parceiros elegíveis).

### CTU-07 — Parceiro aceita um pedido

- **Dado** que sou um parceiro com um pedido pendente na minha lista,
- **Quando** eu clico em aceitar,
- **Então** o pedido deve passar a ser meu (status **aceito**, carimbo sólido) e
  sumir da lista de pendentes dos outros parceiros.

### CTU-08 — Parceiro recusa um pedido

- **Dado** que não quero ou não posso atender um pedido pendente,
- **Quando** eu clico em recusar,
- **Então** o pedido deve sair da minha lista, mas continuar disponível para os
  outros parceiros candidatos.

### CTU-09 — Tutor acompanha e avalia o pedido

- **Dado** que meu pedido foi marcado como concluído pelo parceiro,
- **Quando** eu abro "Meus pedidos" e envio uma nota,
- **Então** o pedido deve mudar para status **avaliado** e eu não devo conseguir
  avaliar de novo.

### CTU-10 — Parceiro gerencia o catálogo

- **Dado** que sou um parceiro,
- **Quando** eu crio uma categoria, um item dentro dela e um complemento para esse
  item,
- **Então** tudo deve aparecer organizado no meu painel e refletir corretamente para
  o tutor no catálogo.

### CTU-11 — Dois parceiros disputam o mesmo pedido

- **Dado** que dois parceiros elegíveis veem o mesmo pedido pendente ao mesmo tempo,
- **Quando** ambos clicam em aceitar quase simultaneamente,
- **Então** apenas um deve conseguir aceitar; o outro deve ver uma mensagem de que o
  pedido já foi aceito por outro parceiro.

## Casos de teste de software

Formato técnico (ID, pré-condição, passos, resultado esperado), pensado pra quem for
validar a implementação ou escrever testes automatizados no futuro.

| ID | Objetivo | Pré-condição | Passos | Resultado esperado |
|----|----------|--------------|--------|---------------------|
| CTS-01 | Isolamento de RLS entre tutores | Dois tutores (A e B) autenticados, cada um com pelo menos um pet | Autenticado como tutor A, tentar ler/editar um pet pertencente a B via query direta | A operação deve retornar zero linhas ou erro de permissão; dados de B nunca retornam |
| CTS-02 | Isolamento de RLS entre parceiros | Dois parceiros (A e B), cada um com itens cadastrados | Autenticado como parceiro A, tentar editar/excluir um item de B | Operação negada pela policy de RLS |
| CTS-03 | Criação de pedido em broadcast | Pelo menos 2 parceiros elegíveis (mesmo `tipo_negocio`/`bairro`, item disponível) | Tutor cria um pedido do item | Deve existir uma linha em `pedido_candidatos` para cada parceiro elegível, todas com status `pendente`; `pedidos.parceiro_id`/`item_id`/`valor_total` permanecem `null` |
| CTS-04 | Filtro de elegibilidade do broadcast | Parceiro C é de outro bairro ou não tem o item | Tutor cria pedido | Parceiro C não deve receber candidatura em `pedido_candidatos` |
| CTS-05 | Corrida de aceite (condição atômica) | Pedido pendente com 2+ candidatos | Disparar dois `UPDATE` concorrentes com `.eq("status", "pendente")` quase ao mesmo tempo | Apenas um `UPDATE` afeta linha (1 row affected); o outro afeta 0 linhas; pedido fica com exatamente um `parceiro_id` |
| CTS-06 | Recusa não afeta outros candidatos | Pedido pendente com 2+ candidatos | Parceiro A recusa | Candidatura de A muda para `recusado`; candidaturas dos demais continuam `pendente`; pedido continua disponível para aceite |
| CTS-07 | Pedido aceito some da lista dos demais | Pedido com 2+ candidatos | Parceiro A aceita | Ao consultar a lista de pendentes do parceiro B, o pedido não deve mais aparecer |
| CTS-08 | Trigger de avaliação recalcula média | Parceiro com pelo menos 1 avaliação prévia | Tutor avalia um novo pedido concluído | `parceiros.nota_media` é recalculada corretamente (média de todas as notas); pedido muda para status `avaliado` |
| CTS-09 | Bloqueio de avaliação duplicada | Pedido já com status `avaliado` | Tentar avaliar novamente o mesmo pedido | Operação deve ser bloqueada ou idempotente, sem gerar nova linha de avaliação duplicada |
| CTS-10 | Funções `security definer` evitam recursão | Policies de `pedidos`/`pedido_candidatos` ativas | Consultar `pedidos` como parceiro candidato | Query retorna sem erro `infinite recursion detected in policy`; usa `eh_candidato_do_pedido`/`eh_candidato_pendente_do_pedido` |
| CTS-11 | Upload de foto sem conflito de RLS | Tutor autenticado, pet já com uma foto anterior | Enviar nova foto para o mesmo pet | Upload deve usar caminho novo (`<pet_id>-<timestamp>.ext`); não deve ocorrer erro 403/AccessDenied de `upsert` |
| CTS-12 | Isolamento de pasta no Storage | Dois tutores com fotos de pets no bucket `pet-fotos` | Tutor A tenta escrever/apagar no path de B (`<tutor_B_id>/...`) | Operação negada pela policy (`storage.foldername(name)[1] = auth.uid()::text`) |
| CTS-13 | Leitura pública do bucket de fotos | Bucket `pet-fotos` configurado `public = true` | Acessar a URL pública de uma foto sem autenticação | Foto deve carregar normalmente, sem exigir login |
| CTS-14 | CRUD de categoria/item/complemento | Parceiro autenticado | Criar, editar, pausar e excluir um item; adicionar/editar complemento | Cada operação reflete corretamente no banco e na tela; itens pausados não aparecem como disponíveis para novo pedido |
| CTS-15 | Categoria opcional no item | Parceiro com item sem `categoria_id` | Criar item sem associar categoria | Item deve ser aceito e exibido normalmente (campo é nullable) |
| CTS-16 | Documento do parceiro (CNPJ/CRMV) | Parceiro cadastrado | Preencher campo de documento e salvar | Valor é salvo no banco; nenhuma validação automática bloqueia o cadastro (verificação é manual, fora do MVP) |
| CTS-17 | Front-end exige servidor estático | Arquivos do projeto disponíveis localmente | Abrir um `.html` diretamente via `file://` vs. via `python -m http.server` | Via `file://`, módulos do Supabase via CDN falham; via servidor estático, a aplicação carrega normalmente |
| CTS-18 | Responsividade | Front-end publicado ou local | Abrir páginas principais (landing, catálogo, painel, meus-pedidos) em viewport mobile e desktop | Layout se adapta sem quebra visual nem scroll horizontal indesejado |
| CTS-19 | Deploy automático | Repositório conectado à Vercel | Fazer `git push` para `master` | Novo deploy de produção é disparado automaticamente e publicado em `pethub-univille.vercel.app` |
| CTS-20 | Schema reprodutível | Projeto Supabase novo e vazio | Rodar `supabase-setup.sql` inteiro no SQL Editor | Todas as tabelas, policies, triggers e o bucket de Storage são recriados sem erro |

## Rastreabilidade (requisito → caso de teste)

Mapeamento rápido pra mostrar cobertura num pitch ou numa auditoria de QA:

- RF01–RF04 (autenticação/perfil) → CTU-01, CTS-01, CTS-02
- RF05–RF08 (perfil do pet) → CTU-01, CTU-02, CTU-03, CTS-11, CTS-12, CTS-13
- RF09–RF12 (catálogo) → CTU-04, CTU-10, CTS-14, CTS-15
- RF13–RF18 (broadcast) → CTU-05, CTU-06, CTU-07, CTU-08, CTU-11, CTS-03 a CTS-07, CTS-10
- RF19–RF20 (avaliação) → CTU-09, CTS-08, CTS-09
- RF21 (carrossel) → cobertura visual manual (sem caso técnico dedicado, baixo risco)
- RNF01–RNF03 (segurança) → CTS-01, CTS-02, CTS-10, CTS-12
- RNF04 (concorrência) → CTS-05
- RNF05–RNF06 (usabilidade) → todos os CTU
- RNF07–RNF09 (desempenho/disponibilidade) → CTS-17, CTS-18, CTS-19
- RNF10 (manutenibilidade) → CTS-20
- RNF11 (storage) → CTS-11
