CLASS lhc_zwms_r_0003 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0003 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0003~create.

    CONSTANTS:
      c_scenario  TYPE string VALUE 'ZWMS_CS_0001',
      c_service   TYPE string VALUE 'ZWMS_IF_0003_01_REST'.

    DATA: http_client TYPE REF TO zcl_cm_0001,
          utils       TYPE REF TO zcl_cm_0002,
          uri         TYPE string.

ENDCLASS.

CLASS lhc_zwms_r_0003 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update      TYPE STRUCTURE FOR UPDATE zwms_r_0003,
           lt_update      TYPE TABLE FOR UPDATE zwms_r_0003,
           ls_update_item TYPE STRUCTURE FOR UPDATE zwms_r_0003_01,
           lt_update_item TYPE TABLE FOR UPDATE zwms_r_0003_01.

    DATA : lv_error(1).

    READ ENTITIES OF zwms_r_0003 IN LOCAL MODE
         ENTITY zwms_r_0003
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(key) = keys[ 1 ].

    "Heaer UUID 기준으로 데이터 조회
    READ ENTITIES OF zwms_r_0003 IN LOCAL MODE
        ENTITY zwms_r_0003
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_header_result)
        "Item 조회
        ENTITY zwms_r_0003 BY \_item
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_item_result).

    DATA(ls_result) = lt_result[ 1 ].
    DATA(ls_result_item) = lt_item_result[ 1 ].
    ls_update = CORRESPONDING #( ls_result ).
    lt_update_item = CORRESPONDING #( lt_item_result ).
    LOOP AT lt_update_item INTO ls_update_item.
      ls_update_item-donum = ls_result-donum.
      MODIFY lt_update_item FROM ls_update_item.
    ENDLOOP.

    "전송받은 값으로 ZWMS_T_0002에서 데이터 확인후 0002 테이블에서 삭제처리
    DATA : lt_delete_02 TYPE STANDARD TABLE OF zwms_t_0002.

    IF lt_item_result[] IS NOT INITIAL.
      SELECT *
        FROM zwms_t_0002
*        FOR ALL ENTRIES IN @lt_item_result
       WHERE bukrs = @ls_result-company
         AND werks = @ls_result-plant
         AND donum = @ls_result-donum
         AND doline = @ls_result_item-doline
        INTO TABLE @lt_delete_02.
    ENDIF.

    IF lt_delete_02 IS NOT INITIAL.

      CLEAR : uri.
      uri = |/A_OutbDeliveryHeader('| && ls_result-donum && |')|.

      CREATE OBJECT http_client
        EXPORTING
          i_scenario     = c_scenario
          i_service      = c_service
        EXCEPTIONS
          no_arrangement = 1.

      CHECK sy-subrc <> 1.

      DATA(token) = http_client->get_token_cookies( uri ).
      DATA(etag) = http_client->get_if_match( uri ).

      IF token IS NOT INITIAL.
        http_client->delete(
        EXPORTING
            uri = uri
            etag  = etag
        IMPORTING
            body = DATA(body)
            status = DATA(status)
        ).
      ENDIF.

      IF status EQ 204.
        ls_update-if_code = '204'.

          DELETE zwms_t_0002 FROM TABLE @lt_delete_02.
          IF sy-subrc EQ 0.
            ls_update-if_flag = 'Y'.
            ls_update-if_msg = '취소처리 성공'.
          ENDIF.

      ELSE.
        ls_update-if_code = '400'.
        ls_update-if_flag = 'E'.
        ls_update-if_msg = '문서 변경 실패 : ' && substring_before( val = substring_after( val = body
                                                                    sub = '"value":"' )
                                                                    sub = '"' )..
      ENDIF.

    ELSE.
      ls_update-if_flag = 'E'.
      ls_update-if_msg = '요청한 취소데이터가 없습니다.'.
    ENDIF.

    "전송 받은 값 업데이트
    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0003 IN LOCAL MODE
    ENTITY zwms_r_0003 UPDATE FIELDS
    ( if_flag if_msg ) WITH lt_update
    ENTITY zwms_r_0003_01 UPDATE FIELDS
    ( donum ) WITH lt_update_item
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0003 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0003 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
