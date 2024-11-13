@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 박스정보 수신'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZWMS_R_0009
  as select from zwms_t_0009
  composition [0..*] of ZWMS_R_0009_01 as _Item
{
  key headeruuid as Headeruuid,
      bukrs      as Company,
      werks      as Plant,
      vbeln_d    as PickNum,
      lfimg      as LotQty,
      zboxweight as BoxWeight,
      erdat      as EntryDate,
      ernam      as EntryUsr,
      _Item 
}
