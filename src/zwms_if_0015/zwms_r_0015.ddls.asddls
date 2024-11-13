@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 공급업체별 품번 조회'
define root view entity ZWMS_R_0015
  as select from I_CustomerMaterial_2
    join         I_Supplier on I_CustomerMaterial_2.Customer = I_Supplier.Supplier
  association [1..1] to I_CompanyCode as _Company on _Company.CompanyCode = '1000'
{

  key _Company.CompanyCode                    as Company,
  key I_CustomerMaterial_2.Product            as PartNum,
      I_CustomerMaterial_2.Customer           as VendorID,
      I_Supplier.SupplierName                 as VendorName,
      I_CustomerMaterial_2.MaterialByCustomer as VendorPartNum,
      cast( floor( I_CustomerMaterial_2.LastChangeDateTime ) as abap.char(20) ) as LastChangeDateTime
      
}
