@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 납품지시서 확정 처리'
define root view entity ZWMS_R_0002
  as select from zwms_t_0002

{
  key bukrs   as Company,
  key werks   as Plant,
  key donum   as DONum,
  key doline  as DOLine,
      partnum as PartNum,
      qty     as Qty,
      vrkme   as VRKME
}
