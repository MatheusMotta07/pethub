// Helpers compartilhados: toast, formatação, navbar e guarda de sessão.
// Requer que supabase-client.js já tenha rodado (window.sb disponível).

function showToast(message, type = "") {
  let el = document.getElementById("app-toast");
  if (!el) {
    el = document.createElement("div");
    el.id = "app-toast";
    el.className = "toast";
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.className = "toast show " + type;
  clearTimeout(el._timer);
  el._timer = setTimeout(() => el.classList.remove("show"), 3200);
}

function formatMoney(value) {
  return (Number(value) || 0).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

function formatDateTime(value) {
  if (!value) return "-";
  return new Date(value).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
}

function formatDate(value) {
  if (!value) return "-";
  return new Date(value).toLocaleDateString("pt-BR");
}

const STATUS_LABELS = {
  pendente: "Procurando parceiro disponível",
  aceito: "Aceito",
  em_andamento: "Em andamento",
  concluido: "Concluído",
  avaliado: "Avaliado",
  cancelado: "Cancelado"
};

const TIPO_NEGOCIO_LABELS = {
  pet_shop: "Pet shop",
  veterinario: "Veterinário",
  hospedagem: "Hospedagem",
  cuidador: "Cuidador"
};

// Ícones de linha (substituem emoji), mesmo traço em todo o site.
const ICONS = {
  paw: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><ellipse cx="12" cy="16" rx="5.2" ry="4.4"/><ellipse cx="5.3" cy="9.3" rx="2.1" ry="2.6" transform="rotate(-18 5.3 9.3)"/><ellipse cx="9.6" cy="5.4" rx="2.1" ry="2.7" transform="rotate(-7 9.6 5.4)"/><ellipse cx="14.4" cy="5.4" rx="2.1" ry="2.7" transform="rotate(7 14.4 5.4)"/><ellipse cx="18.7" cy="9.3" rx="2.1" ry="2.6" transform="rotate(18 18.7 9.3)"/></svg>',
  check: '<svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 8.5 6.5 12 13 4"/></svg>',
  pin: '<svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M8 14.5S13 9.8 13 6.3A5 5 0 0 0 3 6.3C3 9.8 8 14.5 8 14.5Z"/><circle cx="8" cy="6.3" r="1.7"/></svg>',
  clock: '<svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6.2"/><path d="M8 4.6V8l2.6 1.6"/></svg>',
  tag: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M11 3.5h5.5a2 2 0 0 1 2 2V11a2 2 0 0 1-.6 1.4l-7 7a2 2 0 0 1-2.8 0l-4.5-4.5a2 2 0 0 1 0-2.8l7-7A2 2 0 0 1 11 3.5Z"/><circle cx="14.5" cy="8" r="1.4"/></svg>',
  shield: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3.5 19 6v6c0 4.4-3 7.3-7 8.5-4-1.2-7-4.1-7-8.5V6Z"/><polyline points="8.7 12 11 14.3 15.4 9.6"/></svg>',
  broadcast: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="2.3"/><path d="M7.5 8.5a6.2 6.2 0 0 0 0 7M16.5 8.5a6.2 6.2 0 0 1 0 7M4.3 5.3a10.6 10.6 0 0 0 0 13.4M19.7 5.3a10.6 10.6 0 0 1 0 13.4"/></svg>',
  chevronLeft: '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="10 3 5 8 10 13"/></svg>',
  chevronRight: '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 3 11 8 6 13"/></svg>'
};

// Fotos ilustrativas de pets (CC0) para o carrossel das telas iniciais.
// Não são pets reais cadastrados no PetHub, só para ambientar a tela.
const PET_PHOTOS = [
  { src: "img/pets/cachorro-buldogue.jpg", alt: "Filhote de buldogue farejando", caption: "Buldogue, 6 semanas" },
  { src: "img/pets/gato-laranja.jpg", alt: "Gato laranja e branco em cima de uma mesa", caption: "Vira-lata laranja" },
  { src: "img/pets/coelho.jpg", alt: "Coelho de orelha caída na grama", caption: "Coelho ariete" },
  { src: "img/pets/cachorro-bulldog-frances.jpg", alt: "Filhote de bulldog francês", caption: "Bulldog francês" },
  { src: "img/pets/gato-filhote.jpg", alt: "Gatinho preto e branco cheirando uma flor", caption: "Gatinho, 2 meses" },
  { src: "img/pets/hamster.jpg", alt: "Hamster sírio comendo pepino", caption: "Hamster sírio" },
  { src: "img/pets/cachorro-golden-retriever.jpg", alt: "Filhote de golden retriever deitado", caption: "Golden retriever" },
  { src: "img/pets/gato-tigrado.jpg", alt: "Gato tigrado de perfil usando coleira vermelha", caption: "Gato tigrado" },
  { src: "img/pets/tartaruga.jpg", alt: "Tartaruga de estimação sobre um tronco", caption: "Tartaruga" },
  { src: "img/pets/cachorro-corgi.jpg", alt: "Corgi sentado na grama com a língua de fora", caption: "Corgi galês" },
  { src: "img/pets/gato-laranja-deitado.jpg", alt: "Gato laranja deitado no chão", caption: "Gato laranja" },
  { src: "img/pets/cachorro-labrador.jpg", alt: "Filhote de labrador branco olhando para cima", caption: "Labrador" },
  { src: "img/pets/gato-siames.jpg", alt: "Gato siamês de olhos azuis deitado", caption: "Gato siamês" },
  { src: "img/pets/periquito.jpg", alt: "Periquito-australiano verde em um galho", caption: "Periquito-australiano" },
  { src: "img/pets/cachorro-chihuahua.jpg", alt: "Chihuahua no colo da tutora", caption: "Chihuahua" },
  { src: "img/pets/gato-persa.jpg", alt: "Gato persa peludo deitado", caption: "Gato persa" },
  { src: "img/pets/cachorro-beagle.jpg", alt: "Beagle de perfil olhando pela janela", caption: "Beagle" },
  { src: "img/pets/gato-preto-branco.jpg", alt: "Gatinho preto e branco de olhos verdes", caption: "Gatinho de olhos verdes" },
  { src: "img/pets/cachorro-vira-lata.jpg", alt: "Cachorro vira-lata sorridente com olhos de cores diferentes", caption: "Vira-lata, olhos diferentes" },
  { src: "img/pets/gato-preto-branco-2.jpg", alt: "Gato preto e branco de olhos verdes em um parapeito", caption: "Gato preto e branco" }
];

// Monta um carrossel de fotos (arraste ou use as setas) dentro de #containerId.
function renderPetCarousel(containerId) {
  const root = document.getElementById(containerId);
  if (!root) return;

  root.innerHTML = `
    <div class="pet-carousel-track">
      ${PET_PHOTOS.map((p) => `
        <figure class="pet-card">
          <img src="${p.src}" alt="${p.alt}" loading="lazy" width="640" height="800" />
          <figcaption>${p.caption}</figcaption>
        </figure>
      `).join("")}
    </div>
    <div class="pet-carousel-controls">
      <button type="button" class="pet-carousel-btn" data-dir="-1" aria-label="Foto anterior">${ICONS.chevronLeft}</button>
      <div class="pet-carousel-dots"></div>
      <button type="button" class="pet-carousel-btn" data-dir="1" aria-label="Próxima foto">${ICONS.chevronRight}</button>
    </div>
  `;

  const track = root.querySelector(".pet-carousel-track");
  const dotsEl = root.querySelector(".pet-carousel-dots");
  const cards = [...track.children];
  dotsEl.innerHTML = cards.map((_, i) => `<button type="button" data-i="${i}" aria-label="Ir para foto ${i + 1}"></button>`).join("");
  const dots = [...dotsEl.children];

  function step() {
    return cards[0].getBoundingClientRect().width + 16;
  }
  function syncDots() {
    const i = Math.round(track.scrollLeft / step());
    dots.forEach((d, idx) => d.classList.toggle("active", idx === i));
  }
  root.querySelectorAll(".pet-carousel-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      track.scrollBy({ left: Number(btn.dataset.dir) * step() * 2, behavior: "smooth" });
    });
  });
  dots.forEach((d) => {
    d.addEventListener("click", () => {
      track.scrollTo({ left: Number(d.dataset.i) * step(), behavior: "smooth" });
    });
  });
  track.addEventListener("scroll", () => {
    clearTimeout(track._dotTimer);
    track._dotTimer = setTimeout(syncDots, 80);
  });
  syncDots();
}

// Busca a sessão atual e o perfil (profiles) associado. Retorna null se deslogado
// ou se o cliente Supabase não estiver disponível (SDK não carregou).
async function getCurrentProfile() {
  if (!window.sb) return null;
  const { data: { session } } = await window.sb.auth.getSession();
  if (!session) return null;
  const { data, error } = await window.sb
    .from("profiles")
    .select("*")
    .eq("id", session.user.id)
    .maybeSingle();
  if (error) {
    console.error(error);
    return null;
  }
  return data ? { ...data, email: session.user.email } : null;
}

// Protege uma página: redireciona pra auth.html se não houver sessão/perfil.
// Se tipoEsperado for passado ('tutor' | 'parceiro'), redireciona pro catálogo se o tipo não bater.
async function requireAuth(tipoEsperado) {
  if (!window.sb) {
    showToast("Não foi possível conectar ao Supabase (SDK não carregou). Verifique sua internet.", "error");
    return null;
  }
  const profile = await getCurrentProfile();
  if (!profile) {
    window.location.href = "auth.html";
    return null;
  }
  if (tipoEsperado && profile.tipo !== tipoEsperado) {
    window.location.href = profile.tipo === "parceiro" ? "painel.html" : "catalogo.html";
    return null;
  }
  return profile;
}

// Monta a barra de navegação de acordo com o tipo de usuário logado.
async function renderNavbar(activePage) {
  const nav = document.getElementById("navbar");
  if (!nav) return;
  const profile = await getCurrentProfile();

  let links = `<a href="index.html">Início</a>`;
  if (profile && profile.tipo === "tutor") {
    links += `
      <a href="catalogo.html" ${activePage === "catalogo" ? 'class="active"' : ""}>Catálogo</a>
      <a href="meus-pedidos.html" ${activePage === "pedidos" ? 'class="active"' : ""}>Meus pedidos</a>
      <a href="perfil.html" ${activePage === "perfil" ? 'class="active"' : ""}>Meu perfil</a>
    `;
  } else if (profile && profile.tipo === "parceiro") {
    links += `
      <a href="painel.html" ${activePage === "painel" ? 'class="active"' : ""}>Painel</a>
      <a href="perfil.html" ${activePage === "perfil" ? 'class="active"' : ""}>Meu perfil</a>
    `;
  } else {
    links += `<a href="catalogo.html" ${activePage === "catalogo" ? 'class="active"' : ""}>Catálogo</a>`;
  }

  const rightSide = profile
    ? `<span class="user-chip">${profile.nome} · ${profile.tipo === "parceiro" ? "parceiro" : "tutor"}</span>
       <button class="btn-ghost" id="btn-logout">Sair</button>`
    : `<a href="auth.html" class="btn btn-primary">Entrar</a>`;

  nav.innerHTML = `
    <a class="brand" href="index.html">${ICONS.paw}Pet<span>Hub</span></a>
    <div class="nav-links">${links}</div>
    <div class="nav-links">${rightSide}</div>
  `;

  const logoutBtn = document.getElementById("btn-logout");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => {
      await window.sb.auth.signOut();
      window.location.href = "index.html";
    });
  }
}

function starString(nota) {
  const n = Math.round(Number(nota) || 0);
  return "★".repeat(n) + "☆".repeat(5 - n);
}

// Mostra "Sem avaliações ainda" em vez de estrelas quando não há nenhuma avaliação
// (evita ambiguidade visual entre "0 estrelas" e "5 estrelas", já que ★/☆ podem
// renderizar de forma parecida em algumas fontes).
function ratingLabel(nota, total) {
  if (!total) return '<span style="color:var(--ink-soft);">Sem avaliações ainda</span>';
  return `<span class="stars">${starString(nota)}</span> (${total})`;
}
