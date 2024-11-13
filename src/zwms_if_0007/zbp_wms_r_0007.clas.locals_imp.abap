CLASS lhc_zwms_r_0007 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0007 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0007~create.

    CONSTANTS:
      c_scenario TYPE string VALUE 'ZWMS_CS_0001',
      c_service  TYPE string VALUE 'ZWMS_MD_0007_REST'.


    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.

ENDCLASS.

CLASS lhc_zwms_r_0007 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update      TYPE STRUCTURE FOR UPDATE zwms_r_0007,
           lt_update      TYPE TABLE FOR UPDATE zwms_r_0007,
           ls_update_item TYPE STRUCTURE FOR UPDATE zwms_r_0007_01,
           lt_update_item TYPE TABLE FOR UPDATE zwms_r_0007_01.

    DATA : lv_error(1).
    READ ENTITIES OF zwms_r_0007 IN LOCAL MODE
    ENTITY zwms_r_0007
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

    DATA(key) = keys[ 1 ].

    "Heaer UUID 기준으로 데이터 조회
    READ ENTITIES OF zwms_r_0007 IN LOCAL MODE
        ENTITY zwms_r_0007
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_header_result)
        "Item 조회
        ENTITY zwms_r_0007 BY \_item
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_item_result).

    DATA(ls_result) = lt_result[ 1 ].
    ls_update = CORRESPONDING #( ls_result ).
    lt_update_item = CORRESPONDING #( lt_item_result ).

    DATA : lv_item_num TYPE n LENGTH 4.

    LOOP AT lt_update_item INTO ls_update_item.
      ls_update_item-deliverydocument = ls_result-deliverydocument.
      MODIFY lt_update_item FROM ls_update_item.

      CLEAR : uri.
      uri = |/A_OutbDeliveryItem(DeliveryDocument='| && ls_update_item-Deliverydocument && |',DeliveryDocumentItem='| && ls_update_item-Deliverydocumentitem && |')|.

      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service
        EXCEPTIONS
          no_arrangement = 1.

      CHECK sy-subrc <> 1.

      DATA(token) = http_client->get_token_cookies( uri ).
      DATA(etag) = http_client->get_if_match( uri ).

      IF ls_update-ModifyType EQ 'U'.

          DATA(json) = '{' &&
                             ' "ActualDeliveryQuantity" : "' && ls_update_item-Actualdeliveryquantity && '" ' &&
                       '}'.


          IF token IS NOT INITIAL.
            http_client->patch(
            EXPORTING
                uri = uri
                json = json
                etag  = etag
            IMPORTING
                body = DATA(body)
                status = DATA(status)
            ).
          ENDIF.

          IF status EQ 204.
            ls_update-if_code = '204'.
            ls_update-if_flag = 'Y'.
            ls_update-if_msg = '자재문서' && ls_update-Deliverydocument && '변경 성공'.
            ls_update_item-if_code = '204'.
            ls_update_item-if_flag = 'Y'.
            ls_update_item-if_msg = '자재문서' && ls_update-Deliverydocument && '변경 성공'.

          ELSE.
            ls_update-if_code = '400'.
            ls_update-if_flag = 'E'.
            ls_update-if_msg = '문서 변경 실패'.
            ls_update_item-if_code = '400'.
            ls_update_item-if_flag = 'E'.
            ls_update_item-if_msg = '문서 변경 실패'.
          ENDIF.

          MODIFY lt_update_item FROM ls_update_item.

       ENDIF.

       IF ls_update-ModifyType EQ 'D'.

          IF token IS NOT INITIAL.
            http_client->delete(
            EXPORTING
                uri = uri
                etag = etag
            IMPORTING
                body = body
                status = status
            ).
          ENDIF.

          IF status EQ 204.
            ls_update-if_code = '204'.
            ls_update-if_flag = 'Y'.
            ls_update-if_msg = '자재문서' && ls_update-Deliverydocument && '삭제 성공'.
            ls_update_item-if_code = '204'.
            ls_update_item-if_flag = 'Y'.
            ls_update_item-if_msg = '자재문서' && ls_update-Deliverydocument && '삭제 성공'.

          ELSE.
            ls_update-if_code = '400'.
            ls_update-if_flag = 'E'.
            ls_update-if_msg = '문서 삭제 실패'.
            ls_update_item-if_code = '400'.
            ls_update_item-if_flag = 'E'.
            ls_update_item-if_msg = '문서 삭제 실패'.
          ENDIF.

          MODIFY lt_update_item FROM ls_update_item.

       ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zwms_r_0007 IN LOCAL MODE
           ENTITY zwms_r_0007 UPDATE FIELDS
           ( if_code if_flag if_msg ) WITH lt_update
           ENTITY zwms_r_0007_01 UPDATE FIELDS
           ( if_code if_flag if_msg ) WITH lt_update_item
           MAPPED   DATA(ls_mapped_modify)
           FAILED   DATA(lt_failed_modify)
           REPORTED DATA(lt_reported_modify).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0007 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0007 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
