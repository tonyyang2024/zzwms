@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 납품지시서 취소 처리'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZWMS_R_0003
  as select from zwms_t_0003
  composition [0..*] of ZWMS_R_0003_01 as _Item
{
  key headeruuid            as Headeruuid,
      bukrs                 as Company,
      werks                 as Plant,
      donum                 as DONum,
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
      local_last_changed_at as LOCAL_LAST_CHANGED_AT,
      _Item
}
