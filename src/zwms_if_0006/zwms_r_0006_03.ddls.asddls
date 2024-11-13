@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 입고문서&PO데이터 조회'
define root view entity ZWMS_R_0006_03
  as select from    ZWMS_R_0006_02                 as _WDOC
    left outer join I_PurchaseOrderItemAPI01       as POItem             on  _WDOC.PurchaseOrder     = POItem.PurchaseOrder
                                                                         and _WDOC.PurchaseOrderItem = POItem.PurchaseOrderItem
    left outer join I_PurOrdAccountAssignmentAPI01 as POAccAssign        on  POAccAssign.PurchaseOrder        = POItem.PurchaseOrder
                                                                         and POAccAssign.PurchaseOrderItem    = POItem.PurchaseOrderItem
                                                                         and POItem.AccountAssignmentCategory = 'H'
    left outer join I_SalesOrder                                         on I_SalesOrder.SalesOrder = POAccAssign.SalesOrder

    join            I_ProductDescription           as ProductDescription on _WDOC.Material = ProductDescription.Product
    left outer join I_PurgInfoRecdOrgPlntDataApi01 as InfoRecord         on POItem.PurchasingInfoRecord = InfoRecord.PurchasingInfoRecord
    left outer join I_PurchaseOrderHistoryAPI01    as POHistory          on  POHistory.PurchaseOrder                 = POItem.PurchaseOrder
                                                                         and POHistory.PurchaseOrderItem             = POItem.PurchaseOrderItem
                                                                         and POHistory.PurchasingHistoryDocumentType = '1'
    left outer join ZWMS_R_0006_01                 as _WComp             on  _WComp.MaterialDocumentYear1 = _WDOC.MaterialDocumentYear
                                                                         and _WComp.MaterialDocument1     = _WDOC.MaterialDocument
                                                                         and _WComp.MaterialDocumentItem1 = _WDOC.MaterialDocumentItem
{
  key _WDOC.CompanyCode,
  key _WDOC.Plant,
  key _WDOC.MaterialDocumentYear,
  key _WDOC.MaterialDocument,
  key _WDOC.PackSlip,
  key _WDOC.MaterialDocumentItem              as Packline,
  key _WDOC.Supplier                          as VendorID,
      I_SalesOrder.SoldToParty                as CustID,
      _WDOC.PostingDate,
      @Semantics.quantity.unitOfMeasure: 'IUM'
      _WDOC.QuantityInBaseUnit,
      _WDOC.MaterialBaseUnit                  as IUM,

      @Semantics.quantity.unitOfMeasure: 'IUM'
      case when _WComp.QuantityInBaseUnit1 is null then _WDOC.QuantityInBaseUnit
           else ( _WDOC.QuantityInBaseUnit - _WComp.QuantityInBaseUnit1 )
           end                                as QTY,

      _WDOC.PurchaseOrder                     as PONum,
      _WDOC.PurchaseOrderItem                 as POLine,
      _WDOC.PORelNum,
      @Semantics.quantity.unitOfMeasure: 'PUM'
      POItem.OrderQuantity                    as VendorQty,
      POItem.PurchaseOrderQuantityUnit        as PUM,
      _WDOC.Material                          as PartNum,
      ProductDescription.ProductDescription   as PartDescription,
      _WDOC.IssuingOrReceivingStorageLoc      as FromWhse,
      _WDOC.StorageLocation                   as ToWhse,
      POItem.DocumentCurrency                 as Currency,

      @Semantics.amount.currencyCode: 'Currency'
      InfoRecord.NetPriceAmount               as VendorCost,
      @Semantics.amount.currencyCode: 'Currency'
      POItem.NetPriceAmount                   as DocUnitCost,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      POHistory.PurOrdAmountInCompanyCodeCrcy as POHisAmount,
      POHistory.CompanyCodeCurrency           as CompanyCodeCurrency,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when POHistory.CompanyCodeCurrency = 'KRW' or POHistory.CompanyCodeCurrency = 'JPY'
           then cast( round ( ( get_numeric_value( POHistory.PurOrdAmountInCompanyCodeCrcy) / get_numeric_value( POItem.OrderQuantity ) / 100 ), 2 ) as abap.curr(13,2) )
           else
           cast( round ( ( get_numeric_value( POHistory.PurOrdAmountInCompanyCodeCrcy) / get_numeric_value( POItem.OrderQuantity ) ), 2 )  as abap.curr(13,2) )
           end                                as UnitCost,

      _WDOC.MaterialDocumentItemText          as Reference

}

where
  ProductDescription.Language = '3'
