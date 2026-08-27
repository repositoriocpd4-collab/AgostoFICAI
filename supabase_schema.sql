-- ==============================================================================
-- SCHEMA FICAI 4.0 - SUPABASE (POSTGRESQL)
-- Secretaria Municipal de Educação (SMEDU) / Conselho Tutelar / Promotoria
-- ==============================================================================

-- 1. EXTENSÕES NECESSÁRIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Função utilitária para atualização automática de updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 2. TABELAS DE CADASTROS BÁSICOS E CONFIGURAÇÕES
-- ==============================================================================

-- Tabela: Escolas
CREATE TABLE IF NOT EXISTS public.escolas (
    id TEXT PRIMARY KEY DEFAULT ('esc-' || gen_random_uuid()),
    inep TEXT,
    nome TEXT NOT NULL UNIQUE,
    diretor TEXT,
    endereco TEXT,
    bairro TEXT,
    telefone TEXT,
    ramal TEXT,
    email TEXT,
    modalidade TEXT,
    maps_link TEXT,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_escolas_updated_at ON public.escolas;
CREATE TRIGGER set_escolas_updated_at
BEFORE UPDATE ON public.escolas
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Modalidades de Ensino
CREATE TABLE IF NOT EXISTS public.modalidades (
    id TEXT PRIMARY KEY DEFAULT ('mod-' || gen_random_uuid()),
    nome TEXT NOT NULL UNIQUE,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_modalidades_updated_at ON public.modalidades;
CREATE TRIGGER set_modalidades_updated_at
BEFORE UPDATE ON public.modalidades
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Turmas e Turnos
CREATE TABLE IF NOT EXISTS public.turmas (
    id TEXT PRIMARY KEY DEFAULT ('tur-' || gen_random_uuid()),
    ano TEXT NOT NULL,                -- Ex.: '6º Ano', '7º Ano'
    turma TEXT NOT NULL,              -- Ex.: '6º Ano A', '7º Ano B'
    turno TEXT NOT NULL,              -- 'Manhã', 'Tarde', 'Noite', 'Integral'
    modalidade TEXT,                  -- 'Ensino Fundamental', 'Educação Infantil', 'EJA'
    escola TEXT,                      -- Nome da escola vinculada
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_turmas_updated_at ON public.turmas;
CREATE TRIGGER set_turmas_updated_at
BEFORE UPDATE ON public.turmas
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Usuários do Sistema e Perfis RBAC
CREATE TABLE IF NOT EXISTS public.usuarios (
    id TEXT PRIMARY KEY DEFAULT ('usr-' || gen_random_uuid()),
    usuario TEXT NOT NULL,
    email TEXT,
    nivel TEXT NOT NULL,              -- 'Operacional', 'Gestor', 'Administrador', 'Conselho Tutelar'
    cargo TEXT,
    funcao TEXT,
    unidade TEXT,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_usuarios_updated_at ON public.usuarios;
CREATE TRIGGER set_usuarios_updated_at
BEFORE UPDATE ON public.usuarios
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Permissões de Acesso por Módulo
CREATE TABLE IF NOT EXISTS public.permissoes (
    id TEXT PRIMARY KEY DEFAULT ('perm-' || gen_random_uuid()),
    perfil TEXT NOT NULL,             -- 'Administrador', 'Operacional', etc.
    modulo TEXT NOT NULL,             -- 'Dashboard', 'Gerar FICAI', 'Dados da Ficha', etc.
    visualizar BOOLEAN NOT NULL DEFAULT true,
    cadastrar BOOLEAN NOT NULL DEFAULT false,
    editar BOOLEAN NOT NULL DEFAULT false,
    excluir BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_permissoes_updated_at ON public.permissoes;
CREATE TRIGGER set_permissoes_updated_at
BEFORE UPDATE ON public.permissoes
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Pessoas / Equipe (Diretores, Orientadores, Conselheiros)
CREATE TABLE IF NOT EXISTS public.pessoas (
    id TEXT PRIMARY KEY DEFAULT ('pes-' || gen_random_uuid()),
    tipo TEXT NOT NULL,               -- 'Diretor', 'Diretor Adjunto', 'Orientador', 'Coordenador Pedagógico', 'Conselheiro Tutelar'
    nome TEXT NOT NULL,
    matricula TEXT,
    unidade TEXT,
    telefone TEXT,
    email TEXT,
    periodo TEXT DEFAULT '2026',
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_pessoas_updated_at ON public.pessoas;
CREATE TRIGGER set_pessoas_updated_at
BEFORE UPDATE ON public.pessoas
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Catálogo de Procedimentos da Escola
CREATE TABLE IF NOT EXISTS public.procedimentos (
    id TEXT PRIMARY KEY DEFAULT ('proc-' || gen_random_uuid()),
    ordem INT NOT NULL DEFAULT 1,
    nome TEXT NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_procedimentos_updated_at ON public.procedimentos;
CREATE TRIGGER set_procedimentos_updated_at
BEFORE UPDATE ON public.procedimentos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Catálogo de Motivos e Diagnósticos da Evasão
CREATE TABLE IF NOT EXISTS public.motivos (
    id TEXT PRIMARY KEY DEFAULT ('mot-' || gen_random_uuid()),
    grupo TEXT NOT NULL,              -- 'Motivos da ausência', 'Estrutural', 'Social / Familiar', 'Saúde', 'Educacional', 'Segurança Pública e Violência', 'Econômica', 'Outros'
    nome TEXT NOT NULL,
    dashboard BOOLEAN NOT NULL DEFAULT false,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_motivos_updated_at ON public.motivos;
CREATE TRIGGER set_motivos_updated_at
BEFORE UPDATE ON public.motivos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Catálogos Personalizáveis (Situações do Aluno e Vulnerabilidades Extras)
CREATE TABLE IF NOT EXISTS public.catalogo_personalizado (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo TEXT NOT NULL,               -- 'situacao_aluno' ou 'vulnerabilidade'
    nome TEXT NOT NULL,
    descricao TEXT,
    unidade TEXT,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Tabela: Catálogo de Marcadores (Tags)
CREATE TABLE IF NOT EXISTS public.marcadores (
    id TEXT PRIMARY KEY DEFAULT ('tag-' || gen_random_uuid()),
    nome TEXT NOT NULL UNIQUE,
    cor TEXT NOT NULL DEFAULT '#6b7280',
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_marcadores_updated_at ON public.marcadores;
CREATE TRIGGER set_marcadores_updated_at
BEFORE UPDATE ON public.marcadores
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Tabela: Associação de Marcadores por Aluno/FICAI
CREATE TABLE IF NOT EXISTS public.student_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ficai_numero TEXT NOT NULL REFERENCES public.ficais(numero) ON DELETE CASCADE,
    student_key TEXT,
    tag_nome TEXT NOT NULL,
    tag_cor TEXT NOT NULL DEFAULT '#6b7280',
    texto TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_student_tags_ficai ON public.student_tags(ficai_numero);

-- ==============================================================================
-- 3. TABELA DE ALUNOS (ESTUDANTES)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,         -- Chave normalizada para busca local/remota (ex: 'ana-clara-nascimento')
    nome TEXT NOT NULL,
    social TEXT,
    nascimento DATE,
    cpf TEXT,
    rg TEXT,
    filiacao TEXT,
    responsavel TEXT,
    residencia TEXT,
    telefone TEXT,
    referencia TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_students_key ON public.students(key);
CREATE INDEX IF NOT EXISTS idx_students_nome ON public.students(nome);
CREATE INDEX IF NOT EXISTS idx_students_cpf ON public.students(cpf);

DROP TRIGGER IF EXISTS set_students_updated_at ON public.students;
CREATE TRIGGER set_students_updated_at
BEFORE UPDATE ON public.students
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 4. TABELA PRINCIPAL DE FICAIS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ficais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero TEXT UNIQUE NOT NULL,       -- Número oficial FICAI (ex: '00001/2026')
    ano TEXT NOT NULL,                 -- Ano letivo (ex: '2026')
    student_key TEXT,
    aluno_id UUID REFERENCES public.students(id) ON DELETE SET NULL,
    aluno TEXT NOT NULL,
    escola TEXT,
    turma TEXT,
    turno TEXT,
    modalidade TEXT,
    situacao TEXT NOT NULL DEFAULT 'Infrequente', -- 'Infrequente', 'Evadido', 'Sem Acesso', personalizada
    
    -- Datas e identificação do profissional
    falta_inicio DATE,
    falta_fim DATE,
    data_comunicacao DATE,
    profissional TEXT,
    assinatura_prof TEXT,
    
    -- Textos e relatos
    relato_visita TEXT,
    outros_motivos TEXT,
    observacao_inicial TEXT,
    
    -- Diagnósticos, procedimentos e listas em JSON estruturado
    motivos JSONB DEFAULT '[]'::jsonb,
    vulnerabilidades JSONB DEFAULT '[]'::jsonb,
    diagnostico JSONB DEFAULT '{}'::jsonb,
    procedimentos JSONB DEFAULT '[]'::jsonb,
    situacoes_personalizadas JSONB DEFAULT '[]'::jsonb,
    
    -- Conselho Tutelar & Promotoria
    ct_recebimento TEXT,
    ct_diligencias TEXT,
    ct_devolucao TEXT,
    ct_conselheiro TEXT,
    promotoria_acoes JSONB DEFAULT '[]'::jsonb,
    promotor TEXT,
    prom_data DATE,
    
    -- Status do fluxo e encerramento
    status_fluxo TEXT NOT NULL DEFAULT 'aberto', -- 'aberto', 'em_analise', 'conselho_tutelar', 'promotoria', 'encerrado'

    -- Tramitação documental Escola <-> Conselho Tutelar (mesma FICAI, sem cópia)
    section TEXT NOT NULL DEFAULT 'GERADOS',
    status_tramitacao_ct TEXT NOT NULL DEFAULT 'CRIADA', -- CRIADA | ENVIADA_AO_CT | VISUALIZADA_PELO_CT | DEVOLVIDA_PELO_CT
    is_encaminhado_ct BOOLEAN NOT NULL DEFAULT false,
    has_devolutiva_ct BOOLEAN NOT NULL DEFAULT false,
    ct_enviado_em TIMESTAMPTZ,
    ct_enviado_por TEXT,
    ct_visualizado_em TIMESTAMPTZ,
    ct_visualizado_por TEXT,
    ct_devolvido_em TIMESTAMPTZ,
    ct_devolvido_por TEXT,

    data_encerramento TIMESTAMPTZ,
    motivo_encerramento TEXT,
    justificativa_encerramento TEXT,
    
    -- Snapshot completo do formulário (preserva fidelidade absoluta do front-end)
    data JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Migração idempotente do fluxo Escola <-> CT para bancos já existentes
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS section TEXT NOT NULL DEFAULT 'GERADOS';
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS status_tramitacao_ct TEXT NOT NULL DEFAULT 'CRIADA';
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS is_encaminhado_ct BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS has_devolutiva_ct BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_enviado_em TIMESTAMPTZ;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_enviado_por TEXT;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_visualizado_em TIMESTAMPTZ;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_visualizado_por TEXT;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_devolvido_em TIMESTAMPTZ;
ALTER TABLE public.ficais ADD COLUMN IF NOT EXISTS ct_devolvido_por TEXT;

-- Compatibilidade com registros antigos que usavam situacao/status_fluxo para representar o envio ao CT.
UPDATE public.ficais
SET status_tramitacao_ct = 'ENVIADA_AO_CT',
    is_encaminhado_ct = true,
    section = 'GERADOS'
WHERE status_tramitacao_ct = 'CRIADA'
  AND (status_fluxo = 'conselho_tutelar' OR situacao ILIKE '%Conselho Tutelar%');

UPDATE public.ficais
SET status_tramitacao_ct = 'DEVOLVIDA_PELO_CT',
    is_encaminhado_ct = true,
    has_devolutiva_ct = true,
    section = 'RECEBIDOS_CT'
WHERE situacao ILIKE '%Devolutiva CT%';

CREATE INDEX IF NOT EXISTS idx_ficais_numero ON public.ficais(numero);
CREATE INDEX IF NOT EXISTS idx_ficais_ano ON public.ficais(ano);
CREATE INDEX IF NOT EXISTS idx_ficais_aluno ON public.ficais(aluno);
CREATE INDEX IF NOT EXISTS idx_ficais_escola ON public.ficais(escola);
CREATE INDEX IF NOT EXISTS idx_ficais_situacao ON public.ficais(situacao);
CREATE INDEX IF NOT EXISTS idx_ficais_status_fluxo ON public.ficais(status_fluxo);
CREATE INDEX IF NOT EXISTS idx_ficais_status_tramitacao_ct ON public.ficais(status_tramitacao_ct);
CREATE INDEX IF NOT EXISTS idx_ficais_escola_status_ct ON public.ficais(escola, status_tramitacao_ct);
CREATE INDEX IF NOT EXISTS idx_ficais_updated_at ON public.ficais(updated_at DESC);

DROP TRIGGER IF EXISTS set_ficais_updated_at ON public.ficais;
CREATE TRIGGER set_ficais_updated_at
BEFORE UPDATE ON public.ficais
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Primeira visualização do CT: grava uma única vez e preserva o timestamp original.
CREATE OR REPLACE FUNCTION public.ficai_marcar_visualizacao_ct(
    p_ficai_numero TEXT,
    p_visualizado_em TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    p_visualizado_por TEXT DEFAULT 'Conselho Tutelar'
)
RETURNS SETOF public.ficais
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.ficais
    SET status_tramitacao_ct = 'VISUALIZADA_PELO_CT',
        is_encaminhado_ct = true,
        section = 'GERADOS',
        status_fluxo = 'conselho_tutelar',
        ct_visualizado_em = COALESCE(ct_visualizado_em, p_visualizado_em),
        ct_visualizado_por = COALESCE(NULLIF(ct_visualizado_por, ''), p_visualizado_por)
    WHERE numero = p_ficai_numero
      AND ct_visualizado_em IS NULL
      AND status_tramitacao_ct IN ('ENVIADA_AO_CT', 'VISUALIZADA_PELO_CT');

    RETURN QUERY SELECT * FROM public.ficais WHERE numero = p_ficai_numero;
END;
$$;

-- Devolução formal ao CT: muda o estado uma única vez; chamadas repetidas não duplicam a tramitação.
CREATE OR REPLACE FUNCTION public.ficai_devolver_para_escola(
    p_ficai_numero TEXT,
    p_devolvido_em TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    p_devolvido_por TEXT DEFAULT 'Conselho Tutelar'
)
RETURNS SETOF public.ficais
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.ficais
    SET status_tramitacao_ct = 'DEVOLVIDA_PELO_CT',
        is_encaminhado_ct = true,
        has_devolutiva_ct = true,
        section = 'RECEBIDOS_CT',
        status_fluxo = 'em_analise',
        ct_devolvido_em = COALESCE(ct_devolvido_em, p_devolvido_em),
        ct_devolvido_por = COALESCE(NULLIF(ct_devolvido_por, ''), p_devolvido_por)
    WHERE numero = p_ficai_numero
      AND status_tramitacao_ct IN ('ENVIADA_AO_CT', 'VISUALIZADA_PELO_CT');

    RETURN QUERY SELECT * FROM public.ficais WHERE numero = p_ficai_numero;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficai_marcar_visualizacao_ct(TEXT, TIMESTAMPTZ, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ficai_devolver_para_escola(TEXT, TIMESTAMPTZ, TEXT) TO anon, authenticated;

-- ==============================================================================
-- 5. TABELA DE HISTÓRICO E LINHA DO TEMPO PÓS-GERAÇÃO (INFO ENTRIES & DOCUMENTOS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ficai_info_entries (
    id TEXT PRIMARY KEY DEFAULT ('reg-' || gen_random_uuid()),
    ficai_numero TEXT NOT NULL REFERENCES public.ficais(numero) ON DELETE CASCADE,
    date DATE NOT NULL,
    type TEXT NOT NULL,               -- 'Visita Domiciliar', 'Contato Telefônico', 'Devolutiva CT', 'Ofício', 'Relatório', etc.
    entry_kind TEXT NOT NULL DEFAULT 'info', -- 'info' (informação) ou 'document' (documento anexado)
    text TEXT NOT NULL DEFAULT '',
    responsible TEXT NOT NULL,
    attachments JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array de documentos anexados [{ id, name, ext, mime, size, data, url, uploadedAt }]
    is_devolutiva BOOLEAN NOT NULL DEFAULT false,
    action TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Migrações idempotentes para bancos existentes
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS entry_kind TEXT NOT NULL DEFAULT 'info';
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS attachments JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS is_devolutiva BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS action TEXT;
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

CREATE INDEX IF NOT EXISTS idx_info_entries_ficai ON public.ficai_info_entries(ficai_numero);
CREATE INDEX IF NOT EXISTS idx_info_entries_date ON public.ficai_info_entries(date DESC);
CREATE INDEX IF NOT EXISTS idx_info_entries_kind ON public.ficai_info_entries(entry_kind);

DROP TRIGGER IF EXISTS set_ficai_info_entries_updated_at ON public.ficai_info_entries;
CREATE TRIGGER set_ficai_info_entries_updated_at
BEFORE UPDATE ON public.ficai_info_entries
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 5.1 TABELA DEDICADA DE DOCUMENTOS E ANEXOS DA FICAI
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ficai_documentos (
    id TEXT PRIMARY KEY DEFAULT ('doc-' || gen_random_uuid()),
    ficai_numero TEXT NOT NULL REFERENCES public.ficais(numero) ON DELETE CASCADE,
    entry_id TEXT REFERENCES public.ficai_info_entries(id) ON DELETE SET NULL,
    nome_arquivo TEXT NOT NULL,
    tipo_documento TEXT NOT NULL DEFAULT 'Documento', -- 'Ofício', 'Relatório', 'Declaração', 'Comunicação', 'Encaminhamento', 'Resposta', 'Termo', etc.
    extensao TEXT NOT NULL,                           -- 'pdf', 'docx', 'xlsx', 'png', 'jpg', etc.
    mime_type TEXT,
    tamanho_bytes BIGINT,
    arquivo_url TEXT,                                 -- URL pública do Supabase Storage ou base64 data URL
    storage_path TEXT,                                -- Caminho no bucket de storage (ex: '00021-2026/doc-123.pdf')
    responsavel TEXT NOT NULL,
    descricao TEXT,
    data_documento DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_documentos_ficai ON public.ficai_documentos(ficai_numero);
CREATE INDEX IF NOT EXISTS idx_documentos_entry ON public.ficai_documentos(entry_id);
CREATE INDEX IF NOT EXISTS idx_documentos_tipo ON public.ficai_documentos(tipo_documento);
CREATE INDEX IF NOT EXISTS idx_documentos_data ON public.ficai_documentos(data_documento DESC);

DROP TRIGGER IF EXISTS set_ficai_documentos_updated_at ON public.ficai_documentos;
CREATE TRIGGER set_ficai_documentos_updated_at
BEFORE UPDATE ON public.ficai_documentos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 5.2 CONFIGURAÇÃO DO SUPABASE STORAGE (BUCKET: ficai-documentos)
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'ficai-documentos',
    'ficai-documentos',
    true,
    10485760, -- Limite de 10 MB por arquivo
    ARRAY[
        'application/pdf',
        'image/png',
        'image/jpeg',
        'image/jpg',
        'image/gif',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain'
    ]
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Políticas de acesso para o Bucket Storage
DROP POLICY IF EXISTS "Acesso público de leitura no bucket ficai-documentos" ON storage.objects;
CREATE POLICY "Acesso público de leitura no bucket ficai-documentos"
ON storage.objects FOR SELECT
USING (bucket_id = 'ficai-documentos');

DROP POLICY IF EXISTS "Upload público no bucket ficai-documentos" ON storage.objects;
CREATE POLICY "Upload público no bucket ficai-documentos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'ficai-documentos');

DROP POLICY IF EXISTS "Atualização pública no bucket ficai-documentos" ON storage.objects;
CREATE POLICY "Atualização pública no bucket ficai-documentos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'ficai-documentos');

DROP POLICY IF EXISTS "Exclusão pública no bucket ficai-documentos" ON storage.objects;
CREATE POLICY "Exclusão pública no bucket ficai-documentos"
ON storage.objects FOR DELETE
USING (bucket_id = 'ficai-documentos');

-- ==============================================================================
-- 6. HABILITAÇÃO DO ROW LEVEL SECURITY (RLS) E POLÍTICAS DE ACESSO
-- ==============================================================================

ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modalidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.turmas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pessoas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procedimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motivos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalogo_personalizado ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marcadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ficais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ficai_info_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ficai_documentos ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso irrestrito para clientes com a Publishable / Anon Key (ou autenticados)
-- Permite SELECT, INSERT, UPDATE e DELETE no aplicativo FICAI

DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Public access for all on %I" ON public.%I', t, t);
        EXECUTE format('CREATE POLICY "Public access for all on %I" ON public.%I FOR ALL TO public USING (true) WITH CHECK (true)', t, t);
    END LOOP;
END;
$$;

-- ==============================================================================
-- 7. SEED INICIAL DE DADOS PADRÃO (ITAGUAÍ / SMEDU)
-- ==============================================================================

-- Escolas
INSERT INTO public.escolas (id, nome, endereco, telefone, email, ativo) VALUES
('aparecida', 'C. M. Aparecida Azêdo', 'Estrada do Teixeira, nº 2 - Itaguaí/RJ', '(21) 3782-9003', 'aparecida.azedo@itaguai.rj.gov.br', true),
('elmir', 'E.M. Elmir Figueira', 'Itaguaí/RJ - endereço cadastrado da unidade', '(21) 3782-9003', 'elmir.figueira@itaguai.rj.gov.br', true),
('mignone', 'CIEP 496 Maestro Francisco Mignone', 'Itaguaí/RJ - endereço cadastrado da unidade', '(21) 3782-9003', 'ciep496@itaguai.rj.gov.br', true)
ON CONFLICT (id) DO UPDATE SET nome = EXCLUDED.nome, endereco = EXCLUDED.endereco, telefone = EXCLUDED.telefone, email = EXCLUDED.email, ativo = EXCLUDED.ativo;

-- Modalidades
INSERT INTO public.modalidades (id, nome, descricao, ativo) VALUES
('mod-infantil', 'Educação Infantil', 'Pré e etapas da Educação Infantil.', true),
('mod-fundamental', 'Ensino Fundamental', 'Anos Iniciais e Anos Finais.', true),
('mod-eja', 'EJA', 'Educação de Jovens e Adultos / NCEJA.', true)
ON CONFLICT (id) DO UPDATE SET nome = EXCLUDED.nome, descricao = EXCLUDED.descricao, ativo = EXCLUDED.ativo;

-- ==============================================================================
-- POVOAMENTO DA TABELA TURMAS NO SUPABASE
-- Total de turmas a inserir: 428
-- ==============================================================================

INSERT INTO public.turmas (ano, turma, turno, modalidade, escola, ativo) VALUES
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M Teresinha de Jesus Campos de Farias', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Aparecida Azêdo', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Danielle Batista da Silva', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Edson Cruz Amado', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Euclydes José Borges', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Florentino Elias', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Francisco Xavier de Moura Brito (Chico Pitanga)', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Maria Eduviges do Rosario Silva', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Maria Rosa Gomes do Nascimento', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Eliane Lopes Barbosa (Vila Geni)', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª M.ª Cristina Padela Cabral da Silva', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Maria de Lurdes S. Garcia', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.ª Tania Mara Mota de Menezes', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Goethe Coutinho Madruga', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Joaquim Inouê', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Prof.º Renato Barbosa Ladislau', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Rita Ferreira Feijó', true),
('Berçário', 'Berçário A', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Berçário', 'Berçário B', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Berçário', 'Berçário C', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Berçário', 'Berçário D', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível I', 'Nível I A', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível I', 'Nível I B', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível I', 'Nível I C', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível I', 'Nível I D', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível II', 'Nível II A', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível II', 'Nível II B', 'Manhã', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível II', 'Nível II C', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Nível II', 'Nível II D', 'Tarde', 'Educação Infantil', 'C.M. Vereador José Antônio Carrasco', true),
('Pré II', 'Pré II A', 'Manhã', 'Educação Infantil', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('Pré II', 'Pré II B', 'Manhã', 'Educação Infantil', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('Pré II', 'Pré II C', 'Tarde', 'Educação Infantil', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('Pré II', 'Pré II D', 'Tarde', 'Educação Infantil', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('1º Ano', '1º Ano A', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('1º Ano', '1º Ano B', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('1º Ano', '1º Ano C', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('1º Ano', '1º Ano D', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('2º Ano', '2º Ano A', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('2º Ano', '2º Ano B', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('2º Ano', '2º Ano C', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('2º Ano', '2º Ano D', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('3º Ano', '3º Ano A', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('3º Ano', '3º Ano B', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('3º Ano', '3º Ano C', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('3º Ano', '3º Ano D', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('4º Ano', '4º Ano A', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('4º Ano', '4º Ano B', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('4º Ano', '4º Ano C', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('4º Ano', '4º Ano D', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('5º Ano', '5º Ano A', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('5º Ano', '5º Ano B', 'Manhã', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('5º Ano', '5º Ano C', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('5º Ano', '5º Ano D', 'Tarde', 'Ensino Fundamental I', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('6º Ano', '6º Ano A', 'Manhã', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('6º Ano', '6º Ano B', 'Manhã', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('6º Ano', '6º Ano C', 'Tarde', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('6º Ano', '6º Ano D', 'Tarde', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('7º Ano', '7º Ano A', 'Manhã', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('7º Ano', '7º Ano B', 'Manhã', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('7º Ano', '7º Ano C', 'Tarde', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('7º Ano', '7º Ano D', 'Tarde', 'Ensino Fundamental II', 'CEMAEE  Centro Municipal de Atendimento Educacional Especializado', true),
('4º Ano', '4º Ano A', 'Manhã', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('4º Ano', '4º Ano B', 'Manhã', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('4º Ano', '4º Ano C', 'Tarde', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('4º Ano', '4º Ano D', 'Tarde', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('5º Ano', '5º Ano A', 'Manhã', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('5º Ano', '5º Ano B', 'Manhã', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('5º Ano', '5º Ano C', 'Tarde', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('5º Ano', '5º Ano D', 'Tarde', 'Ensino Fundamental I', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('6º Ano', '6º Ano A', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('6º Ano', '6º Ano B', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('6º Ano', '6º Ano C', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('6º Ano', '6º Ano D', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('7º Ano', '7º Ano A', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('7º Ano', '7º Ano B', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('7º Ano', '7º Ano C', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('7º Ano', '7º Ano D', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('8º Ano', '8º Ano A', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('8º Ano', '8º Ano B', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('8º Ano', '8º Ano C', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('8º Ano', '8º Ano D', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('9º Ano', '9º Ano A', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('9º Ano', '9º Ano B', 'Manhã', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('9º Ano', '9º Ano C', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('9º Ano', '9º Ano D', 'Tarde', 'Ensino Fundamental II', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IV', 'NCEJA IV A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IV', 'NCEJA IV B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IV', 'NCEJA IV C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IV', 'NCEJA IV D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA V', 'NCEJA V A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA V', 'NCEJA V B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA V', 'NCEJA V C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA V', 'NCEJA V D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VI', 'NCEJA VI A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VI', 'NCEJA VI B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VI', 'NCEJA VI C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VI', 'NCEJA VI D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VII', 'NCEJA VII A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VII', 'NCEJA VII B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VII', 'NCEJA VII C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VII', 'NCEJA VII D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VIII', 'NCEJA VIII A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VIII', 'NCEJA VIII B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VIII', 'NCEJA VIII C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA VIII', 'NCEJA VIII D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IX', 'NCEJA IX A', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IX', 'NCEJA IX B', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IX', 'NCEJA IX C', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('NCEJA IX', 'NCEJA IX D', 'Noite', 'EJA / NCEJA', 'CESMI-Centro Municipal de Estudos Supletivos de Itaguaí', true),
('6º Ano', '6º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('6º Ano', '6º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('6º Ano', '6º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('6º Ano', '6º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('7º Ano', '7º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('7º Ano', '7º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('7º Ano', '7º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('7º Ano', '7º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('8º Ano', '8º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('8º Ano', '8º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('8º Ano', '8º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('8º Ano', '8º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('9º Ano', '9º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('9º Ano', '9º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('9º Ano', '9º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('9º Ano', '9º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 300 Munic. Prefeito Vicente Cicarino', true),
('1º Ano', '1º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('1º Ano', '1º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('1º Ano', '1º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('1º Ano', '1º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('2º Ano', '2º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('2º Ano', '2º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('2º Ano', '2º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('2º Ano', '2º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('3º Ano', '3º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('3º Ano', '3º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('3º Ano', '3º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('3º Ano', '3º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('4º Ano', '4º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('4º Ano', '4º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('4º Ano', '4º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('4º Ano', '4º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('5º Ano', '5º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('5º Ano', '5º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('5º Ano', '5º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('5º Ano', '5º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('6º Ano', '6º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('6º Ano', '6º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('6º Ano', '6º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('6º Ano', '6º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('7º Ano', '7º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('7º Ano', '7º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('7º Ano', '7º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('7º Ano', '7º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('8º Ano', '8º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('8º Ano', '8º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('8º Ano', '8º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('8º Ano', '8º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('9º Ano', '9º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('9º Ano', '9º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('9º Ano', '9º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('9º Ano', '9º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA I', 'NCEJA I A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA I', 'NCEJA I B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA I', 'NCEJA I C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA I', 'NCEJA I D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA II', 'NCEJA II A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA II', 'NCEJA II B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA II', 'NCEJA II C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA II', 'NCEJA II D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA III', 'NCEJA III A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA III', 'NCEJA III B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA III', 'NCEJA III C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA III', 'NCEJA III D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IV', 'NCEJA IV A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IV', 'NCEJA IV B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IV', 'NCEJA IV C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IV', 'NCEJA IV D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA V', 'NCEJA V A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA V', 'NCEJA V B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA V', 'NCEJA V C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA V', 'NCEJA V D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VI', 'NCEJA VI A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VI', 'NCEJA VI B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VI', 'NCEJA VI C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VI', 'NCEJA VI D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VII', 'NCEJA VII A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VII', 'NCEJA VII B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VII', 'NCEJA VII C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VII', 'NCEJA VII D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VIII', 'NCEJA VIII A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VIII', 'NCEJA VIII B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VIII', 'NCEJA VIII C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA VIII', 'NCEJA VIII D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IX', 'NCEJA IX A', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IX', 'NCEJA IX B', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IX', 'NCEJA IX C', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('NCEJA IX', 'NCEJA IX D', 'Noite', 'EJA / NCEJA', 'CIEP 496 Munic. Maestro Francisco Mignone', true),
('Pré I', 'Pré I A', 'Manhã', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré I', 'Pré I B', 'Manhã', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré I', 'Pré I C', 'Tarde', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré I', 'Pré I D', 'Tarde', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré II', 'Pré II A', 'Manhã', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré II', 'Pré II B', 'Manhã', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré II', 'Pré II C', 'Tarde', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('Pré II', 'Pré II D', 'Tarde', 'Educação Infantil', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('1º Ano', '1º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('1º Ano', '1º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('1º Ano', '1º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('1º Ano', '1º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('2º Ano', '2º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('2º Ano', '2º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('2º Ano', '2º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('2º Ano', '2º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('3º Ano', '3º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('3º Ano', '3º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('3º Ano', '3º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('3º Ano', '3º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('4º Ano', '4º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('4º Ano', '4º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('4º Ano', '4º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('4º Ano', '4º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('5º Ano', '5º Ano A', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('5º Ano', '5º Ano B', 'Manhã', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('5º Ano', '5º Ano C', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('5º Ano', '5º Ano D', 'Tarde', 'Ensino Fundamental I', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('6º Ano', '6º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('6º Ano', '6º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('6º Ano', '6º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('6º Ano', '6º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('7º Ano', '7º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('7º Ano', '7º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('7º Ano', '7º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('7º Ano', '7º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('8º Ano', '8º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('8º Ano', '8º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('8º Ano', '8º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('8º Ano', '8º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('9º Ano', '9º Ano A', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('9º Ano', '9º Ano B', 'Manhã', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('9º Ano', '9º Ano C', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true),
('9º Ano', '9º Ano D', 'Tarde', 'Ensino Fundamental II', 'CIEP 497 Munic. Prof.ª Sílvia Tupinambá', true);

-- Usuários
INSERT INTO public.usuarios (id, usuario, nivel, cargo, funcao, unidade, email, ativo) VALUES
('usr-escola', 'Usuário Escola', 'Operacional', 'Agente Administrativo', 'Secretaria Escolar', 'E.M. Elmir Figueira', 'escola@itaguai.rj.gov.br', true),
('usr-smedu', 'Usuário SMEDU', 'Administrador', 'Assessor', 'Gestão FICAI', 'SMEDU', 'smedu@itaguai.rj.gov.br', true),
('usr-ct', 'Joe Amado', 'Conselho Tutelar', 'Conselheiro Tutelar', 'Conselho Tutelar de Itaguaí', 'Conselho Tutelar de Itaguaí', 'joe.amado@edu.itaguai.rj.gov.br', true)
ON CONFLICT (id) DO NOTHING;

-- Permissões
INSERT INTO public.permissoes (id, perfil, modulo, visualizar, cadastrar, editar, excluir) VALUES
('perm-admin', 'Administrador', 'Todos os módulos', true, true, true, true),
('perm-operacional', 'Operacional', 'FICAI', true, true, true, false),
('perm-ct-conselho', 'Conselho Tutelar', 'Conselho Tutelar', true, true, true, false),
('perm-ct-encerramento', 'Conselho Tutelar', 'Encerramento de Casos', true, false, false, false),
('perm-ct-sobre', 'Conselho Tutelar', 'Sobre o Sistema', true, false, false, false)
ON CONFLICT (id) DO NOTHING;

-- Pessoas
INSERT INTO public.pessoas (id, tipo, nome, matricula, unidade, telefone, email, periodo, ativo) VALUES
('pes-dir', 'Diretor', 'Diretor(a) da Unidade', '', 'E.M. Elmir Figueira', '', '', '2026', true),
('pes-ori', 'Orientador', 'Orientador(a) Educacional', '', 'E.M. Elmir Figueira', '', '', '2026', true),
('pes-ct', 'Conselheiro Tutelar', 'Conselheiro(a) responsável', '', 'Conselho Tutelar de Itaguaí', '', '', '2026', true)
ON CONFLICT (id) DO NOTHING;

-- Procedimentos
INSERT INTO public.procedimentos (id, ordem, nome, ativo) VALUES
('proc-1', 1, 'Comunicação/bilhete ao responsável', true),
('proc-2', 2, 'Retorno do estudante à escola', true),
('proc-3', 3, 'Contato telefônico com o responsável', true),
('proc-4', 4, 'Não retorno do aluno à escola', true),
('proc-5', 5, 'Telegrama ao responsável', true),
('proc-6', 6, 'Visita ao domicílio do aluno', true),
('proc-7', 7, 'Comparecimento do responsável e assinatura do termo de responsabilidade', true)
ON CONFLICT (id) DO UPDATE SET ordem = EXCLUDED.ordem, nome = EXCLUDED.nome, ativo = EXCLUDED.ativo;

-- Motivos e Diagnósticos
INSERT INTO public.motivos (id, grupo, nome, dashboard, ativo) VALUES
('mot-1', 'Motivos da ausência', 'Mudança de endereço do aluno com pedido de transferência escolar', false, true),
('mot-2', 'Motivos da ausência', 'Aluno está trabalhando', false, true),
('mot-3', 'Motivos da ausência', 'Mudança de endereço do aluno sem pedido de transferência escolar', false, true),
('mot-4', 'Motivos da ausência', 'Falta recurso para o transporte escolar', false, true),
('mot-5', 'Motivos da ausência', 'Informação de matrícula em outra Unidade Educacional', false, true),
('mot-6', 'Motivos da ausência', 'Falta de motivação para ir à escola', true, true),
('mot-7', 'Motivos da ausência', 'Aluno ficou doente (internação, receita, atestado, cuidados caseiros)', true, true),
('mot-8', 'Motivos da ausência', 'Baixo interesse do responsável (omissão, negligência)', false, true),
('mot-9', 'Motivos da ausência', 'Violência no local de moradia', false, true),
('mot-10', 'Estrutural', 'Falta de Vaga na Escola', false, true),
('mot-11', 'Estrutural', 'Dificuldade de Transporte', false, true),
('mot-12', 'Estrutural', 'Distância da Residência', false, true),
('mot-13', 'Estrutural', 'Barreiras Arquitetônicas', false, true),
('mot-14', 'Estrutural', 'Falta de recursos (didático, vestuário)', false, true),
('mot-15', 'Estrutural', 'Falta de políticas escolares', false, true),
('mot-16', 'Estrutural', 'Falta de educação especial', false, true),
('mot-17', 'Social / Familiar', 'Trabalho Infantil', false, true),
('mot-18', 'Social / Familiar', 'Conflito Familiar', false, true),
('mot-19', 'Social / Familiar', 'Gravidez na Adolescência', false, true),
('mot-20', 'Social / Familiar', 'Vulnerabilidade Social', false, true),
('mot-21', 'Social / Familiar', 'Cuidados familiares', false, true),
('mot-22', 'Saúde', 'Saúde do Aluno (Física)', false, true),
('mot-23', 'Saúde', 'Saúde Mental (Aluno)', false, true),
('mot-24', 'Saúde', 'Doença na Família', false, true),
('mot-25', 'Saúde', 'Dependência Química', false, true),
('mot-26', 'Educacional', 'Dificuldade de Aprendizagem', false, true),
('mot-27', 'Educacional', 'Evasão por Bullying', false, true),
('mot-28', 'Educacional', 'Falta de Motivação', false, true),
('mot-29', 'Educacional', 'Desajuste de Nível/Idade', false, true),
('mot-30', 'Educacional', 'Risco de reprovação', false, true),
('mot-31', 'Segurança Pública e Violência', 'Ameaça ou Violência no Trajeto', false, true),
('mot-32', 'Segurança Pública e Violência', 'Envolvimento com Tráfico', false, true),
('mot-33', 'Segurança Pública e Violência', 'Violência Doméstica', false, true),
('mot-34', 'Segurança Pública e Violência', 'Medida Socioeducativa', false, true),
('mot-35', 'Econômica', 'Inserção no Mercado de Trabalho', false, true),
('mot-36', 'Econômica', 'Falta de Recursos Materiais', false, true),
('mot-37', 'Econômica', 'Insegurança Alimentar', false, true),
('mot-38', 'Econômica', 'Mudança de Domicílio/Migração', false, true),
('mot-39', 'Outros', 'Violência', false, true),
('mot-40', 'Outros', 'Bullying', false, true),
('mot-41', 'Outros', 'Preconceito', false, true)
ON CONFLICT (id) DO NOTHING;

-- Alunos demonstrativos
INSERT INTO public.students (key, nome, social, nascimento, cpf, rg, filiacao, responsavel, residencia, telefone, referencia) VALUES
('aluno-demonstrativo', 'Aluno Demonstrativo', '', '2012-05-14', '', '', 'Responsável 1 / Responsável 2', 'Responsável Demonstrativo', 'Endereço demonstrativo - Itaguaí/RJ', '(21) 99999-0000', 'Parente de referência - Itaguaí/RJ'),
('ana-clara-nascimento', 'Ana Clara Nascimento', '', '2012-03-11', '', '', 'Dados cadastrados no sistema', 'Responsável cadastrado', 'Itaguaí/RJ', '(21) 99999-1111', 'Referência cadastrada'),
('bruno-henrique-silva', 'Bruno Henrique Silva', '', '2013-07-21', '', '', 'Dados cadastrados no sistema', 'Responsável cadastrado', 'Itaguaí/RJ', '(21) 99999-2222', 'Referência cadastrada')
ON CONFLICT (key) DO NOTHING;

-- ==============================================================================
-- ==============================================================================
-- CADASTRO EM MASSA DE USUÁRIOS NO AUTHENTICATOR DO SUPABASE (auth.users)
-- Execute no SQL Editor do Supabase: https://supabase.com/dashboard/project/ojvxsrvmmkjxfgyczypm/sql/new
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  usr_record RECORD;
  usr_id UUID;
  encrypted_pw TEXT;
BEGIN
  -- Tabela temporária de dados para inserção em massa
  CREATE TEMP TABLE IF NOT EXISTS temp_users_seed (
    email TEXT PRIMARY KEY,
    password TEXT,
    role TEXT
  ) ON COMMIT DROP;

  TRUNCATE temp_users_seed;

  -- Inserir Administrador CPD (Senha: T3c4n3x0)
  INSERT INTO temp_users_seed (email, password, role) VALUES
    ('cpdinfra@edu.itaguai.rj.gov.br', 'T3c4n3x0', 'Administrador')
  ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password;

  -- Inserir Conselho Tutelar de Itaguaí (Senha: Ficai-Itaguai)
  INSERT INTO temp_users_seed (email, password, role) VALUES
    ('joe.amado@edu.itaguai.rj.gov.br', 'Ficai-Itaguai', 'Conselho Tutelar')
  ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password;

  -- Inserir os 65 E-mails de Escolas (Senha: FicaiSmedu)
  INSERT INTO temp_users_seed (email, password, role) VALUES
    ('carmem.menezes.adm@gmail.com', 'FicaiSmedu', 'Escola'),
    ('cemaee@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cesmi@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('ciep300@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('ciep496@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('ciep497@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.aparecidaazedo@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.daniellebatistadasilva@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.edsoncruzamado@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.elianelopesbarbosa@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.estreladoceu@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.euclydesjoseborges@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.florentinoelias@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.franciscoxavierdemourabrito@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.jardimmar@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.joaquiminoue@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.mariacristinapadelacabraldasilva@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.mariadelurdessgarcia@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.mariaeduvigesdorosariosilva@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.mariarosagomesdonascimento@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.renatobarbosaladislau@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.ritaferreirafeijo@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.senadorteotoniovilella@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.taniamaramottademenezes@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('cm.teresinhadejesuscamposdefarias@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.camilocuquejo@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.carmemmenezesdireito@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.chapero@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.drjorgeabrahao@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.fazsantacandida@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.santarosa@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eem.tacianobasilio@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('eemcamilocuquejo@gmail.com', 'FicaiSmedu', 'Escola'),
    ('em.acacias@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.alexandreignacio@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.amauriferreira@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.antoniotupinamba@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.argentinacoutinho@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.celalzirosantiago@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.eiderribeirodantas@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.elmirafigueira@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.elmobaptistacoelho@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.fusaofukmati@edu.itaguai.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.jardimmar@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.joaovicentesoares@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.jorgefloresdasilva@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.mariaguilherminadesouzafreire@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.oscarjosedesouza@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.padrerafaelscarfo@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.prefalbeilardgoulartdesouza@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.prefotonirocha@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.prefwilsonpedrofrancisco@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.renatogoncalvesmartins@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.saosebastiao@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.severinadosramosdesousa@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.severinosalustianodefrarias@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.terezadearaujosagario@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.veramericorodriguesdeamorim@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.vereadorgalliacoprata@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.verprofessorarthurbritodecastro@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.vertaianofernandesnunes@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('em.yolandarangelpereira@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('emei.hypolitovieradecarvalho@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('emei.monteirolobato@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola'),
    ('emei.prefisoldacksoncruzdebrito@edu.itaguai.rj.gov.br', 'FicaiSmedu', 'Escola')
  ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password;

  -- Processar inserção/atualização automática no Authenticator (auth.users e auth.identities)
  FOR usr_record IN SELECT * FROM temp_users_seed LOOP
    encrypted_pw := crypt(usr_record.password, gen_salt('bf', 10));

    -- Verifica se o usuário já existe em auth.users
    SELECT id INTO usr_id FROM auth.users WHERE lower(email) = lower(usr_record.email);

    IF usr_id IS NOT NULL THEN
      UPDATE auth.users
      SET
        encrypted_password = encrypted_pw,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
        raw_user_meta_data = jsonb_build_object('role', usr_record.role),
        updated_at = now()
      WHERE id = usr_id;

      -- Atualiza ou insere em auth.identities
      IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = usr_id) THEN
        INSERT INTO auth.identities (
          id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), usr_id::text, usr_id, jsonb_build_object('sub', usr_id::text, 'email', usr_record.email),
          'email', now(), now(), now()
        );
      END IF;
    ELSE
      usr_id := gen_random_uuid();

      INSERT INTO auth.users (
        id, instance_id, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, is_super_admin, role, aud, created_at, updated_at
      ) VALUES (
        usr_id, '00000000-0000-0000-0000-000000000000', usr_record.email, encrypted_pw, now(),
        '{"provider":"email","providers":["email"]}'::jsonb, jsonb_build_object('role', usr_record.role),
        false, 'authenticated', 'authenticated', now(), now()
      );

      INSERT INTO auth.identities (
        id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
      ) VALUES (
        gen_random_uuid(), usr_id::text, usr_id, jsonb_build_object('sub', usr_id::text, 'email', usr_record.email),
        'email', now(), now(), now()
      );
    END IF;
  END LOOP;
END $$;

-- ==============================================================================
-- TABELA: CANCELAMENTOS DE FICAIS (REGISTRO AUDITÁVEL PERMANENTE)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.cancelamentos_ficais (
    id TEXT PRIMARY KEY DEFAULT ('canc-' || gen_random_uuid()),
    ficai_numero TEXT NOT NULL,
    aluno_nome TEXT NOT NULL,
    escola_nome TEXT,
    turma TEXT,
    motivo TEXT NOT NULL,
    justificativa TEXT NOT NULL,
    responsavel TEXT NOT NULL,
    data_cancelamento TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

DROP TRIGGER IF EXISTS set_cancelamentos_ficais_updated_at ON public.cancelamentos_ficais;
CREATE TRIGGER set_cancelamentos_ficais_updated_at
BEFORE UPDATE ON public.cancelamentos_ficais
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Políticas RLS de Segurança
ALTER TABLE public.cancelamentos_ficais ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura pública de cancelamentos" ON public.cancelamentos_ficais;
CREATE POLICY "Permitir leitura pública de cancelamentos" ON public.cancelamentos_ficais FOR SELECT USING (true);
DROP POLICY IF EXISTS "Permitir inserção de cancelamentos" ON public.cancelamentos_ficais;
CREATE POLICY "Permitir inserção de cancelamentos" ON public.cancelamentos_ficais FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Permitir atualização de cancelamentos" ON public.cancelamentos_ficais;
CREATE POLICY "Permitir atualização de cancelamentos" ON public.cancelamentos_ficais FOR UPDATE USING (true);

-- ==============================================================================
-- TABELA: LOGS DO SISTEMA (HISTÓRICO DE ATIVIDADES E EVENTOS AUDITÁVEIS)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.system_logs (
    id TEXT PRIMARY KEY DEFAULT ('log-' || gen_random_uuid()),
    level TEXT NOT NULL DEFAULT 'update',
    action TEXT NOT NULL,
    description TEXT NOT NULL,
    user_email TEXT NOT NULL DEFAULT 'Sistema',
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Limpar logs atuais
TRUNCATE TABLE public.system_logs;

-- Índices de desempenho
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON public.system_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON public.system_logs (level);
CREATE INDEX IF NOT EXISTS idx_system_logs_user_email ON public.system_logs (user_email);

-- Políticas RLS de Segurança para Logs do Sistema
ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura pública de logs" ON public.system_logs;
CREATE POLICY "Permitir leitura pública de logs" ON public.system_logs FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção de logs" ON public.system_logs;
CREATE POLICY "Permitir inserção de logs" ON public.system_logs FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir exclusão de logs" ON public.system_logs;
CREATE POLICY "Permitir exclusão de logs" ON public.system_logs FOR DELETE USING (true);

-- ==============================================================================
-- TABELA: ENCERRAMENTOS E REABERTURAS DE CASOS (encerramentos_ficais)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.encerramentos_ficais (
    id TEXT PRIMARY KEY DEFAULT ('enc-' || gen_random_uuid()),
    ficai_numero TEXT NOT NULL,
    aluno_nome TEXT NOT NULL,
    escola_nome TEXT,
    turma TEXT,
    tipo_acao TEXT NOT NULL DEFAULT 'Encerramento',
    motivo TEXT,
    justificativa TEXT NOT NULL,
    responsavel TEXT NOT NULL,
    data_evento TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Trigger para atualização automática de updated_at
DROP TRIGGER IF EXISTS set_encerramentos_ficais_updated_at ON public.encerramentos_ficais;
CREATE TRIGGER set_encerramentos_ficais_updated_at
BEFORE UPDATE ON public.encerramentos_ficais
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Índices de Desempenho
CREATE INDEX IF NOT EXISTS idx_encerramentos_ficais_numero ON public.encerramentos_ficais (ficai_numero);
CREATE INDEX IF NOT EXISTS idx_encerramentos_ficais_data ON public.encerramentos_ficais (data_evento DESC);

-- Políticas RLS de Segurança
ALTER TABLE public.encerramentos_ficais ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura pública de encerramentos" ON public.encerramentos_ficais;
CREATE POLICY "Permitir leitura pública de encerramentos" ON public.encerramentos_ficais FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção de encerramentos" ON public.encerramentos_ficais;
CREATE POLICY "Permitir inserção de encerramentos" ON public.encerramentos_ficais FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de encerramentos" ON public.encerramentos_ficais;
CREATE POLICY "Permitir atualização de encerramentos" ON public.encerramentos_ficais FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir exclusão de encerramentos" ON public.encerramentos_ficais;
CREATE POLICY "Permitir exclusão de encerramentos" ON public.encerramentos_ficais FOR DELETE USING (true);

-- ==============================================================================
-- TABELA: Sequencial do Número FICAI por Ano Letivo (ficais_sequencial)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ficais_sequencial (
    ano_letivo INT PRIMARY KEY,
    ultimo_numero INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Trigger para atualização automática de updated_at
DROP TRIGGER IF EXISTS set_ficais_sequencial_updated_at ON public.ficais_sequencial;
CREATE TRIGGER set_ficais_sequencial_updated_at
BEFORE UPDATE ON public.ficais_sequencial
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Políticas RLS de Segurança
ALTER TABLE public.ficais_sequencial ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura pública de ficais_sequencial" ON public.ficais_sequencial;
CREATE POLICY "Permitir leitura pública de ficais_sequencial" ON public.ficais_sequencial FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir alteração de ficais_sequencial" ON public.ficais_sequencial;
CREATE POLICY "Permitir alteração de ficais_sequencial" ON public.ficais_sequencial FOR ALL USING (true);

-- ==============================================================================
-- FUNÇÃO DE CADASTRO E ATUALIZAÇÃO DIRETA NO AUTHENTICATOR (auth.users) E TABELA USUÁRIOS
-- Permite que administradores gerenciem usuários e senhas sem precisar abrir o console do Supabase
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS login TEXT;
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

CREATE OR REPLACE FUNCTION public.ficai_upsert_auth_user(
    p_id TEXT,
    p_nome TEXT,
    p_email TEXT,
    p_login TEXT,
    p_nivel TEXT,
    p_cargo TEXT,
    p_funcao TEXT,
    p_unidade TEXT,
    p_senha TEXT,
    p_ativo BOOLEAN DEFAULT true
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id UUID;
    v_encrypted_pw TEXT;
    v_final_id TEXT;
    v_clean_email TEXT;
BEGIN
    v_clean_email := lower(trim(p_email));
    v_final_id := COALESCE(NULLIF(p_id, ''), 'usr-' || gen_random_uuid());

    -- 1. Sincroniza tabela public.usuarios
    INSERT INTO public.usuarios (
        id, usuario, email, login, nivel, cargo, funcao, unidade, ativo, updated_at
    ) VALUES (
        v_final_id, p_nome, v_clean_email, p_login, p_nivel, p_cargo, p_funcao, p_unidade, p_ativo, now()
    )
    ON CONFLICT (id) DO UPDATE SET
        usuario = EXCLUDED.usuario,
        email = EXCLUDED.email,
        login = EXCLUDED.login,
        nivel = EXCLUDED.nivel,
        cargo = EXCLUDED.cargo,
        funcao = EXCLUDED.funcao,
        unidade = EXCLUDED.unidade,
        ativo = EXCLUDED.ativo,
        updated_at = now();

    -- 2. Se e-mail for informado, sincroniza com auth.users e auth.identities
    IF v_clean_email IS NOT NULL AND v_clean_email <> '' THEN
        SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = v_clean_email;

        IF v_user_id IS NOT NULL THEN
            IF p_senha IS NOT NULL AND trim(p_senha) <> '' THEN
                v_encrypted_pw := crypt(p_senha, gen_salt('bf', 10));
                UPDATE auth.users
                SET encrypted_password = v_encrypted_pw,
                    email_confirmed_at = COALESCE(email_confirmed_at, now()),
                    raw_user_meta_data = jsonb_build_object(
                        'name', p_nome,
                        'role', p_nivel,
                        'cargo', p_cargo,
                        'unidade', p_unidade,
                        'login', p_login,
                        'active', p_ativo
                    ),
                    updated_at = now()
                WHERE id = v_user_id;
            ELSE
                UPDATE auth.users
                SET email_confirmed_at = COALESCE(email_confirmed_at, now()),
                    raw_user_meta_data = jsonb_build_object(
                        'name', p_nome,
                        'role', p_nivel,
                        'cargo', p_cargo,
                        'unidade', p_unidade,
                        'login', p_login,
                        'active', p_ativo
                    ),
                    updated_at = now()
                WHERE id = v_user_id;
            END IF;

            IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_user_id) THEN
                INSERT INTO auth.identities (
                    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
                ) VALUES (
                    gen_random_uuid(), v_user_id::text, v_user_id,
                    jsonb_build_object('sub', v_user_id::text, 'email', v_clean_email),
                    'email', now(), now(), now()
                );
            END IF;
        ELSE
            v_user_id := gen_random_uuid();
            v_encrypted_pw := crypt(COALESCE(NULLIF(trim(p_senha), ''), 'FicaiSmedu2026'), gen_salt('bf', 10));

            INSERT INTO auth.users (
                id, instance_id, email, encrypted_password, email_confirmed_at,
                raw_app_meta_data, raw_user_meta_data, is_super_admin, role, aud, created_at, updated_at
            ) VALUES (
                v_user_id, '00000000-0000-0000-0000-000000000000', v_clean_email, v_encrypted_pw, now(),
                '{"provider":"email","providers":["email"]}'::jsonb,
                jsonb_build_object(
                    'name', p_nome,
                    'role', p_nivel,
                    'cargo', p_cargo,
                    'unidade', p_unidade,
                    'login', p_login,
                    'active', p_ativo
                ),
                false, 'authenticated', 'authenticated', now(), now()
            );

            INSERT INTO auth.identities (
                id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), v_user_id::text, v_user_id,
                jsonb_build_object('sub', v_user_id::text, 'email', v_clean_email),
                'email', now(), now(), now()
            );
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'id', v_final_id,
        'usuario', p_nome,
        'email', v_clean_email,
        'login', p_login,
        'nivel', p_nivel,
        'cargo', p_cargo,
        'unidade', p_unidade,
        'ativo', p_ativo
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficai_upsert_auth_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) TO anon, authenticated;