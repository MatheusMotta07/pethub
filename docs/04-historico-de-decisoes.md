# Histórico de decisões

← [[00-indice|Índice]]

Linha do tempo de como o projeto evoluiu, em ordem. Pensado pra responder "por que
isso é assim?" sem precisar reconstruir a conversa inteira.

1. **Ponto de partida.** Quatro documentos do trabalho de Negócios Digitais (SWOT,
   funil de vendas, mercado/produto, proposta de solução) + um Business Model Canvas
   foram analisados para decidir o que construir. Ver
   [[01-visao-geral-e-negocio|visão geral]].

2. **Decisão de escopo do MVP.** Protótipo navegável (não documento), cobrindo os
   dois lados do marketplace (tutor + parceiro), em Vanilla JS + Supabase.

3. **Setup do Supabase guiado.** O usuário foi guiado passo a passo para criar o
   projeto Supabase e configurar `config.js`. Em um ponto, o agente tentou desligar
   "Confirm email" diretamente pelo navegador (pra evitar rate limit de e-mail de
   confirmação durante os testes) e foi **bloqueado pelo classificador de modo
   automático** por ser uma mudança de segurança sensível — o agente parou, explicou
   a situação, e o próprio usuário fez a mudança manualmente.

4. **Primeira versão: modelo sequencial de repasse.** Implementado e testado
   end-to-end: pedido vai a um parceiro específico; se ele recusa, o sistema
   repassa automaticamente para o próximo parceiro elegível (`pedido_origem_id`
   encadeando os repasses).

5. **Pivot para o modelo broadcast.** A partir de um print de chat de um colega de
   equipe descrevendo o fluxo real pretendido (duas "plataformas": agendamento de
   serviço + marketplace de itens estilo Zé Delivery, com despacho simultâneo a
   todos os parceiros elegíveis), o usuário escolheu migrar o modelo sequencial para
   broadcast. Esquema, RLS e as três páginas envolvidas (`parceiro.html`,
   `painel.html`, `meus-pedidos.html`) foram reescritos e revalidados com múltiplas
   contas reais (duas contas de pet shop, duas de tutor) antes de seguir em frente.

6. **Redesign visual completo.** O visual inicial (creme + laranja + cards
   genéricos + emoji) foi substituído pela identidade "ficha de despacho" descrita
   em [[03-design-e-interface|design e interface]].

7. **Deploy inicial.** `git init`, repositório privado criado no GitHub
   (`MatheusMotta07/pethub`), deploy via Vercel CLI (login por device code), domínio
   customizado configurado (`pethub-univille.vercel.app`). Ver
   [[05-deploy-e-infraestrutura]].

8. **Carrossel de fotos de pets.** Adicionado com 6 fotos CC0 inicialmente, depois
   expandido para 20 a pedido do usuário.

9. **Edição de pet + upload de foto.** Em "Meu perfil", adicionado botão de editar
   nome do pet e upload de foto real (bucket `pet-fotos`). Encontrado e contornado
   um bug de RLS com `upsert: true` (ver [[02-arquitetura-e-dados]]).

10. **Remoção de travessões.** A pedido do usuário, todo travessão (—) foi removido
    de textos visíveis, títulos e comentários de código, reescrito naturalmente com
    vírgula, dois-pontos, ponto-e-vírgula ou ponto final.

11. **Categorias, itens e complementos no painel do parceiro.** O cadastro de itens,
    que antes só permitia criar/pausar/excluir, ganhou: categorias (agrupamento),
    edição completa de itens (nome, preço, categoria, descrição, prazo — antes não
    dava pra editar nada depois de criado), e complementos por item (opcionais com
    preço próprio, ex: "embalagem para presente").

12. **Este registro no Obsidian**, consolidando todo o contexto acima em notas
    linkadas, pra não depender só do histórico de uma conversa.

13. **Edição de pet estendida para todos os campos.** O que o item 9 deixou de fora
    (editar só nome/foto) foi completado: o formulário inline de edição em "Meu
    perfil" passou a cobrir espécie, raça, data de nascimento, vacinas, alergias e
    rotina, espelhando o formulário de "Adicionar pet".

14. **Atualização deste registro no Obsidian**, mantendo o histórico em dia conforme
    o projeto evolui (este próprio item).

15. **Segundo pivot: catálogo compartilhado, pedido por item.** O usuário notou que
    o fluxo de pedido ainda exigia escolher um parceiro específico antes de pedir
    (entrar na página dele, escolher um item do cardápio *dele*), o que contradizia
    o próprio modelo broadcast ("Zé Delivery": pedir o quê, não de quem). Causa raiz:
    o casamento de parceiros elegíveis comparava texto livre de nome (`ilike`) e
    usava o bairro do parceiro visitado, então só fazia sentido partindo da página
    dele. A pedido do usuário, nova tabela `catalogo_itens` (catálogo compartilhado
    da plataforma, mantido pela equipe) virou a referência: `itens` passou a
    apontar pra ela (`catalogo_item_id`), o broadcast passou a casar por esse id e
    pelo bairro do próprio tutor (não mais do parceiro visitado), e `catalogo.html`
    ganhou a aba "Por item" (pede direto, sem escolher parceiro) como padrão,
    mantendo "Por parceiro" pra quem quer ver o cardápio completo de um
    estabelecimento. Lógica de criação do pedido consolidada numa função
    compartilhada (`criarPedidoBroadcast` em `js/app.js`), usada por `catalogo.html`
    e `parceiro.html`. Itens cadastrados antes dessa mudança ficam sem
    `catalogo_item_id` até o parceiro vinculá-los manualmente no painel (editar
    item → escolher "o que você está oferecendo"); o card do item no painel destaca
    isso com um aviso.
