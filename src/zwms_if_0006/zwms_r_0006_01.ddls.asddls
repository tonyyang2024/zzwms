@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 자재문서아이템 정보'
define root view entity ZWMS_R_0006_01
  as select from I_MaterialDocumentItem_2 as _WComp

{

  key left(_WComp.MaterialDocumentItemText, 4)          as MaterialDocumentYear1,
  key substring(_WComp.MaterialDocumentItemText, 5, 10) as MaterialDocument1,
  key substring(_WComp.MaterialDocumentItemText, 15, 4) as MaterialDocumentItem1,

      _WComp.MaterialBaseUnit,
      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      sum( QuantityInBaseUnit )                         as QuantityInBaseUnit1
}
where
       _WComp.Plant                    = '1000'
  and(
       _WComp.StorageLocation          = '4011'
    or _WComp.StorageLocation          = '4014'
  )
  and  _WComp.DebitCreditCode          = 'S'
  and  _WComp.ReversedMaterialDocument = ''
  and  _WComp.GoodsMovementIsCancelled = ''
group by
  _WComp.MaterialDocumentItemText,
  _WComp.MaterialBaseUnit
