CREATE OR REPLACE FUNCTION public.fn_get_profile()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
/*
============================================================================================
Copyright     : Tech-Techi, 2025
Created By    : Pratul Dwivedi
Modified Date : 07-Jun-2025
Description   : Get user profile after successful login

Example:
SET LOCAL request.jwt.claim.sub  ='4657c4e0-2357-4679-b802-061989d64df3';
SELECT fn_get_profile();
============================================================================================
*/
DECLARE
    v_result jsonb;
    v_tenant_id integer := NULL;
    v_user_id integer := NULL;
    v_caller_id integer := NULL;
BEGIN
    BEGIN  -- Main logic block

         -- Get tenant/user/caller context
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM fn_get_request_context('fn_get_profile');

        -- Fetch profile data
        SELECT jsonb_agg(to_jsonb(t)) INTO v_result
        FROM (
            SELECT
                t.name AS tenant_name,
                p.id,
                p.uid,
                p.tenant_id,
                p.email,
                p.user_name,
                p.full_name,
                p.data
            FROM public.profiles p
            INNER JOIN public.tenants t ON p.tenant_id = t.id
            WHERE p.uid = v_user_id
              AND p.is_active = TRUE
        ) t;

        -- Raise error if profile not found
        IF v_result IS NULL THEN
            RAISE EXCEPTION 'Profile not found or inactive';
        END IF;

        -- Return standardized success response
        RETURN fn_response_success(
            p_data := v_result,
            p_message := 'Profile retrieved successfully',
            p_total_records := 1,
            p_page_size := 1,
            p_page_index := 1
        );

    EXCEPTION
        WHEN OTHERS THEN
            RETURN fn_response_error(
                p_function_name := 'fn_get_profile',
                p_message := SQLERRM,
                p_data := '[]'::jsonb,
                p_tenant_id := v_tenant_id,
                p_user_id := v_user_id
            );
    END;
END;
$function$
