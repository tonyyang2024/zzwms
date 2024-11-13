@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 납품지시서 취소 처리-아이템'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZWMS_R_0003_01
  as select from zwms_t_0003_01 as _Item
  association to parent ZWMS_R_0003 as _Header on $projection.Headeruuid = _Header.Headeruuid
{
  key itemuuid   as Itemuuid,
      headeruuid as Headeruuid,
      donum      as DONum,
      doline     as DOLine,
      _Header
}
