CLASS lhc_zwms_r_0011 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0011 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0011~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZMES_MD_0004_REST'.  "자재문서 POST용


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.
ENDCLASS.

CLASS lhc_zwms_r_0011 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.
    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0011,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0011.
    DATA : lv_error(1).

    READ ENTITIES OF zwms_r_0011 IN LOCAL MODE
         ENTITY zwms_r_0011
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(ls_result) = lt_result[ 1 ].
    IF ls_result-companycode IS INITIAL.
      ls_result-companycode = '1000'.
    ENDIF.

    ls_update = CORRESPONDING #( ls_result ).

    "입력값 체크
    IF ls_result-plant NE '1000'.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = 'Plant[PLANT]가 1000이 아니라 처리할수 없습니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.


    IF lv_error IS INITIAL.
      IF ls_result-movementdate IS NOT INITIAL.
        DATA(lv_find) = find( val = ls_result-movementdate sub = '-' ).
        IF lv_find > 0.
          DATA(lv_posting) =
              ls_result-movementdate && 'T00:00:00'.
        ELSE.
          lv_posting =
             |{ ls_result-movementdate+0(4) }-{ ls_result-movementdate+4(2) }-{ ls_result-movementdate+6(2) }T00:00:00|.
        ENDIF.
      ELSE.
        lv_posting = |{ sy-datum+0(4) }-{ sy-datum+4(2) }-{ sy-datum+6(2) }T00:00:00|.
      ENDIF.

      CLEAR : uri.
      uri = '/A_MaterialDocumentHeader'.
      DATA(json) = '{'
                && '"PostingDate": "' && lv_posting && '", '
                && '"GoodsMovementCode": "04", '
                && '"to_MaterialDocumentItem" : ['
                && '{'
                && ' "Plant": "' && ls_result-plant && '",'                               "1000
                && ' "StorageLocation": "' && ls_result-storage_from && '",'
                && ' "Material": "' && ls_result-product && '",'
                && ' "GoodsMovementType": "' && 311 && '",'
                && ' "QuantityInEntryUnit": "' && ls_result-qty && '",'
                && ' "IssuingOrReceivingPlant": "' && ls_result-plant && '",'             "1000
                && ' "IssuingOrReceivingStorageLoc": "' && ls_result-storage_to && '",'
                && ' "MaterialDocumentItemText": "' && ls_result-reason && '"'
                && '}'
                && ']}'.

      "get token
      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service
        EXCEPTIONS
          no_arrangement = 1.

      CHECK sy-subrc <> 1.

      DATA(token) = http_client->get_token_cookies( uri ).

      IF token IS NOT INITIAL.
        http_client->post(
          EXPORTING
              uri = uri
              json = json
          IMPORTING
              body   = DATA(body)
              status = DATA(status)
      ).
      ENDIF.

      IF status EQ 201.
        ls_update-if_code = '201'.
        ls_update-if_flag = 'Y'.
        ls_update-document_num = substring_before( val = substring_after( val = body
                                             sub = '"MaterialDocument":"' )
                                             sub = '"' ).
        ls_update-document_year = substring_before( val = substring_after( val = body
                                     sub = '"MaterialDocumentYear":"' )
                                     sub = '"' ).
        ls_update-if_msg = '자재문서' && ls_update-document_num && '생성 성공'.

      ELSE.
        ls_update-if_code = '400'.
        ls_update-if_flag = 'E'.
        ls_update-if_msg = '문서 생성 실패 : ' && substring_before( val = substring_after( val = body
                                                                sub = '"value":"' )
                                                                sub = '"' ).
      ENDIF.
    ENDIF.   "-- ERROR 확인 IF

    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0011 IN LOCAL MODE
    ENTITY zwms_r_0011 UPDATE FIELDS ( companycode document_year document_num if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0011 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0011 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
