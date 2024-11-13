@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 사유리스트 조회'
define root view entity ZWMS_R_0021 as select from I_DefectCodeText
 association [1..1] to I_CompanyCode  as _Company on _Company.CompanyCode = '1000'
{
    key _Company.CompanyCode as Company,
    key concat( I_DefectCodeText.DefectCodeGroup, I_DefectCodeText.DefectCode ) as DMRCode,
    I_DefectCodeText.DefectCodeText as DMRName
    
}where I_DefectCodeText.Language = '3'
