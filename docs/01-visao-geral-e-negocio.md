# Visão geral e contexto de negócio

← [[00-indice|Índice]]

## O que é

**PetHub** é um protótipo navegável (MVP) de marketplace pet para Joinville/SC:
tutores centralizam o perfil do pet (vacinas, alergias, rotina) e pedem produtos ou
agendam serviços (veterinário, banho e tosa, hospedagem, cuidador) com parceiros da
região; parceiros (pet shops, clínicas, hotéis, cuidadores) recebem os pedidos e
gerenciam seu próprio catálogo.

## Origem acadêmica

Trabalho da disciplina **Negócios Digitais** (Univille, 2026). O ponto de partida
foram quatro documentos de planejamento de negócio produzidos pela equipe, mais um
Business Model Canvas:

1. SWOT / diferenciais competitivos
2. Funil de vendas
3. Mercado e produto (dimensionamento TAM/SAM/SOM)
4. Proposta de solução
5. Business Model Canvas (imagem)

> Observação: o conteúdo integral desses documentos (números exatos de SWOT,
> TAM/SAM/SOM, estágios do funil) não está reproduzido aqui — eles existem como
> arquivos separados do trabalho acadêmico. Este registro documenta as *decisões de
> produto* que vieram deles, não os documentos em si.

**Equipe:** Carlos Brazão, Jorge Dutra, Juliana Seemann, Lorenzo Poncio, Matheus Motta.

## Decisão de escopo do MVP

A partir da análise dos documentos acima, três decisões de escopo foram tomadas
antes de começar a implementar:

1. **Entregável:** protótipo de front-end navegável (não um documento ou apresentação
   estática) — pra validar o fluxo de uso de verdade, clicando.
2. **Escopo:** os dois lados do marketplace, simplificados — tutor (consumidor) e
   parceiro (estabelecimento) — não só o lado do consumidor.
3. **Stack:** Vanilla JS + Supabase, sem framework de front-end, seguindo o mesmo
   padrão de um projeto irmão na mesma pasta de trabalho (`mapa-clientes`).

## O que é mock/simplificado neste protótipo

Decisão consciente de escopo pra um MVP de validação de fluxo, não de produto final:

- **Pagamento:** não há gateway real; o pedido é "confirmado" direto, sem cobrança.
- **Roteamento por região:** simplificado para "mesmo bairro", sem geolocalização real.
- **Verificação de CNPJ/CRMV:** o campo é salvo, mas a validação não é automática —
  hoje só é marcada manualmente no banco (seria uma tela de admin numa v2).
- **Lembretes de recompra/vacina:** citados no Canvas e no Business Model, mas ainda
  não implementados (próximo passo natural do roadmap).
- **Destaque pago / plano premium do parceiro:** fonte de receita do Canvas, fora do
  escopo deste MVP de validação de fluxo.

## O pivot mais importante: de "repasse sequencial" para "broadcast"

A primeira versão implementada e testada ponta a ponta usava um modelo **sequencial**:
o pedido ia para um parceiro específico; se ele recusasse, o sistema repassava
automaticamente para o próximo parceiro elegível.

Depois dessa versão já estar funcionando, um print de uma conversa de um colega de
equipe descreveu como o fluxo real deveria funcionar: duas "plataformas" dentro do
app (agendamento de serviço, e uma aba de marketplace de itens estilo Zé Delivery),
e, na parte de marketplace, **"quando o cliente final pedir, vai tocar o pedido e
quem aceitar faz a entrega, separa os itens e envia"** — ou seja, o pedido deveria
ir para **todos os parceiros elegíveis ao mesmo tempo**, não um de cada vez.

A pedido do usuário, o modelo foi totalmente reescrito para broadcast (ver
[[02-arquitetura-e-dados|arquitetura técnica]] para o detalhe de implementação) e
revalidado end-to-end antes de seguir em frente. Essa mudança está registrada com
mais detalhe cronológico em [[04-historico-de-decisoes|histórico de decisões]].
