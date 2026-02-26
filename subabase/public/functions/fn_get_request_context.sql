CREATE OR REPLACE FUNCTION public.fn_get_request_context(p_caller_function text DEFAULT NULL::text)
 RETURNS TABLE(tenant_id integer, user_id integer, caller_id integer, allowed_schema text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
===========================================================
Copyright    : Tech-Techi, 2026                                                                                  
Created By   : Pratul Dwivedi                                                                               
Modified Date: 07-Feb-2026                                                                               
Description  : Get request context to retrieve logged-in user info
               Supports both JWT authentication and API key authentication
               Validates payload before authentication
===========================================================
Usage Examples:
*/
DECLARE
  v_caller_id INTEGER := NULL;
  v_tenant_id INTEGER;
  v_uid INTEGER;
  v_api_key TEXT;
  v_auth_uid UUID;
  v_payload JSONB;
  v_validation RECORD;
  v_schema TEXT;
BEGIN

  -- 1. Optionally get caller_id from pages if p_caller_function is provided
  IF p_caller_function IS NOT NULL THEN
    SELECT id INTO v_caller_id
    FROM pages
    WHERE p_caller_function IN (
      binding_name_get,
      binding_name_post,
      binding_name_delete
    )
    LIMIT 1;
  END IF;

  -- 2. Get payload and validate BEFORE authentication
  BEGIN
    v_payload := current_setting('request.payload', true)::jsonb;
  EXCEPTION
    WHEN OTHERS THEN
      v_payload := NULL;
  END;
  
  -- 3. Validate payload if caller_id is found and payload exists
  IF v_caller_id IS NOT NULL AND v_payload IS NOT NULL THEN
    SELECT * INTO v_validation 
    FROM fn_validate_request_payload(v_caller_id, v_payload);
    
    IF NOT v_validation.is_valid THEN
      RAISE EXCEPTION 'Payload validation failed: %', v_validation.error_message
        USING ERRCODE = '22023',
              DETAIL = v_validation.validation_details::TEXT;
    END IF;
  END IF;

  -- 4. Try to get x-api-key from request headers
  BEGIN
    v_api_key := current_setting('request.headers', true)::json->>'x-api-key';
  EXCEPTION
    WHEN OTHERS THEN
      v_api_key := NULL;
  END;

  -- 5. Determine authentication method and get tenant_id and uid
  IF v_api_key IS NOT NULL AND v_api_key != '' THEN
    -- API Key Authentication
    SELECT p.tenant_id, p.uid
    INTO v_tenant_id, v_uid
    FROM profiles p
    WHERE 
      p.access_control->>'x-api-key' = v_api_key 
      AND p.access_control->>'x-api-key-active' = 'true'
      AND p.is_active = TRUE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Invalid or inactive API key'
        USING ERRCODE = '28000';
    END IF;
  ELSE
    -- JWT Authentication
    v_auth_uid := auth.uid();
    
    IF v_auth_uid IS NULL THEN
      RAISE EXCEPTION 'No valid authentication found (neither JWT nor API key)'
        USING ERRCODE = '28000';
    END IF;

    SELECT p.tenant_id, p.uid , t.access_control->>'schema'
    INTO v_tenant_id, v_uid , v_schema
    FROM profiles p inner join tenants t
    ON p.tenant_id= t.id
    WHERE p.id = v_auth_uid
      AND t.is_active = TRUE
      AND p.is_active = TRUE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Authenticated user not found or inactive in profiles table'
        USING ERRCODE = '28000';
    END IF;
  END IF;

  IF v_schema IS NULL THEN
    v_schema:='public';
  END IF;
  
  -- 6. Return values
  RETURN QUERY
  SELECT v_tenant_id, v_uid, v_caller_id, v_schema;
END;
$function$
