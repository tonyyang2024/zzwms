@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 거래처 조회'
define root view entity ZWMS_R_0018
  as select from ZURM_R_0002
    join         I_Customer as _Customer on _Customer.Customer = ZURM_R_0002.CustNum
{
  key ZURM_R_0002.Company             as Company,
  key ZURM_R_0002.CustNum             as CustID,
      ZURM_R_0002.BusinessPartnerName as CustName,
      ZURM_R_0002.StreetName          as Address1,
      _Customer.Country               as Address2,     //9/23: 삭제요청
      ZURM_R_0002.TaxNumber2          as ResaleID,
      cast( ZURM_R_0002.LastChangeDateTime as abap.char(20) )  as LastChangeDateTime
}
// 10/30 : BU_GROUP 조건 추가
where ZURM_R_0002.BusinessPartnerGrouping = '1000' or    
      ZURM_R_0002.BusinessPartnerGrouping = '1100' or
      ZURM_R_0002.BusinessPartnerGrouping = '2000' or
      ZURM_R_0002.BusinessPartnerGrouping = '2200' 
