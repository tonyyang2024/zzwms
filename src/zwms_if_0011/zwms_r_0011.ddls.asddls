@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 재고이동 처리'
define root view entity ZWMS_R_0011
  as select from zwms_t_0011

{

  key uuid                  as UUID,
      companycode           as COMPANYCODE,
      plant                 as PLANT,
      product               as PRODUCT,
      movementdate          as MOVEMENTDATE,
      storage_from          as STORAGE_FROM,
      storage_to            as STORAGE_TO,
      qty                   as QTY,
      document_year         as DOCUMENT_YEAR,
      document_num          as DOCUMENT_NUM,
      reason                as REASON,
      if_code               as IF_CODE,
      if_msg                as IF_MSG,
      if_uuid               as IF_UUID,
      if_flag               as IF_FLAG,
      @Semantics.user.createdBy: true
      created_by            as CREATED_BY,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CREATED_AT,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LAST_CHANGED_BY,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LAST_CHANGED_AT,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LOCAL_LAST_CHANGED_AT
}
