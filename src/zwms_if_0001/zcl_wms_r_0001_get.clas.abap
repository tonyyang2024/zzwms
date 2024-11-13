CLASS zcl_wms_r_0001_get DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.
    DATA: pt_response TYPE TABLE OF zwms_r_0001,
          ps_response LIKE LINE OF pt_response.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZWMS_MD_0001_REST'.



    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_WMS_R_0001_GET IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    IF io_request->is_data_requested( ). "incoming data
      io_request->get_paging( ).

      DATA(lv_offset) = io_request->get_paging( )->get_offset( ).
      DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
      DATA(lv_max_rows) = COND #( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited THEN 0
                                  ELSE lv_page_size ).
      TRY.
          DATA(lt_filter_range) =  io_request->get_filter( )->get_as_ranges( ).
        CATCH cx_rap_query_filter_no_range.
          DATA(lv_no_filter) = 'X'.
      ENDTRY.

      DATA(lv_code) = VALUE string( ).
      DATA(lv_check) = VALUE string( ).

      DATA : lr_custid   TYPE RANGE OF zcm_e_0002_01,
             lr_donum    TYPE RANGE OF zcm_e_0002_01,
             lr_custname TYPE RANGE OF /iam/s_i_obj_ref-object_id1,
             lr_part_no  TYPE RANGE OF /iam/s_i_obj_ref-internal_id1,
             lr_part_hb  TYPE RANGE OF /iam/s_i_obj_ref-object_id1,
             lr_part_jj  TYPE RANGE OF /iam/s_i_obj_ref-object_id1,
             lr_part_cb  TYPE RANGE OF /iam/s_i_obj_ref-object_id1.

      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service
        EXCEPTIONS
          no_arrangement = 1.
      CHECK sy-subrc <> 1.

      LOOP AT lt_filter_range INTO DATA(ls_range).
        CASE ls_range-name.
          WHEN 'CUSTID'.     " 판매처
            lr_custid = VALUE #( ( sign = ls_range-range[ 1 ]-sign
                                 option = ls_range-range[ 1 ]-option
                                    low = ls_range-range[ 1 ]-low ) ).
          WHEN 'CUSTNAME'.
            lr_custname = VALUE #( ( sign = ls_range-range[ 1 ]-sign
                                 option = ls_range-range[ 1 ]-option
                                    low = ls_range-range[ 1 ]-low ) ).
          WHEN 'DONUM'.     " DO 번호
            DATA(ft_donum)     = ls_range-range[ 1 ]-low.
            IF ft_donum IS NOT INITIAL.
              lr_donum = VALUE #( ( sign = 'I' option = 'EQ' low = ft_donum ) ).
            ENDIF.
          WHEN 'PARTNUM'.
            DATA(ft_part_no)     = ls_range-range[ 1 ]-low.       "(필수)품번
            IF ft_part_no IS NOT INITIAL.
              lr_part_no = VALUE #( ( sign = 'I' option = 'EQ' low = ft_part_no ) ).
            ENDIF.
          WHEN 'PARTHB'.
            lr_part_hb = VALUE #( ( sign = ls_range-range[ 1 ]-sign
                      option = ls_range-range[ 1 ]-option
                         low = ls_range-range[ 1 ]-low ) ).
          WHEN 'PARTJJ'.
            lr_part_jj = VALUE #( ( sign = ls_range-range[ 1 ]-sign
                      option = ls_range-range[ 1 ]-option
                         low = ls_range-range[ 1 ]-low ) ).
          WHEN 'PARTCB'.
            lr_part_cb = VALUE #( ( sign = ls_range-range[ 1 ]-sign
                      option = ls_range-range[ 1 ]-option
                         low = ls_range-range[ 1 ]-low ) ).
        ENDCASE.
      ENDLOOP.

      SELECT *
       FROM zwms_r_0001_01
      WHERE donum IN @lr_donum
        AND custid IN @lr_custid
        AND CustName IN @lr_custname
        AND partnum IN @lr_part_no
        AND parthb IN @lr_part_hb
        AND partjj IN @lr_part_jj
        AND partcb IN @lr_part_cb
   ORDER BY ( 'primary key' )
       INTO TABLE @DATA(lt_tab)
       OFFSET @lv_offset UP TO @lv_max_rows ROWS
         .

      IF sy-subrc EQ 0.
        CLEAR : pt_response.
        LOOP AT lt_tab INTO DATA(ls_tab).
          CLEAR ps_response.
          MOVE-CORRESPONDING ls_tab TO ps_response.

          "UnShippedQty = 판매오더 수량 - DO 수량
          ps_response-unshippedqty = ps_response-orderqty - ps_response-reqqty.

          "KRW일때 판매단가는 unitprice에 적용, 외화일때 docunitprice(외화)에 적용
          IF ps_response-currencycode = 'KRW'.
            ps_response-unitprice = ls_tab-netpriceamount.

            "Amount = 단가(KRW) * 출하지시수량
            ps_response-amount = ps_response-unitprice * ps_response-reqqty.
          ELSE.
            ps_response-docunitprice = ls_tab-netpriceamount.
          ENDIF.

          CLEAR : uri.
          uri = |/A_SalesOrderItemText?$filter=SalesOrder eq '{ ls_tab-sonum }'|
             && | and SalesOrderItem eq '{ ls_tab-soline }'|
             && | and Language eq 'KO' and LongTextID eq 'TX01'|.

          DATA(ls_header) = http_client->get( uri ).

          IF ls_header-status EQ '200'.

            "BODY parsing
            DATA: header_msg_s      TYPE REF TO data.
            /ui2/cl_json=>deserialize( EXPORTING json = ls_header-body CHANGING data = header_msg_s ).


            ASSIGN header_msg_s->* TO FIELD-SYMBOL(<fs_result_msg_s>).
            ASSIGN ('<fs_result_msg_s>-d->*') TO FIELD-SYMBOL(<fs_re>).
            " 데이터가 존재하는지 확인
            IF <fs_re> IS ASSIGNED.
              ASSIGN ('<fs_re>-results->*') TO FIELD-SYMBOL(<ft_data>).

              LOOP AT <ft_data> ASSIGNING FIELD-SYMBOL(<fs_data>).
                ASSIGN ('<fs_data>->*') TO FIELD-SYMBOL(<fs_data_str>).
                ASSIGN ('<fs_data_str>-LongText->*') TO FIELD-SYMBOL(<fv_longtext>).
                ps_response-commenttext = <fv_longtext>.
              ENDLOOP.

            ENDIF.

          ELSE.
            "BODY parsing
            DATA: header_msg_f      TYPE REF TO data.
            /ui2/cl_json=>deserialize( EXPORTING json = ls_header-body CHANGING data = header_msg_f ).
            ASSIGN header_msg_f->* TO FIELD-SYMBOL(<fs_result_msg_f>).
          ENDIF.

          APPEND ps_response TO pt_response.
          CLEAR ps_response.
        ENDLOOP.
      ENDIF.

      "데이터 전송 : 데이터 전송이 없으면 response 오류, 무조건 200으로 response 하고 메세지로 알림
      io_response->set_data( pt_response  ).

    ENDIF.
  ENDMETHOD.
ENDCLASS.
