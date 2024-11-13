@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 품목 수정삭제'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZWMS_R_0007_01
  as select from zwms_t_0007_01 as _Item
  association to parent ZWMS_R_0007 as _Header on $projection.Headeruuid = _Header.Headeruuid
{
  key itemuuid      as Itemuuid,
      headeruuid    as Headeruuid,
      deliverydocument as Deliverydocument,
      deliverydocumentitem as Deliverydocumentitem,
      actualdeliveryquantity as Actualdeliveryquantity,
      if_flag               as IF_FLAG,
      if_code               as IF_CODE,
      if_msg                as IF_MSG,
      _Header
}
