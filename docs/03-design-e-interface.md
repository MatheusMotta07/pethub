# Design e interface

← [[00-indice|Índice]]

## De onde saiu

A primeira versão do front-end usava o visual "padrão" que qualquer gerador de UI
produz sem direção específica: fundo creme, acento laranja, cards brancos
arredondados com sombra suave idêntica em todos, e emoji como ícone (🐾✅⚡📍✓⏱). A
pedido do usuário ("tire o aspecto de feito com IA"), o site inteiro foi redesenhado
em cima de um conceito próprio, ligado ao que o produto realmente é.

## Conceito: "ficha de despacho"

Em vez de cards de SaaS genérico, pedidos são tratados visualmente como **fichas**:

- **Pendente** (ainda não aceito) = carimbo **tracejado** — a ficha ainda não foi
  carimbada.
- **Aceito/concluído** = carimbo **sólido**, levemente girado, como se tivesse
  acabado de ser batido.

Essa é uma escolha deliberada: o visual reforça a própria mecânica de negócio do
produto (modelo broadcast — "quem carimba primeiro, leva"), em vez de ser decoração
neutra.

## Paleta e tipografia

- **Cores:** papel (bege claro) + verde-pinho (estrutura, marca, nav) + latão
  (dourado — CTA, preços, destaque). Vermelho-terracota apenas para cancelamento/erro.
- **Tipografia:** Bitter (serifada, títulos) + Work Sans (corpo/UI) + Space Mono
  (preços, códigos de pedido, texto de carimbo — reforça a ideia de "ticket
  impresso").
- **Ícones:** linha fina desenhada à mão (SVG inline), nunca emoji.

## Elementos de interface recorrentes

- **Topbar** sólida verde-pinho com underline dourado no item ativo (em vez de pílula
  arredondada flutuante).
- **`.badge`** é usado tanto para tags simples (tipo de negócio) quanto para status de
  pedido/item — quando usado como status, vira visualmente um "carimbo" (tracejado
  ou sólido conforme o estado).
- **Hero da landing** mostra uma pilha de fichas de pedido ilustrando o próprio
  mecanismo de despacho, em vez do "big number + CTA" genérico.

## Carrossel de fotos de pets

Nas telas iniciais (landing e login/cadastro), um carrossel horizontal com 20 fotos
(cães, gatos, coelho, hamster, tartaruga, periquito), cada uma como uma "ficha" com
cantos levemente rotacionados, consistente com o resto do visual.

- Fotos são **CC0** (domínio público, sem exigência de atribuição), de bancos
  Openverse/Wikimedia/StockSnap — escolhidas e recortadas manualmente (proporção 4:5,
  foco no rosto do animal), otimizadas localmente e salvas em `img/pets/`.
- São apenas ilustrativas — **não são pets reais** cadastrados no PetHub (isso está
  documentado também em comentário no código, em `js/app.js`).
- Navegação por arraste (scroll-snap nativo) + setas + indicadores de posição — sem
  auto-play contínuo, pra não ter movimento não solicitado pelo usuário rodando o
  tempo todo.

## Fotos de pets reais (perfil do tutor)

Diferente do carrossel (decorativo), em "Meu perfil" cada pet cadastrado pelo tutor
tem uma foto própria, de verdade, enviada por upload (ver
[[02-arquitetura-e-dados|arquitetura]] para o detalhe técnico do bucket de Storage),
exibida como avatar circular ao lado do nome.
