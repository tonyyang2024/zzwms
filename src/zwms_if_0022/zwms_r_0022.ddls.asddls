@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 중국_GI처리'
define root view entity ZWMS_R_0022 as select from zwms_t_0022
{
    key uuid as Uuid,
    vbeln_d,
    wadat_ist ,
    if_code,
    if_flag,
    if_msg,
    document_year, 
    document_num ,
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
