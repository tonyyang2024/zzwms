CLASS lhc_zwms_r_0012 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0012 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0012~create.

    CONSTANTS:
      c_scenario    TYPE string VALUE 'ZWMS_CS_0001',
      c_service_def TYPE string VALUE 'ZMES_MD_0005_REST',   "결함문서 등록용
      c_service     TYPE string VALUE 'ZMES_MD_0004_REST'.  "자재문서 POST용


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.
ENDCLASS.

CLASS lhc_zwms_r_0012 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0012,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0012.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0012 IN LOCAL MODE
         ENTITY zwms_r_0012
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

    "입력값 체크
    IF ls_result-plant NE '1000'.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = 'Plant[PLANT]가 1000이 아니라 처리할수 없습니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.

    IF ls_result-fromwhse NE '4011'.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = 'FromWhse가 4011이 아니라 처리할수 없습니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.


    IF lv_error IS INITIAL.

      "1. 결함문서 등록
      SELECT SINGLE defectcodetext
        FROM zwms_r_0012_01
       WHERE defectcodegroup = @ls_result-dmrreasoncode+0(2)
         AND defectcode = @ls_result-dmrreasoncode+2(3)
        INTO @DATA(lv_defecttext).

      DATA(json) = '{'
                && '"DefectCategory": "06", '
                && '"DefectText": "원부자재부적합(폐기)", '
                && |"DefectCodeGroup": "{ ls_result-dmrreasoncode+0(2) }", |
                && |"DefectCode": "{ ls_result-dmrreasoncode+2(3) }", |
                && '"DefectiveQuantity": ' && ls_result-quantity && ', '
                && '"DefectiveQuantityUnit": "' && ls_result-ium && '", '
                && '"Material": "' && ls_result-partnum && '", '
                && '"Plant": "' && ls_result-plant && '", '
*                  && '"QualityIssueReference": "' && lv_ref && '", '
                && '"_DefectDetailedDescription" : ['
                && '{'
                && '  "DefectLongText": "' && lv_defecttext && '"'
                && '}'
                && ']}'
            .
      uri = '/Defect'.

      "get token
      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service_def
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
                body   = DATA(def_body)
                status = DATA(def_status)
        ).
      ENDIF.

      IF def_status EQ 201.
        ls_update-if_code = '201'.
        ls_update-if_flag = 'Y'.
        DATA(lv_defect) = substring_before( val = substring_after( val = def_body
                                         sub = '"Defect":"' )
                                         sub = '"' ).

      ELSE.
        ls_update-if_code = '400'.
        ls_update-if_flag = 'E'.
        ls_update-if_msg =
             '결함문서 등록 실패 : ' && substring_before( val = substring_after( val = def_body
                                                            sub = '"message":"' )
                                                            sub = '"' ).
      ENDIF.

      "2. 결함문서 등록 성공하면 자재문서 생성
      IF lv_defect IS NOT INITIAL.

        DATA(lv_posting) = |{ sy-datum+0(4) }-{ sy-datum+4(2) }-{ sy-datum+6(2) }T00:00:00|.

        CLEAR : uri, json.
        uri = '/A_MaterialDocumentHeader'.
        json = '{'
                  && '"PostingDate": "' && lv_posting && '", '
                  && '"GoodsMovementCode": "04", '
                  && '"to_MaterialDocumentItem" : ['
                  && '{'
                  && ' "Plant": "' && ls_result-plant && '",'
                  && ' "StorageLocation": "' && ls_result-fromwhse && '",'    "4011
                  && ' "Material": "' && ls_result-partnum && '",'
                  && ' "MaterialDocumentItemText": "' && ls_result-dmrreasoncode && '",'
                  && ' "GoodsMovementType": "' && 311 && '",'
                  && ' "QuantityInEntryUnit": "' && ls_result-quantity && '",'
                  && ' "IssuingOrReceivingPlant": "' && ls_result-plant && '",'
                  && ' "IssuingOrReceivingStorageLoc": "' && ls_result-towhse && '"'     "3002고정 제외 09/23
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

        clear : token.
        token = http_client->get_token_cookies( uri ).

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
      ENDIF.

    ENDIF.   "-- ERROR 확인 IF

    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0012 IN LOCAL MODE
    ENTITY zwms_r_0012 UPDATE FIELDS
    ( company plant document_year document_num if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0012 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0012 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
