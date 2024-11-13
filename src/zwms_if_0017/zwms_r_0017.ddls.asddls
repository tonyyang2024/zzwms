@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 창고 조회'
define root view entity ZWMS_R_0017 
  as select from I_StorageLocation
  association [1..1] to I_CompanyCode as _Company on _Company.CompanyCode = '1000'
{
  key _Company.CompanyCode       ,
  key I_StorageLocation.Plant    ,
      I_StorageLocation.StorageLocation    ,
      I_StorageLocation.StorageLocationName 
}
where I_StorageLocation.Plant = '1000'
