@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 박스정보 수신-아이템'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZWMS_R_0009_01
  as select from zwms_t_0009_01 as _Item
  association to parent ZWMS_R_0009 as _Header on $projection.Headeruuid = _Header.Headeruuid
{
  key itemuuid       as Itemuuid,
      headeruuid     as Headeruuid,
      vbeln_d        as PickNum,
      posnr_d        as PickLine,
      zbox           as BoxNum,
      zboxline       as BoxLine,
      zboxweight     as BoxWeight,
      zboxweightline as BoxWeightline,
      _Header

}
