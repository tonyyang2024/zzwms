@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 공급업체 조회'
define root view entity ZWMS_R_0016
  as select from I_Supplier
  association [1..1] to I_BusinessPartner as _BP      on I_Supplier.Supplier = _BP.BusinessPartner
  association [1..1] to I_CompanyCode     as _Company on _Company.CompanyCode = '1000'
{
  key _Company.CompanyCode        as Company,
  key I_Supplier.Supplier         as VendorID,
      I_Supplier.SupplierName     as VendorName,
      I_Supplier.BPAddrCityName   as Address1,
      I_Supplier.BPAddrStreetName as Address2,

      case
      when concat(_BP.LastChangeDate,_BP.LastChangeTime) = '00000000000000' then cast ( concat(_BP.CreationDate,_BP.CreationTime) as abap.char(20) )
      else cast ( concat(_BP.LastChangeDate,_BP.LastChangeTime) as abap.char(20) )
      end                         as LastChangeDateTime

}
