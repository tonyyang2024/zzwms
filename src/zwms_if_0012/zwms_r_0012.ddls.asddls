@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] DMR 출고 처리'
define root view entity ZWMS_R_0012
  as select from zwms_t_0012

{
  key uuid                  as UUID,
      companycode           as Company,
      plant                 as Plant,
      partnum               as PartNum,
      vendorid              as VendorID,
      quantity              as Quantity,
      ium                   as IUM,
      fromwhse              as FromWhse,
      towhse                as ToWhse,
      inspectorid           as InspectorID,
      dmrreasoncode         as DMRReasonCode,
      document_year         as DOCUMENT_YEAR,
      document_num          as DOCUMENT_NUM,
      if_flag               as IF_FLAG,
      if_uuid               as IF_UUID,
      if_code               as IF_CODE,
      if_msg                as IF_MSG,
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
