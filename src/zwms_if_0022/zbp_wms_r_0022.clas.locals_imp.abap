CLASS lhc_zwms_r_0022 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0022 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0022~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZWMS_MD_0007_REST'.


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.
ENDCLASS.

CLASS lhc_zwms_r_0022 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0022,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0022.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0022 IN LOCAL MODE
         ENTITY zwms_r_0022
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(ls_result) = lt_result[ 1 ].

    ls_update = CORRESPONDING #( ls_result ).

    "필수입력 체크
    IF ls_result-vbeln_d IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '출하지시번호 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ELSEIF ls_result-wadat_ist IS INITIAL.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = '출고일자 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ELSE.
        DATA(lv_donum) = |{ ls_result-vbeln_d ALPHA = IN }|.
        DATA(lv_mvtdate) = |{ ls_result-wadat_ist+0(4) }-{ ls_result-wadat_ist+4(2) }-{ ls_result-wadat_ist+6(2) }T00:00:00|.
    ENDIF.

    IF lv_error IS INITIAL.
        "삭제
        IF ls_result-cflag EQ 'X'.

            SELECT SINGLE ActualGoodsMovementDate
              FROM I_DeliveryDocument
             WHERE DeliveryDocument = @lv_donum
              INTO @DATA(lv_date).

            CREATE OBJECT http_client
                EXPORTING
                    i_scenario     = c_scenario
                    i_service      = c_service
                EXCEPTIONS
                    no_arrangement = 1.

            CHECK sy-subrc <> 1.

            "실제출고일 변경
            DATA(lv_movement) = |{ lv_date+0(4) }-{ lv_date+4(2) }-{ lv_date+6(2) }T00:00:00|.
            CLEAR : uri.
            uri = |/ReverseGoodsIssue?DeliveryDocument='{ lv_donum }'&ActualGoodsMovementDate=datetime'{ lv_movement }'|.

            DATA(token) = http_client->get_token_cookies( uri ).
            DATA(etag) = http_client->get_if_match( uri ).

            IF token IS NOT INITIAL.
                http_client->post(
                             EXPORTING
                                 uri = uri
                                etag = etag
                             IMPORTING
                                body = DATA(body)
                              status = DATA(status)
                           ).
            ENDIF.

            IF status EQ 200.
                ls_update-if_code = '200'.
                ls_update-if_flag = 'Y'.
                ls_update-if_msg  = '출고 취소처리 완료'.
            ELSE.
                ls_update-if_code = '400'.
                ls_update-if_flag = 'E'.
                ls_update-if_msg  = '출고 취소처리 실패'.
            ENDIF.
        ELSE.

          CREATE OBJECT http_client
            EXPORTING
              i_scenario     = c_scenario
              i_service      = c_service
            EXCEPTIONS
              no_arrangement = 1.

          CHECK sy-subrc <> 1.

          "실제출고일 변경
          CLEAR : uri.
          uri = |/A_OutbDeliveryHeader('{ lv_donum }')|.
          DATA(json) = '{'
                    && '"ActualGoodsMovementDate": "' && lv_mvtdate && '", '
                    && '"ActualGoodsMovementTime": "PT00H00M00S"'
                    && '}'.

          token = http_client->get_token_cookies( uri ).
          etag = http_client->get_if_match( uri ).

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
            uri = |/PostGoodsIssue?DeliveryDocument='{ lv_donum }'|.

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
               WHERE postingdate = @ls_result-wadat_ist
                 AND deliverydocument = @lv_donum
                 AND goodsmovementiscancelled = ''
                INTO @DATA(ls_matdoc).
              IF sy-subrc EQ 0.
                ls_update-if_code = '201'.
                ls_update-if_flag = 'Y'.
                ls_update-document_num = ls_matdoc-materialdocument.
                ls_update-document_year = ls_matdoc-materialdocumentyear.
                ls_update-if_msg = '자재문서' && ls_update-document_num && '생성 성공'.
              ENDIF.

            ELSE.
              ls_update-if_code = '400'.
              ls_update-if_flag = 'E'.
              ls_update-if_msg = '출고처리 문서생성 실패 ' && substring_before( val = substring_after( val = post_body
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
      ENDIF.
    ENDIF.

    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0022 IN LOCAL MODE
    ENTITY zwms_r_0022 UPDATE FIELDS
    ( document_year document_num if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).
  ENDMETHOD.

ENDCLASS.
