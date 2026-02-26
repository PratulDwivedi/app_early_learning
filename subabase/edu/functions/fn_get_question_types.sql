CREATE OR replace FUNCTION edu.fn_get_question_types(
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    :
Created Date  :
Description   : Fetch all question types for the tenant
                including the data field (contains rules
                like no_of_questions_in_set).
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_question_types();
================================================
*/
DECLARE
  v_tenant_id     bigint;
  v_user_id       bigint;
  v_caller_id     bigint;
  v_result        jsonb;
  v_total_records int;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_get_question_types');

    -- ── Total count ───────────────────────────────────────────

    SELECT COUNT(*)
    INTO v_total_records
    FROM edu.question_types
    WHERE tenant_id = v_tenant_id
      AND is_active = true;

    -- ── Fetch question types ──────────────────────────────────

    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id',           qt.id,
        'name',         qt.name,
        'icon_url',     qt.icon_url,
        'sort_order',   qt.sort_order,
        'is_active',    qt.is_active,
        'data',         qt.data,        -- includes no_of_questions_in_set etc
        'created_at',   qt.created_at,
        'updated_at',   qt.updated_at
      )
      ORDER BY qt.sort_order ASC, qt.id ASC
    ), '[]'::jsonb)
    INTO v_result
    FROM edu.question_types qt
    WHERE qt.tenant_id = v_tenant_id
      AND qt.is_active = true;

    RETURN public.fn_response_success(
      p_data          := v_result,
      p_message       := 'Question types retrieved successfully.',
      p_total_records := v_total_records,
      p_page_size     := v_total_records,
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_get_question_types',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$;