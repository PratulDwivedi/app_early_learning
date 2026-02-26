CREATE OR REPLACE FUNCTION public.fn_response_success(p_data jsonb DEFAULT '[]'::jsonb, p_message text DEFAULT 'OK'::text, p_status_code integer DEFAULT 200, p_total_records integer DEFAULT 1, p_page_size integer DEFAULT 1, p_page_index integer DEFAULT 1, p_page_id integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
    v_print_urls jsonb;
    v_print_urls_data jsonb;
    v_response jsonb;
BEGIN
    IF p_page_id IS NULL THEN
        v_response := jsonb_build_object(
            'is_success', true,
            'data', p_data,
            'paging', jsonb_build_object(
                'total_records', p_total_records,
                'page_size', p_page_size,
                'page_index', p_page_index
            ),
            'message', p_message,
            'status_code', p_status_code
        );
    ELSE
        v_print_urls := fn_get_template_ids_from_variation(
            p_page_id => p_page_id,
            p_data_id => 0,
            p_data => p_data->0
        );
        v_print_urls_data := v_print_urls->'data'->0;
        v_response := jsonb_build_object(
            'is_success', true,
            'data', p_data,
            'paging', jsonb_build_object(
                'total_records', p_total_records,
                'page_size', p_page_size,
                'page_index', p_page_index
            ),
            'print_urls', v_print_urls_data,
            'message', p_message,
            'status_code', p_status_code
        );
    END IF;
    RETURN v_response;
END;
$function$
