-- Dados de exemplo OPCIONAIS para testar o catálogo sem precisar criar parceiros manualmente.
-- Rode DEPOIS do supabase-setup.sql. Cria parceiros "fantasma" (sem usuário real em auth.users),
-- então eles aparecem no catálogo mas ninguém consegue logar neles ou gerenciá-los pelo painel.
-- Use só para visualizar o catálogo populado; para testar o fluxo completo de parceiro
-- (login, cadastrar itens, aceitar pedido), cadastre um parceiro de verdade pela tela de login.
--
-- Como profiles.id normalmente exige um usuário em auth.users, este script afrouxa essa
-- checagem (NOT VALID) só para permitir os perfis fantasma abaixo; novos cadastros via app
-- continuam validados normalmente.
alter table profiles drop constraint if exists profiles_id_fkey;
alter table profiles
  add constraint profiles_id_fkey foreign key (id) references auth.users(id) on delete cascade not valid;

do $$
declare
  v_profile_id uuid;
  v_parceiro_id uuid;
begin
  -- Pet shop exemplo
  v_profile_id := gen_random_uuid();
  insert into profiles (id, tipo, nome, bairro, cidade) values
    (v_profile_id, 'parceiro', 'Equipe Amigo Fiel', 'América', 'Joinville');
  insert into parceiros (profile_id, tipo_negocio, nome_fantasia, documento, verificado, bairro, descricao, nota_media, total_avaliacoes)
    values (v_profile_id, 'pet_shop', 'Pet Shop Amigo Fiel', '11.222.333/0001-44', true, 'América', 'Ração, petiscos e acessórios com entrega rápida.', 4.6, 12)
    returning id into v_parceiro_id;
  insert into itens (parceiro_id, tipo, nome, descricao, preco, prazo_horas) values
    (v_parceiro_id, 'produto', 'Ração Premium Adulto 10,1kg', 'Ração super premium para cães adultos de porte médio.', 189.90, 4),
    (v_parceiro_id, 'produto', 'Areia Higiênica para Gatos 4kg', 'Areia aglomerante com controle de odor.', 39.90, 4);

  -- Veterinário exemplo
  v_profile_id := gen_random_uuid();
  insert into profiles (id, tipo, nome, bairro, cidade) values
    (v_profile_id, 'parceiro', 'Dra. Camila Souza', 'Atiradores', 'Joinville');
  insert into parceiros (profile_id, tipo_negocio, nome_fantasia, documento, verificado, bairro, descricao, nota_media, total_avaliacoes)
    values (v_profile_id, 'veterinario', 'Clínica Vet Atiradores', 'CRMV-SC 12345', true, 'Atiradores', 'Clínica geral, vacinas e check-up preventivo.', 4.9, 20)
    returning id into v_parceiro_id;
  insert into itens (parceiro_id, tipo, nome, descricao, preco, prazo_horas) values
    (v_parceiro_id, 'servico', 'Consulta veterinária geral', 'Avaliação clínica completa com veterinário.', 150.00, 1),
    (v_parceiro_id, 'servico', 'Pacote de vacinação V10', 'Aplicação da vacina V10 com carteira atualizada.', 95.00, 1);

  -- Cuidador exemplo
  v_profile_id := gen_random_uuid();
  insert into profiles (id, tipo, nome, bairro, cidade) values
    (v_profile_id, 'parceiro', 'Rafael Lima', 'América', 'Joinville');
  insert into parceiros (profile_id, tipo_negocio, nome_fantasia, documento, verificado, bairro, descricao, nota_media, total_avaliacoes)
    values (v_profile_id, 'cuidador', 'Rafa Pet Sitter', '222.333.444-55', false, 'América', 'Passeios e hospedagem na casa do cuidador.', 4.3, 7)
    returning id into v_parceiro_id;
  insert into itens (parceiro_id, tipo, nome, descricao, preco, prazo_horas) values
    (v_parceiro_id, 'servico', 'Passeio de 30 minutos', 'Passeio individual no bairro com acompanhamento.', 35.00, 1),
    (v_parceiro_id, 'servico', 'Hospedagem diária', 'Hospedagem na casa do cuidador, com fotos diárias.', 80.00, 24);
end $$;
