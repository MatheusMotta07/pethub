// Cliente Supabase compartilhado por todas as páginas.
// Depende de window.APP_CONFIG (config.js) e do SDK supabase-js (CDN).
// Se o SDK não carregar (sem internet, CDN bloqueado, etc.), window.sb fica null
// e as páginas mostram uma mensagem amigável em vez de travar em "Carregando...".
if (window.supabase && typeof window.supabase.createClient === "function") {
  window.sb = window.supabase.createClient(
    window.APP_CONFIG.SUPABASE_URL,
    window.APP_CONFIG.SUPABASE_ANON_KEY
  );
} else {
  console.error("SDK do Supabase não carregou. Verifique a conexão com a internet ou o CDN.");
  window.sb = null;
}
