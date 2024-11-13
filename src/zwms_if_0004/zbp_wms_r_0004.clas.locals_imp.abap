CLASS lhc_zwms_r_0004 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zwms_r_0004 RESULT result.

    METHODS create FOR DETERMINE ON SAVE
      IMPORTING keys FOR zwms_r_0004~create.

ENDCLASS.

CLASS lhc_zwms_r_0004 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

      DATA : ls_update      TYPE STRUCTURE FOR UPDATE zwms_r_0004,
           lt_update      TYPE TABLE FOR UPDATE zwms_r_0004,
           ls_update_item TYPE STRUCTURE FOR UPDATE zwms_r_0004_01,
           lt_update_item TYPE TABLE FOR UPDATE zwms_r_0004_01.


    DATA : lv_error(1).

    READ ENTITIES OF zwms_r_0004 IN LOCAL MODE
         ENTITY zwms_r_0004
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result)
         FAILED    DATA(lt_failed)
         REPORTED  DATA(lt_reported).

    DATA(key) = keys[ 1 ].

    "Heaer UUID 기준으로 데이터 조회
    READ ENTITIES OF zwms_r_0004 IN LOCAL MODE
        ENTITY zwms_r_0004
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_header_result)
        "Item 조회
        ENTITY zwms_r_0004 BY \_item
        ALL FIELDS WITH VALUE #( ( headeruuid = key-headeruuid ) )
        RESULT DATA(lt_item_result).

    DATA(ls_result) = lt_result[ 1 ].
    ls_update = CORRESPONDING #( ls_result ).
    lt_update_item = CORRESPONDING #( lt_item_result ).
    LOOP AT lt_update_item INTO ls_update_item.
      ls_update_item-donum = ls_result-donum.
      MODIFY lt_update_item FROM ls_update_item.
    ENDLOOP.


    "전송 받은 값 업데이트
    APPEND ls_update TO lt_update.

    MODIFY ENTITIES OF zwms_r_0004 IN LOCAL MODE
    ENTITY zwms_r_0004_01 UPDATE FIELDS
    ( donum ) WITH lt_update_item
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).


  ENDMETHOD.

ENDCLASS.

CLASS lsc_zwms_r_0004 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zwms_r_0004 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
