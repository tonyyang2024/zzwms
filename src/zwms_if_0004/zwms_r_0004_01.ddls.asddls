@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 출고유보해제-아이템'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZWMS_R_0004_01
  as select from zwms_t_0004_01 as _Item
  association to parent ZWMS_R_0004 as _Header on $projection.Headeruuid = _Header.Headeruuid
{
  key itemuuid   as Itemuuid,
      headeruuid as Headeruuid,
      vbeln_vl   as DONum,
      posnr_vl   as DOLine,
      lgort      as StorageLocation,
      _Header
}
