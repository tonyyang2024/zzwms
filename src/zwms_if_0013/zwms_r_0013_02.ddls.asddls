@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 판매예정 재고'
define root view entity ZWMS_R_0013_02   as select from I_DeliveryDocument     as _Doh
    inner join   I_DeliveryDocumentItem as _Doi on _Doh.DeliveryDocument = _Doi.DeliveryDocument
{

  key _Doi.Product,
  key _Doi.Plant,
  key _Doi.StorageLocation,

      _Doi.DeliveryQuantityUnit,
      @Semantics.quantity.unitOfMeasure: 'DeliveryQuantityUnit'
      sum( _Doi.OriginalDeliveryQuantity ) as OriginalDeliveryQuantity

}
where
      _Doi.InventorySpecialStockType  =  ''
  and _Doh.OverallGoodsMovementStatus <> 'C'

group by
  _Doi.Product,
  _Doi.Plant,
  _Doi.StorageLocation,
  _Doi.DeliveryQuantityUnit
