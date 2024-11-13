@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 출고확정 처리'
define root view entity ZWMS_R_0005
  as select from zwms_t_0005

{
  key vbeln_d   as VBELN_D,
      wadat_ist as WADAT_IST,
      cancle    as CANCLE
}
