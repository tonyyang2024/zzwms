CLASS lhc_zwms_r_0008 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0008 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0008~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZMES_MD_0004_REST'.  "자재문서 POST용


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.
ENDCLASS.

CLASS lhc_zwms_r_0008 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0008,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0008.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0008 IN LOCAL MODE
         ENTITY zwms_r_0008
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(ls_result) = lt_result[ 1 ].

    IF ls_result-companycode IS INITIAL.
      ls_result-companycode = '1000'.
    ENDIF.

    DATA lv_packslipitem TYPE n LENGTH 4.
    lv_packslipitem = ls_result-packslipitem.

    ls_update = CORRESPONDING #( ls_result ).

    "입력값 체크
    IF ls_result-plant NE '1000'.
      ls_update-if_flag = 'E'.
      ls_update-if_code = '400'.
      ls_update-if_msg = 'Plant[PLANT]가 1000이 아니라 처리할수 없습니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ENDIF.


    IF lv_error IS INITIAL.
      DATA(lv_find) = find( val = ls_result-incomingdate sub = '-' ).
      IF lv_find > 0.
        DATA(lv_posting) =
            ls_result-incomingdate && 'T00:00:00'.
      ELSE.
        lv_posting =
           |{ ls_result-incomingdate+0(4) }-{ ls_result-incomingdate+4(2) }-{ ls_result-incomingdate+6(2) }T00:00:00|.
      ENDIF.

      SELECT SINGLE inventoryspecialstocktype,
                 specialstockidfgsalesorder,
                 specialstockidfgsalesorderitem
     FROM i_materialdocumentitem_2
     WHERE materialdocumentyear = @ls_result-packslip+0(4)
       AND materialdocument     = @ls_result-packslip+4(10)
       AND materialdocumentitem = @ls_result-packslipitem
      INTO @DATA(ls_matitem).

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
                && ' "MaterialDocumentItemText": "' && ls_result-packslip && lv_packslipitem && '",'
                && ' "GoodsMovementType": "' && 311 && '",'
                && ' "QuantityInEntryUnit": "' && ls_result-qty && '",'
                && ' "IssuingOrReceivingPlant": "' && ls_result-plant && '",'             "1000
                && ' "IssuingOrReceivingStorageLoc": "' && ls_result-storage_to && '"'.

      "24/09/02 추가내용
      CASE ls_matitem-inventoryspecialstocktype .
        WHEN 'E'.
          json = json && ','
       && ' "InventorySpecialStockType": "' && ls_matitem-inventoryspecialstocktype && '",'
       && ' "SpecialStockIdfgSalesOrder": "' && ls_matitem-specialstockidfgsalesorder && '",'
       && ' "SpecialStockIdfgSalesOrderItem": "' && ls_matitem-specialstockidfgsalesorderitem && '",'
       && ' "IssgOrRcvgSpclStockInd": "' && ls_matitem-inventoryspecialstocktype && '"' .
        WHEN ''.
          json = json && ','
       && ' "InventorySpecialStockType": "' && ls_matitem-inventoryspecialstocktype && '",'
       && ' "IssgOrRcvgSpclStockInd": "' && ls_matitem-inventoryspecialstocktype && '"' .
      ENDCASE.

      json = json
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

        SELECT SINGLE MaterialDocumentYear, MaterialDocument, MaterialDocumentItem
                 FROM i_materialdocumentitem_2
                WHERE materialdocumentyear EQ @ls_update-document_year
                  AND materialdocument EQ @ls_update-document_num
                  AND debitcreditcode EQ 'H'
                 INTO @DATA(ls_doc).

        ls_update-packslip = ls_update-document_year && ls_update-document_num && ls_doc-MaterialDocumentItem.
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

    MODIFY ENTITIES OF zwms_r_0008 IN LOCAL MODE
    ENTITY zwms_r_0008 UPDATE FIELDS
    ( companycode packslip document_year document_num if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0008 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0008 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
