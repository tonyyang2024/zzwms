CLASS lhc_zwms_r_0010 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0010 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0010~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZWMS_MD_0010_REST'.


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.

ENDCLASS.

CLASS lhc_zwms_r_0010 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0010,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0010.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0010 IN LOCAL MODE
         ENTITY zwms_r_0010
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(ls_result) = lt_result[ 1 ].

    IF ls_result-company IS INITIAL.
      ls_result-company = '1000'.
    ENDIF.

    IF ls_result-plant IS INITIAL.
      ls_result-plant = '1000'.
    ENDIF.

    ls_update = CORRESPONDING #( ls_result ).

    "필수입력 체크
    IF ls_result-rmanum IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '납품지시번호 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.

    IF ls_result-rmaline IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '납품지시번호 항목 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.

    IF ls_result-quantity IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '납품지시수량 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.

    IF ls_result-warehousecode IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '입고창고 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.

    IF ls_result-wadat_ist IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '실제 출고일 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.

    ELSE.

      DATA(lv_find) = find( val = ls_result-wadat_ist sub = '-' ).
      IF lv_find > 0.
        DATA(lv_mvtdate) =
            ls_result-wadat_ist && 'T00:00:00'.
        DATA(lv_search_mvtdate) = ls_result-wadat_ist+0(4) && ls_result-wadat_ist+5(2) && ls_result-wadat_ist+8(2).
      ELSE.
        lv_mvtdate =
           |{ ls_result-wadat_ist+0(4) }-{ ls_result-wadat_ist+4(2) }-{ ls_result-wadat_ist+6(2) }T00:00:00|.

        lv_search_mvtdate = ls_result-wadat_ist.
      ENDIF.

    ENDIF.

    "입력값 유효성 점검
    DATA(lv_donum) = |{ ls_result-rmanum ALPHA = IN }|.
    SELECT _doheader~deliverydocument,
           _doheader~deliverydocumenttype,
           _doitem~deliverydocumentitem,
              _doitem~storagelocation
      FROM i_deliverydocument AS  _doheader
      INNER JOIN i_deliverydocumentitem AS  _doitem
      ON _doitem~deliverydocument = _doheader~deliverydocument
     WHERE _doheader~deliverydocument = @lv_donum
      INTO TABLE @DATA(lt_tab).
    IF sy-subrc EQ 0.

      READ TABLE lt_tab TRANSPORTING NO FIELDS
      WITH KEY deliverydocumenttype = 'LR'.
      IF sy-subrc NE 0.
        ls_update-if_flag = 'E'.
        ls_update-if_code = '400'.
        ls_update-if_msg = '납품지시유형이 LR인것들만 처리 가능합니다.'.
        CLEAR lv_error. lv_error = 'X'.
      ENDIF.

      READ TABLE lt_tab TRANSPORTING NO FIELDS
      WITH KEY storagelocation = '4012'.
      IF sy-subrc NE 0.
        READ TABLE lt_tab TRANSPORTING NO FIELDS
        WITH KEY storagelocation = '4015'.
        IF sy-subrc NE 0.
          ls_update-if_flag = 'E'.
          ls_update-if_code = '400'.
          ls_update-if_msg = '창고 인천물류반품[4012], 해외지사 반품[4015]인것들만 처리 가능합니다.'.
          CLEAR lv_error. lv_error = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_error IS INITIAL.

      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service
        EXCEPTIONS
          no_arrangement = 1.

      CHECK sy-subrc <> 1.

      "실제출고일 변경
      CLEAR : uri.
      uri = |/A_ReturnsDeliveryHeader('| && lv_donum && |')|.
      DATA(json) = '{'
                && '"ActualGoodsMovementDate": "' && lv_mvtdate && '", '
                && '"ActualGoodsMovementTime": "PT00H00M00S"'
                && '}'.
      DATA(token) = http_client->get_token_cookies( uri ).
      DATA(etag) = http_client->get_if_match( uri ).
      IF token IS NOT INITIAL AND etag IS NOT INITIAL.
        http_client->patch(
                           EXPORTING
                               uri   = uri
                               json  = json
                               etag  = etag
                          IMPORTING
                               body  = DATA(patch_body)
                              status = DATA(patch_status)
                           ).
      ENDIF.
      IF patch_status EQ 204.
        " 조회를 통해 token, etag 다시 확보
        token = http_client->get_token_cookies( uri ).
        etag = http_client->get_if_match( uri ).

        CLEAR : uri.
        uri = |/PostGoodsReceipt?DeliveryDocument='|
              && lv_donum && |'&ActualGoodsMovementDate=datetime'| && lv_mvtdate && |'|.



        IF token IS NOT INITIAL AND etag IS NOT INITIAL.
          http_client->post(
                         EXPORTING
                             uri = uri
                            etag = etag
                         IMPORTING
                            body = DATA(post_body)
                          status = DATA(post_status)
                       ).
        ENDIF.
        IF post_status EQ 200.

          "Action Response 값이 없으므로 성공일때 납품문서 번호로 입고 문서번호를 찾아본다
          SELECT single materialdocumentyear, materialdocument
            FROM i_materialdocumentitem_2
           WHERE postingdate = @lv_search_mvtdate
             AND deliverydocument = @lv_donum
*             AND goodsmovementtype = '657'
             AND goodsmovementiscancelled = ''
            INTO @DATA(ls_matdoc).
          IF sy-subrc EQ 0.
            ls_update-if_code = '201'.
            ls_update-if_flag = 'Y'.
            ls_update-documentnum = ls_matdoc-materialdocument.
            ls_update-documentyear = ls_matdoc-materialdocumentyear.
            ls_update-if_msg = '자재문서' && ls_update-documentnum && '생성 성공'.
          ENDIF.
        ELSE.
          ls_update-if_code = '400'.
          ls_update-if_flag = 'E'.
          ls_update-if_msg = '반품입고 문서생성 실패 ' && substring_before( val = substring_after( val = post_body
                                                                  sub = '"value":"' )
                                                                  sub = '"' ).
        ENDIF.
      ELSE.
        ls_update-if_code = '400'.
        ls_update-if_flag = 'E'.
        ls_update-if_msg = '실제출고일 변경 실패 ' && substring_before( val = substring_after( val = patch_body
                                                                sub = '"value":"' )
                                                                sub = '"' ).
      ENDIF.


    ENDIF.   "-- ERROR 확인 IF

    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0010 IN LOCAL MODE
    ENTITY zwms_r_0010 UPDATE FIELDS
    ( company plant documentyear documentnum if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0010 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0010 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
