@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 입고문서 헤더아이템'
define root view entity ZWMS_R_0006_02
  as select from    I_MaterialDocumentHeader_2 as Mat_Header
    join            I_MaterialDocumentItem_2   as Mat_Item on  Mat_Header.MaterialDocumentYear = Mat_Item.MaterialDocumentYear
                                                           and Mat_Header.MaterialDocument     = Mat_Item.MaterialDocument
    left outer join I_Supplier                             on Mat_Item.Supplier = I_Supplier.Supplier
  association [1..1] to I_CompanyCode as _Company on _Company.CompanyCode = '1000'
{
  key _Company.CompanyCode,
  key Mat_Item.Plant,
  key Mat_Header.MaterialDocumentYear,
  key Mat_Item.MaterialDocument,
  key concat(Mat_Header.MaterialDocumentYear, Mat_Item.MaterialDocument) as PackSlip,
  key Mat_Item.MaterialDocumentItem,
  key Mat_Item.Supplier,
      Mat_Header.PostingDate,
      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      Mat_Item.QuantityInBaseUnit,
      Mat_Item.MaterialBaseUnit,                                                      --IUM
      Mat_Item.PurchaseOrder,                                                         --PONum
      Mat_Item.PurchaseOrderItem,                                                     --POLine
      '1'                                                                as PORelNum, --PORelNum
      Mat_Item.Material,                                                              --PartNum
      Mat_Item.StorageLocation,                                                       --ToWhse
      Mat_Item.IssuingOrReceivingStorageLoc,                                          --FromWhse
      Mat_Item.MaterialDocumentItemText                                               --Reference
}
where
  (
       Mat_Item.StorageLocation          = '4010'
    or Mat_Item.StorageLocation          = '4013'
  )
  and  Mat_Item.DebitCreditCode          = 'S'
  and  Mat_Item.ReversedMaterialDocument = ''
  and  Mat_Item.GoodsMovementIsCancelled = ''
