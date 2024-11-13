@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 출고유보해제'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZWMS_R_0004
  as select from zwms_t_0004
  composition [0..*] of ZWMS_R_0004_01 as _Item
{
  key headeruuid as Headeruuid,
      bukrs      as Company,
      werks      as Plant,
      vbeln_vl   as DONum,
      zcy_issue  as CYStockTransfer,
      _Item
}
