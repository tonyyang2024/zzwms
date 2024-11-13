@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 입고지시서 조회'
define root view entity ZWMS_R_0006
  as select from ZWMS_R_0006_03
{
  key CompanyCode,
  key Plant,
  key VendorID,
  key PackSlip,
  key Packline,
      CustID,
      PostingDate,
      @Semantics.quantity.unitOfMeasure: 'IUM'
      QTY,
      IUM,
      PONum,
      POLine,
      PORelNum,
      VendorQty,
      PUM,
      PartNum,
      PartDescription,
      FromWhse,
      ToWhse,
      Currency,
      CompanyCodeCurrency,
      case when get_numeric_value( DocUnitCost ) = 0 then 0 else 
      get_numeric_value( UnitCost ) / get_numeric_value( DocUnitCost ) end as ExchRate,
      VendorCost,
      DocUnitCost,
      UnitCost,
      Reference
}
