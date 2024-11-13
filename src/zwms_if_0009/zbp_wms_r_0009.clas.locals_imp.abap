CLASS lhc_zwms_r_0009 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0009 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0009~create.

ENDCLASS.

CLASS lhc_zwms_r_0009 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_update      TYPE STRUCTURE FOR UPDATE zwms_r_0009,
           lt_update      TYPE TABLE FOR UPDATE zwms_r_0009,
           ls_update_item TYPE STRUCTURE FOR UPDATE zwms_r_0009_01,
           lt_update_item TYPE TABLE FOR UPDATE zwms_r_0009_01.


    DATA : lv_error(1).

    READ ENTITIES OF zwms_r_0009 IN LOCAL MODE
         ENTITY zwms_r_0009
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(key) = keys[ 1 ].

    "Heaer UUID 기준으로 데이터 조회
    READ ENTITIES OF zwms_r_0009 IN LOCAL MODE
        ENTITY zwms_r_0009
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_header_result)
        "Item 조회
        ENTITY zwms_r_0009 BY \_item
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_item_result).

    DATA(ls_result) = lt_result[ 1 ].
    ls_update = CORRESPONDING #( ls_result ).
    lt_update_item = CORRESPONDING #( lt_item_result ).
    LOOP AT lt_update_item INTO ls_update_item.
      ls_update_item-picknum = ls_result-picknum.
      MODIFY lt_update_item FROM ls_update_item.
    ENDLOOP.

    DATA: ls_d_t09    TYPE zwms_t_0009,
          lt_d_t09    TYPE STANDARD TABLE OF zwms_t_0009,
          ls_d_t09_01 TYPE zwms_t_0009_01,
          lt_d_t09_01 TYPE STANDARD TABLE OF zwms_t_0009_01.

    DATA : lv_vbeln TYPE c LENGTH 10,
           lv_posnr TYPE c LENGTH 6.


    "전송 받은 헤더가 이미 CBO에 있는지 확인하고 있으면 삭제대상
    lv_vbeln = |{ ls_update-picknum ALPHA = IN }|.
    SELECT client, headeruuid, bukrs, werks, vbeln_d,
           lfimg, zboxweight, erdat, ernam
       FROM zwms_t_0009
      WHERE vbeln_d = @lv_vbeln
      INTO TABLE @DATA(lt_t09).
    IF sy-subrc EQ 0.
      "데이터가 있으면 삭제대상
      lt_d_t09 = CORRESPONDING #( lt_t09 ).
    ENDIF.

    "아이템으로 전송되어 온것들도 이미 있으면 삭제대상
    IF lt_item_result[] IS NOT INITIAL.
      SELECT client, itemuuid, headeruuid, vbeln_d, posnr_d, zbox, zboxline,
             zboxweight, zboxweightline
         FROM zwms_t_0009_01
         FOR ALL ENTRIES IN @lt_update_item
        WHERE vbeln_d = @lt_update_item-picknum
          AND posnr_d = @lt_update_item-pickline
        INTO TABLE @DATA(lt_send_item).
      IF sy-subrc EQ 0.
        "데이터가 있으면 삭제대상
        lt_d_t09_01 = CORRESPONDING #( lt_send_item ).
      ENDIF.
    ENDIF.


    "SAP DO 라인항목이 몇개인지 확인
    SELECT deliverydocument, deliverydocumentitem
      FROM i_deliverydocumentitem
     WHERE deliverydocument = @lv_vbeln
      INTO TABLE @DATA(lt_sap_do).

    "09번 테이블내용을 현 시점 sap DO항목을 비교하여 없는것들은 삭제대상
    SELECT client, itemuuid, headeruuid, vbeln_d, posnr_d, zbox, zboxline,
           zboxweight, zboxweightline
       FROM zwms_t_0009_01
      WHERE vbeln_d = @lv_vbeln
      INTO TABLE @DATA(lt_t09_01).

    LOOP AT lt_t09_01 INTO DATA(ls_t09_01).
      CLEAR : lv_posnr.
      lv_posnr = |{ ls_t09_01-posnr_d ALPHA = IN }|.
      READ TABLE lt_sap_do TRANSPORTING NO FIELDS
      WITH KEY deliverydocument = lv_vbeln
               deliverydocumentitem = lv_posnr.
      IF sy-subrc NE 0.
        MOVE-CORRESPONDING ls_t09_01 TO ls_d_t09_01.
        APPEND ls_d_t09_01 TO lt_d_t09_01.
      ENDIF.
    ENDLOOP.

    IF lt_d_t09[] IS NOT INITIAL.
      DELETE  zwms_t_0009 FROM TABLE @lt_d_t09.
    ENDIF.

    IF lt_d_t09_01[] IS NOT INITIAL.
      DELETE  zwms_t_0009_01 FROM TABLE @lt_d_t09_01.
    ENDIF.

    "전송 받은 값 업데이트
    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0009 IN LOCAL MODE
    ENTITY zwms_r_0009_01 UPDATE FIELDS
    ( picknum BoxNum BoxWeight ) WITH lt_update_item
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0009 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0009 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
