@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 중국_CY처리'
define root view entity ZWMS_R_0023 as select from zwms_t_0023
{
    key uuid as Uuid,
    vbeln_d as vbeln_d,
    wadat_ist as wadat_ist,
    document_num,
    document_year,
    if_code,
    if_flag,
    if_msg,
    cflag,
      @Semantics.user.createdBy: true
      created_by            as CREATED_BY,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CREATED_AT,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LAST_CHANGED_BY,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LAST_CHANGED_AT
}

