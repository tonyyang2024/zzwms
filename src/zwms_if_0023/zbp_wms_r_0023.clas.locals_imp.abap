CLASS lhc_zwms_r_0023 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0023 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0023~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZMES_MD_0004_REST', "자재문서
      c_service2  TYPE string VALUE 'ZWMS_MD_0007_REST'. "출하

    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.

ENDCLASS.

CLASS lhc_zwms_r_0023 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update TYPE STRUCTURE FOR UPDATE zwms_r_0023,
           lt_update TYPE TABLE FOR UPDATE zwms_r_0023.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0023 IN LOCAL MODE
         ENTITY zwms_r_0023
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
      ls_update-if_msg = '출하일자 값은 필수항목입니다.' .
      CLEAR lv_error. lv_error = 'X'.
    ELSE.
        DATA(lv_dom) = ls_result-vbeln_d.
        DATA(lv_mvtdate) = |{ ls_result-wadat_ist+0(4) }-{ ls_result-wadat_ist+4(2) }-{ ls_result-wadat_ist+6(2) }T00:00:00|.
        DATA(lv_now) = |{ sy-datum+0(4) }-{ sy-datum+4(2) }-{ sy-datum+6(2) }T{ sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }|.
    ENDIF.

    IF lv_error IS INITIAL.

        IF ls_result-cflag EQ 'X'.
            DATA : lv_refdom TYPE c LENGTH 10.
            lv_refdom = |{ lv_dom ALPHA = IN }|.

            SELECT _matdoc~materialdocumentyear,
                          _matdoc~materialdocument
              FROM I_MaterialDocumentHeader_2 as _matdoc
             WHERE _matdoc~ReferenceDocument = @lv_refdom
              INTO TABLE @DATA(lt_refdoc).

            IF lt_refdoc[] IS NOT INITIAL.
                LOOP AT lt_refdoc INTO DATA(ls_refdoc).

                    uri = |/Cancel?MaterialDocumentYear='{ ls_refdoc-MaterialDocumentYear }'&MaterialDocument='{ ls_refdoc-MaterialDocument }'|.

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
                      IMPORTING
                          body   = DATA(body)
                          status = DATA(status)
                    ).
                    ENDIF.

                    IF status EQ 200.
                        ls_update-if_code = status.
                        ls_update-if_flag = 'Y'.
                        ls_update-if_msg = |{ ls_update-if_msg }, 자재문서 삭제 성공 : { ls_refdoc-MaterialDocument }|.
                    ELSE.
                        ls_update-if_code = status.
                        ls_update-if_flag = 'Y'.
                        DATA(lv_errormsg) = substring_before( val = substring_after( val = body
                                                                                sub = '"value":"' )
                                                                                sub = '"' ).
                        ls_update-if_msg = |{ ls_update-if_msg }, 자재문서 삭제 실패 : { ls_refdoc-MaterialDocument }, { lv_errormsg }|.
                    ENDIF.
                ENDLOOP.
            ENDIF.

        ELSE.

            DATA(lv_donum) = |{ ls_result-vbeln_d ALPHA = IN }|.
            SELECT _doheader~deliverydocument,
                   _doheader~deliverydocumenttype,
                   _doitem~deliverydocumentitem,
                   _doitem~storagelocation,
                   _doheader~PlannedGoodsIssueDate,
                   _doitem~material,
                   _doitem~plant,
                   _doitem~DeliveryQuantityUnit,
                   _doitem~OriginalDeliveryQuantity
              FROM i_deliverydocument AS  _doheader
              INNER JOIN i_deliverydocumentitem AS  _doitem
              ON _doitem~deliverydocument = _doheader~deliverydocument
             WHERE _doheader~deliverydocument = @lv_donum
              INTO TABLE @DATA(lt_tab).

            IF sy-subrc EQ 0.

              CLEAR : uri.
              uri = '/A_MaterialDocumentHeader'.

              DATA : item_json TYPE string.
              LOOP AT lt_tab INTO DATA(ls_tab).
                DATA : lv_mditem TYPE c LENGTH 4.
                lv_mditem = |{ ls_tab-DeliveryDocumentItem ALPHA = OUT }|.

                IF ( item_json <> '' ).
                    item_json = item_json && ','.
                ENDIF.

                item_json = item_json && '{'
                                      "&& '"MaterialDocumentYear" : "' && ls_tab-PlannedGoodsIssueDate+0(4) && '",'
                                      "&& '"MaterialDocumentItem" : "' && lv_mditem && '",'
                                      && '"Material" : "' && ls_tab-Material && '",'
                                      && '"Plant" : "' && ls_tab-Plant && '",'
                                      && '"StorageLocation" : "' && ls_tab-StorageLocation && '",'
                                      && '"GoodsMovementType" : "311",'
                                      && '"EntryUnit" : "' && ls_tab-DeliveryQuantityUnit && '",'
                                      && '"QuantityInEntryUnit" : "' && ls_tab-OriginalDeliveryQuantity && '",'
                                      && '"IssuingOrReceivingPlant" : "' && ls_tab-Plant && '",'
                                      && '"IssuingOrReceivingStorageLoc" : "5000"'
                                      && '}'.
              ENDLOOP.

              DATA(json) = '{'
                        "&& '"MaterialDocumentYear": "' && ls_tab-PlannedGoodsIssueDate+0(4) && '", '
                        && '"DocumentDate": "' && lv_now && '", '
                        && '"PostingDate": "' && lv_mvtdate && '", '
                        && '"ReferenceDocument": "' && ls_tab-DeliveryDocument && '", '
                        && '"GoodsMovementCode": "04", '
                        && '"to_MaterialDocumentItem" : ['
                        &&       item_json
                        && '   ]'
                        && ' }'.

              CREATE OBJECT http_client
                EXPORTING
                  i_scenario     = c_scenario
                  i_service      = c_service
                EXCEPTIONS
                  no_arrangement = 1.

              CHECK sy-subrc <> 1.

              token = http_client->get_token_cookies( uri ).

              IF token IS NOT INITIAL.
                http_client->post(
                  EXPORTING
                      uri = uri
                      json = json
                  IMPORTING
                      body   = body
                      status = status
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

                "DO변경
                LOOP AT lt_tab INTO ls_tab.
                    lv_mditem = |{ ls_tab-DeliveryDocumentItem ALPHA = OUT }|.

                    uri = |/A_OutbDeliveryItem(DeliveryDocument='{ ls_tab-DeliveryDocument }',DeliveryDocumentItem='{ lv_mditem }')|.

                    json = '{'
                        && '"StorageLocation": "5000"'
                        && ' }'.

                    CREATE OBJECT http_client
                    EXPORTING
                      i_scenario     = c_scenario
                      i_service      = c_service2
                    EXCEPTIONS
                      no_arrangement = 1.

                  CHECK sy-subrc <> 1.

                  token = http_client->get_token_cookies( uri ).
                  DATA(etag) = http_client->get_if_match( uri ).

                  IF token IS NOT INITIAL and etag IS NOT INITIAL.
                    http_client->patch(
                      EXPORTING
                          uri = uri
                          etag = etag
                          json = json
                      IMPORTING
                          body   = body
                          status = status
                  ).
                  ENDIF.

                  IF status EQ 204.
                    ls_update-if_code = status.
                    ls_update-if_flag = 'Y'.
                    ls_update-if_msg = |{ ls_update-if_msg }, DO 변경 성공 : { ls_tab-DeliveryDocument }, { ls_tab-DeliveryDocumentItem }|.
                  ELSE.
                    ls_update-if_code = status.
                    ls_update-if_flag = 'E'.
                    lv_errormsg = '문서 생성 실패 : ' && substring_before( val = substring_after( val = body
                                                                        sub = '"value":"' )
                                                                        sub = '"' ).
                    ls_update-if_msg = |{ ls_update-if_msg }, DO 변경 실패 : { ls_tab-DeliveryDocument }, { ls_tab-DeliveryDocumentItem }, { lv_errormsg }|.
                  ENDIF.
                ENDLOOP.

              ELSE.
                ls_update-if_code = '400'.
                ls_update-if_flag = 'E'.
                ls_update-if_msg = '문서 생성 실패 : ' && substring_before( val = substring_after( val = body
                                                                        sub = '"value":"' )
                                                                        sub = '"' ).
              ENDIF.
            ENDIF.   "-- ERROR 확인 IF
        ENDIF.
    ENDIF.

    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0023 IN LOCAL MODE
    ENTITY zwms_r_0023 UPDATE FIELDS
    ( document_year document_num if_flag if_code if_msg ) WITH lt_update
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).
  ENDMETHOD.

ENDCLASS.
