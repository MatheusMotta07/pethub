# PetHub — índice de contexto do projeto

Registro completo do contexto por trás do protótipo PetHub, pra não depender só da
memória de uma conversa com IA. Pensado pra quem (equipe, ou você mesmo daqui a uns
meses) precisar entender *por que* o projeto é como é, não só *o que* ele faz.

## Notas

- [[01-visao-geral-e-negocio|Visão geral e contexto de negócio]] — o que é o PetHub,
  pra que trabalho acadêmico serve, decisões de escopo do MVP.
- [[02-arquitetura-e-dados|Arquitetura técnica e modelo de dados]] — stack, schema do
  Supabase, RLS, modelo de despacho broadcast.
- [[03-design-e-interface|Design e interface]] — identidade visual, tipografia,
  carrossel de fotos.
- [[04-historico-de-decisoes|Histórico de decisões]] — linha do tempo de como o
  projeto evoluiu, incluindo os pivots.
- [[05-deploy-e-infraestrutura|Deploy e infraestrutura]] — onde o código e o banco
  vivem, como publicar uma mudança.
- [[06-requisitos|Requisitos funcionais e não funcionais]] — RF e RNF levantados a
  partir do que está implementado.
- [[07-casos-de-teste|Casos de teste]] — casos de teste de usuário e de software,
  com rastreabilidade para os requisitos.

## Em uma frase

Marketplace de produtos e serviços pet em Joinville/SC: tutores pedem ração ou
agendam banho/veterinário/hospedagem, e o pedido é oferecido **ao mesmo tempo** a
todos os parceiros elegíveis da região — quem aceitar primeiro, atende (modelo
"broadcast", como um despacho de corrida).

## Links úteis

- Código: [github.com/MatheusMotta07/pethub](https://github.com/MatheusMotta07/pethub) (privado)
- App publicado: [pethub-univille.vercel.app](https://pethub-univille.vercel.app)
- Banco (Supabase): projeto `PetHub`, ref `emzqbsfllzmevvxfmwez`
