CREATE OR REPLACE FUNCTION edu.fn_save_config(
    p_name  text    DEFAULT NULL,
    p_data  jsonb   DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Created Date  : 01-Mar-2026
Modified Date : 01-Mar-2026
Description   : Insert or update the single config record for the tenant.
                If a config already exists → UPDATE (merge data).
                If no config exists        → INSERT.

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_save_config(
    p_name := 'App Config',
    p_data := '{"total_questions": 10, "total_duration_minutes": 30}'::jsonb
);
================================================
*/
DECLARE
    v_tenant_id  bigint;
    v_user_id    bigint;
    v_caller_id  bigint;
    v_config_id  bigint;
    v_result     jsonb;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_save_config');

        -- ── Validations ───────────────────────────────────────

        IF p_data IS NULL THEN
            RAISE EXCEPTION 'data is required.';
        END IF;

        -- ── Check if config already exists ────────────────────

        SELECT id INTO v_config_id
        FROM edu.configs
        WHERE tenant_id = v_tenant_id
        LIMIT 1;

        IF FOUND THEN
            -- ── UPDATE: merge incoming data with existing data ─

            UPDATE edu.configs
            SET
                name       = COALESCE(p_name, name),
                data       = data || p_data,        -- merge, incoming keys win
                updated_by = v_user_id,
                updated_at = now()
            WHERE id = v_config_id;

        ELSE
            -- ── INSERT: create first config record ─────────────

            IF p_name IS NULL THEN
                RAISE EXCEPTION 'name is required when creating a new config.';
            END IF;

            INSERT INTO edu.configs (
                name,
                data,
                is_active,
                tenant_id,
                created_by,
                created_at
            ) VALUES (
                p_name,
                p_data,
                true,
                v_tenant_id,
                v_user_id,
                now()
            )
            RETURNING id INTO v_config_id;

        END IF;

        -- ── Return saved record ───────────────────────────────

        SELECT to_jsonb(t)
        INTO v_result
        FROM (
            SELECT
                id,
                name,
                data,
                is_active,
                created_at,
                updated_at
            FROM edu.configs
            WHERE id = v_config_id
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Config saved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_save_config',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;