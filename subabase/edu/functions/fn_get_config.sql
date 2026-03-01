CREATE OR REPLACE FUNCTION edu.fn_get_config()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Created Date  : 01-Mar-2026
Modified Date : 01-Mar-2026
Description   : Retrieve the single config record for the tenant.

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_config();
================================================
*/
DECLARE
    v_tenant_id  bigint;
    v_user_id    bigint;
    v_caller_id  bigint;
    v_result     jsonb;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_config');

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
            WHERE tenant_id = v_tenant_id
              AND is_active  = true
            LIMIT 1
        ) t;

        RETURN public.fn_response_success(
            p_data    := COALESCE(v_result, '{}'::jsonb),
            p_message := 'Config retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_get_config',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;