@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] RMA입고처리'
define root view entity ZWMS_R_0010
  as select from zwms_t_0010

{
  key uuid                  as UUID,
      companycode           as Company,
      plant                 as Plant,
      partnum               as PartNum,
      rmanum                as RMANum,
      rmaline               as RMALine,
      quantity              as Quantity,
      ium                   as IUM,
      warehousecode         as WareHouseCode,
      wadat_ist             as WADAT_IST,
      document_year         as DocumentYear,
      document_num          as DocumentNum,
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
