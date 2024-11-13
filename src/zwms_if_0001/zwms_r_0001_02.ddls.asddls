@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 납품지시조회 확정포함'
define root view entity ZWMS_R_0001_02
  as select from    I_DeliveryDocument           as _DOHeader
    inner join      I_DeliveryDocumentItem       as _DOItem      on _DOHeader.DeliveryDocument = _DOItem.DeliveryDocument
    
    left outer join      I_SalesOrder            as _SOHeader    on _SOHeader.SalesOrder = _DOItem.ReferenceSDDocument
    
    left outer join      I_SalesOrderPartner     as _Partner     on  _SOHeader.SalesOrder = _Partner.SalesOrder
                                                                 and _Partner.PartnerFunction = 'WE'
    
    left outer join      I_SalesOrderItem        as _SOItem      on  _SOItem.SalesOrder     = _DOItem.ReferenceSDDocument
                                                                 and _SOItem.SalesOrderItem = _DOItem.ReferenceSDDocumentItem
    
    left outer join      I_SalesDocument         as _SDHeader    on _SDHeader.SalesDocument = _SOHeader.SalesOrder
    
    left outer join      I_SalesDocumentItem     as _SDItem      on  _SDItem.SalesDocument     = _SOItem.SalesOrder
                                                                 and _SDItem.SalesDocumentItem = _SOItem.SalesOrderItem
                                                                 and _SDHeader.SalesDocument   = _SDItem.SalesDocument

    left outer join I_SalesDocItemPricingElement as _TaxCode     on  _TaxCode.SalesDocument     = _SOItem.SalesOrder
                                                                 and _TaxCode.SalesDocumentItem = _SOItem.SalesOrderItem
                                                                 and _TaxCode.ConditionType     = 'TTX1'
    
    left outer join I_TaxCodeText                as _TaxCodeText on  _TaxCodeText.TaxCode  = _TaxCode.TaxCode
                                                                 and _TaxCodeText.Language = '3'
    
    inner join      I_Product                    as _Product     on _DOItem.Product = _Product.Product
    
    left outer join I_ProductText                as _ProductText on  _ProductText.Product  = _Product.Product
                                                                 and _ProductText.Language = '3'
    
    left outer join I_BusinessPartner            as _SoldToParty on _SoldToParty.BusinessPartner = _SOHeader.SoldToParty
    
    left outer join I_BusinessPartner            as _ShipToParty on _ShipToParty.BusinessPartner = _DOHeader.ShipToParty
    
    left outer join I_ShippingTypeText           as _shipText    on _shipText.ShippingType = _DOHeader.ShippingType 
                                                                 and _shipText.Language = '3'
    
    join            I_Customer                   as _Customer    on _Customer.Customer = _ShipToParty.BusinessPartner
{
  key _DOHeader.DeliveryDocument                                                                                                       as DONum,
  key _DOItem.DeliveryDocumentItem                                                                                                     as DOLine,
      'Y'                                                                                                                              as ShipHold,
      _SOHeader.SoldToParty                                                                                                            as CustID,
      _SoldToParty.BusinessPartnerName                                                                                                 as CustName,
      _Product.Product                                                                                                                 as PartNum,
      _ProductText.ProductName                                                                                                         as PartHB,
      _Product.YY1_MAT_JJ_PRD                                                                                                          as PartJJ,
      _Product.YY1_MAT_CB_PRD                                                                                                          as PartCB,
      _Product.BaseUnit                                                                                                                as IUM,


      @Semantics.quantity.unitOfMeasure: 'IUM'
      _DOItem.OriginalDeliveryQuantity                                                                                                 as OrderQty,
      
      @Semantics.quantity.unitOfMeasure: 'IUM'
      _DOItem.OriginalDeliveryQuantity                                                                                                 as ReqQty,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      _SOItem.NetPriceAmount,
      _SOItem.TransactionCurrency                                                                                                      as CurrencyCode,
      concat( concat(_SOHeader.SalesOrder,'-'), _SOItem.SalesOrderItem )                                                               as OrderNum,
      _SOHeader.SalesOrder                                                                                                             as SONum,
      _SOItem.SalesOrderItem                                                                                                           as SOLine,
      _ShipToParty.BusinessPartnerName                                                                                                 as ShipToName,
      // 도시 + 도로주소 + 번지 + 우편번호
      concat_with_space(_Customer._AddressDefaultRepresentation.CityName,
      concat_with_space(_Customer._AddressDefaultRepresentation.StreetName, _Customer._AddressDefaultRepresentation.HouseNumber, 1),1) as ShipToAddress,

      _TaxCode.TaxCode                                                                                                                 as TaxCode,
      _TaxCodeText.TaxCodeName                                                                                                         as TaxDesc,
      _TaxCode.ConditionRateValue                                                                                                      as TaxRate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      _SOItem.TaxAmount                                                                                                                as TaxAmount,
      _SOHeader.RequestedDeliveryDate                                                                                                  as ReqDate,
      _SOHeader.CreationDate                                                                                                           as OrderDate,
      _SOHeader.PurchaseOrderByCustomer                                                                                                as PONum,
      _DOItem.StorageLocation                                                                                                          as DefaultWhse,
      _SOItem.ShippingType                                                                                                             as ShipViaCode,
      _DOHeader.DeliveryDocumentType                                                                                                   as Type,
      _SDHeader.CreatedByUser                                                                                                          as EntryPerson,
      _Partner.Customer                                                                                                                as Shipto,
      _shipText.ShippingTypeName                                                                                                       as ShipViaDesc,
      case when _SDItem.DeliveryPriority is null then '' else 'Y' end                                                                  as LPRIO
}
where
  (
       _DOHeader.DeliveryDocumentType =  'LF'
    or _DOHeader.DeliveryDocumentType =  'LR'
  )
  and  _DOItem.GoodsMovementStatus    <> 'C'
  and(
       _DOItem.StorageLocation        =  '4011'
    or _DOItem.StorageLocation        =  '4014'
    or _DOItem.StorageLocation        =  '4012'
    or _DOItem.StorageLocation        =  '4015'
  ) 
