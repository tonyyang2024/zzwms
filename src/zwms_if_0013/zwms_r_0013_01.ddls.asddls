@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 현재고 조회'

define root view entity ZWMS_R_0013_01
  as select from I_StockQuantityCurrentValue_2( P_DisplayCurrency : 'KRW' ) as _Hstk

{

  key _Hstk.Product,
  key _Hstk.Plant,
  key _Hstk.StorageLocation,

      _Hstk.MaterialBaseUnit,
      _Hstk.Currency,

      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      sum( _Hstk.MatlWrhsStkQtyInMatlBaseUnit ) as MatlWrhsStkQtyInMatlBaseUnit,

      @Semantics.amount.currencyCode: 'Currency'
      sum( _Hstk.StockValueInCCCrcy )           as StockValueInCCCrcy
}
where
      _Hstk.InventorySpecialStockType = ''
  and _Hstk.InventoryStockType        = '01'
  and _Hstk.ValuationAreaType         = '1'

group by
  _Hstk.Product,
  _Hstk.Plant,
  _Hstk.StorageLocation,
  _Hstk.MaterialBaseUnit,
  _Hstk.Currency
