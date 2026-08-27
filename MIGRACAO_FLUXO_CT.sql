-- ==============================================================================
-- FICAI 4.0 — MIGRAÇÃO DO FLUXO ESCOLA <-> CONSELHO TUTELAR
-- Execute uma única vez no SQL Editor do Supabase antes de publicar esta versão.
-- Script idempotente: pode ser executado novamente sem duplicar colunas.
-- ==============================================================================

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
ALTER TABLE public.ficai_info_entries ADD COLUMN IF NOT EXISTS action TEXT;

CREATE INDEX IF NOT EXISTS idx_ficais_status_tramitacao_ct ON public.ficais(status_tramitacao_ct);
CREATE INDEX IF NOT EXISTS idx_ficais_escola_status_ct ON public.ficais(escola, status_tramitacao_ct);

-- Migração básica de registros legados, sem alterar situação pedagógica.
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
-- CADASTRO E ATUALIZAÇÃO DE USUÁRIOS NO AUTHENTICATOR DO SUPABASE (auth.users)
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

