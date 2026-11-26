-- PetHub MVP - schema Supabase (Postgres)
-- Rode este script inteiro no SQL Editor do seu projeto Supabase.
-- Depois, copie a URL e a anon key do projeto para pethub/config.js.

create extension if not exists pgcrypto;

-- ====================================================================
-- PERFIS (um por usuário autenticado, tutor ou parceiro)
-- ====================================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  tipo text not null check (tipo in ('tutor', 'parceiro')),
  nome text not null,
  telefone text,
  cidade text default 'Joinville',
  bairro text,
  created_at timestamptz not null default now()
);

-- ====================================================================
-- PETS (perfil do pet, centralizado e compartilhado entre prestadores)
-- ====================================================================
create table if not exists pets (
  id uuid primary key default gen_random_uuid(),
  tutor_id uuid not null references profiles(id) on delete cascade,
  nome text not null,
  especie text not null check (especie in ('cachorro', 'gato', 'outro')),
  raca text,
  data_nascimento date,
  vacinas text,
  alergias text,
  rotina text,
  foto_url text,
  created_at timestamptz not null default now()
);

-- ====================================================================
-- PARCEIROS (pet shops, veterinários, hospedagem, cuidadores)
-- ====================================================================
create table if not exists parceiros (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references profiles(id) on delete cascade,
  tipo_negocio text not null check (tipo_negocio in ('pet_shop', 'veterinario', 'hospedagem', 'cuidador')),
  nome_fantasia text not null,
  documento text not null, -- CNPJ ou CRMV
  verificado boolean not null default false,
  cidade text default 'Joinville',
  bairro text,
  descricao text,
  nota_media numeric(2,1) default 0,
  total_avaliacoes int not null default 0,
  created_at timestamptz not null default now()
);

-- ====================================================================
-- ITENS (produtos ou serviços oferecidos por um parceiro)
-- ====================================================================
create table if not exists itens (
  id uuid primary key default gen_random_uuid(),
  parceiro_id uuid not null references parceiros(id) on delete cascade,
  tipo text not null check (tipo in ('produto', 'servico')),
  nome text not null,
  descricao text,
  preco numeric(10,2) not null,
  prazo_horas int not null default 24, -- prazo de entrega (produto) ou duração (serviço)
  disponivel boolean not null default true,
  created_at timestamptz not null default now()
);

-- ====================================================================
-- PEDIDOS (compra de produto ou agendamento de serviço)
-- Modelo "broadcast": ao ser criado, o pedido não tem parceiro/item/valor
-- definidos ainda (ficam null). Ele é oferecido a vários parceiros ao
-- mesmo tempo (ver pedido_candidatos) e só é "fechado" com o primeiro
-- parceiro que aceitar, igual um despacho de corrida/entrega.
-- ====================================================================
create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  tutor_id uuid not null references profiles(id) on delete cascade,
  parceiro_id uuid references parceiros(id) on delete cascade, -- preenchido só quando alguém aceita
  pet_id uuid references pets(id) on delete set null,
  item_id uuid references itens(id) on delete restrict, -- preenchido só quando alguém aceita
  tipo text not null check (tipo in ('produto', 'servico')),
  nome_item text not null, -- nome do produto/serviço pedido, usado para achar parceiros elegíveis
  preco_referencia numeric(10,2), -- preço que o tutor viu ao pedir, só para exibição
  quantidade int not null default 1,
  horario_agendado timestamptz,
  endereco_entrega text,
  valor_total numeric(10,2), -- preenchido com o preço do parceiro que aceitou
  status text not null default 'pendente'
    check (status in ('pendente', 'aceito', 'em_andamento', 'concluido', 'avaliado', 'cancelado')),
  created_at timestamptz not null default now()
);

-- ====================================================================
-- CANDIDATOS (quais parceiros foram notificados de um pedido em aberto)
-- ====================================================================
create table if not exists pedido_candidatos (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id) on delete cascade,
  parceiro_id uuid not null references parceiros(id) on delete cascade,
  item_id uuid not null references itens(id) on delete cascade,
  status text not null default 'pendente' check (status in ('pendente', 'recusado')),
  created_at timestamptz not null default now(),
  unique (pedido_id, parceiro_id)
);

-- ====================================================================
-- AVALIAÇÕES (nota do tutor sobre um pedido concluído)
-- ====================================================================
create table if not exists avaliacoes (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null unique references pedidos(id) on delete cascade,
  nota int not null check (nota between 1 and 5),
  comentario text,
  created_at timestamptz not null default now()
);

-- ====================================================================
-- Funções auxiliares (security definer) usadas pelas policies abaixo.
-- Ficam em funções porque uma policy de "pedidos" que reconsultasse
-- "pedido_candidatos" (que por sua vez reconsulta "pedidos") causaria
-- recursão no RLS; a função, rodando como dono da tabela, não dispara
-- essas policies de novo.
-- ====================================================================
create or replace function tutor_e_dono_do_pedido(p_pedido_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from pedidos where id = p_pedido_id and tutor_id = auth.uid());
$$;

create or replace function eh_candidato_do_pedido(p_pedido_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from pedido_candidatos pc
    join parceiros pa on pa.id = pc.parceiro_id
    where pc.pedido_id = p_pedido_id and pa.profile_id = auth.uid()
  );
$$;

create or replace function eh_candidato_pendente_do_pedido(p_pedido_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from pedido_candidatos pc
    join parceiros pa on pa.id = pc.parceiro_id
    where pc.pedido_id = p_pedido_id and pa.profile_id = auth.uid() and pc.status = 'pendente'
  );
$$;

-- ====================================================================
-- RLS (Row Level Security)
-- ====================================================================
alter table profiles enable row level security;
alter table pets enable row level security;
alter table parceiros enable row level security;
alter table itens enable row level security;
alter table pedidos enable row level security;
alter table pedido_candidatos enable row level security;
alter table avaliacoes enable row level security;

-- profiles: qualquer pessoa autenticada lê perfis (precisa mostrar nome do parceiro no catálogo);
-- só o dono edita o próprio perfil.
create policy "profiles_select_all" on profiles for select using (true);
create policy "profiles_insert_self" on profiles for insert with check (auth.uid() = id);
create policy "profiles_update_self" on profiles for update using (auth.uid() = id);

-- pets: só o tutor dono vê e edita os pets dele.
create policy "pets_select_own" on pets for select using (auth.uid() = tutor_id);
create policy "pets_insert_own" on pets for insert with check (auth.uid() = tutor_id);
create policy "pets_update_own" on pets for update using (auth.uid() = tutor_id);
create policy "pets_delete_own" on pets for delete using (auth.uid() = tutor_id);

-- parceiros: catálogo é público para leitura; só o próprio parceiro edita seu cadastro.
create policy "parceiros_select_all" on parceiros for select using (true);
create policy "parceiros_insert_self" on parceiros for insert with check (auth.uid() = profile_id);
create policy "parceiros_update_self" on parceiros for update using (auth.uid() = profile_id);

-- itens: catálogo público para leitura; só o parceiro dono cria/edita os próprios itens.
create policy "itens_select_all" on itens for select using (true);
create policy "itens_insert_own" on itens for insert with check (
  parceiro_id in (select id from parceiros where profile_id = auth.uid())
);
create policy "itens_update_own" on itens for update using (
  parceiro_id in (select id from parceiros where profile_id = auth.uid())
);
create policy "itens_delete_own" on itens for delete using (
  parceiro_id in (select id from parceiros where profile_id = auth.uid())
);

-- pedidos: o tutor dono sempre vê; o parceiro que já fechou o pedido vê;
-- e qualquer parceiro que ainda está "disputando" o pedido (candidato) também vê.
create policy "pedidos_select_envolvidos" on pedidos for select using (
  auth.uid() = tutor_id
  or parceiro_id in (select id from parceiros where profile_id = auth.uid())
  or eh_candidato_do_pedido(id)
);

create policy "pedidos_insert_tutor" on pedidos for insert with check (auth.uid() = tutor_id);

-- update: o tutor (dono) e o parceiro que já fechou o pedido seguem o fluxo normal;
-- além disso, QUALQUER candidato pendente pode "aceitar" (preencher parceiro_id/item_id/
-- valor_total e mudar o status), desde que o pedido ainda esteja 'pendente': isso é o
-- que garante que só o primeiro a aceitar vence (os demais caem porque o status já mudou).
create policy "pedidos_update_envolvidos" on pedidos for update using (
  auth.uid() = tutor_id
  or parceiro_id in (select id from parceiros where profile_id = auth.uid())
  or (status = 'pendente' and eh_candidato_pendente_do_pedido(id))
) with check (
  auth.uid() = tutor_id
  or parceiro_id in (select id from parceiros where profile_id = auth.uid())
);

-- pedido_candidatos: cada parceiro só vê/atualiza as próprias candidaturas;
-- o tutor (dono do pedido) pode criar uma candidatura por parceiro elegível.
create policy "candidatos_select_own_parceiro" on pedido_candidatos for select using (
  parceiro_id in (select id from parceiros where profile_id = auth.uid())
);
create policy "candidatos_insert_tutor_dono_pedido" on pedido_candidatos for insert with check (
  tutor_e_dono_do_pedido(pedido_id)
);
create policy "candidatos_update_own" on pedido_candidatos for update using (
  parceiro_id in (select id from parceiros where profile_id = auth.uid())
);

-- avaliações: catálogo público para leitura (compor nota média); só o tutor do pedido avalia.
create policy "avaliacoes_select_all" on avaliacoes for select using (true);
create policy "avaliacoes_insert_tutor_dono" on avaliacoes for insert with check (
  pedido_id in (select id from pedidos where tutor_id = auth.uid())
);

-- ====================================================================
-- Trigger: ao inserir avaliação, recalcula nota média do parceiro
-- e marca o pedido como 'avaliado'.
-- ====================================================================
create or replace function atualizar_nota_parceiro()
returns trigger as $$
declare
  v_parceiro_id uuid;
begin
  select parceiro_id into v_parceiro_id from pedidos where id = new.pedido_id;

  update parceiros p
  set
    total_avaliacoes = p.total_avaliacoes + 1,
    nota_media = round(
      (
        (p.nota_media * p.total_avaliacoes) + new.nota
      ) / (p.total_avaliacoes + 1)::numeric,
      1
    )
  where p.id = v_parceiro_id;

  update pedidos set status = 'avaliado' where id = new.pedido_id;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_avaliacao_insert on avaliacoes;
create trigger trg_avaliacao_insert
  after insert on avaliacoes
  for each row execute function atualizar_nota_parceiro();

-- ====================================================================
-- STORAGE: fotos de pets
-- Bucket público (leitura livre, como a anon key já é pública); upload,
-- troca e exclusão só pelo próprio tutor, no seu próprio "fundo" de pasta
-- (caminho salvo como "<tutor_id>/<pet_id>.jpg").
-- ====================================================================
insert into storage.buckets (id, name, public)
values ('pet-fotos', 'pet-fotos', true)
on conflict (id) do nothing;

drop policy if exists "pet_fotos_insert_own" on storage.objects;
create policy "pet_fotos_insert_own" on storage.objects for insert to authenticated
with check (bucket_id = 'pet-fotos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "pet_fotos_update_own" on storage.objects;
create policy "pet_fotos_update_own" on storage.objects for update to authenticated
using (bucket_id = 'pet-fotos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "pet_fotos_delete_own" on storage.objects;
create policy "pet_fotos_delete_own" on storage.objects for delete to authenticated
using (bucket_id = 'pet-fotos' and (storage.foldername(name))[1] = auth.uid()::text);
