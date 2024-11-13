@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] DefectCodeText 조회'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZWMS_R_0012_01 as select from I_DefectCodeText

{
    key DefectCodeGroup,
    key DefectCode,
        DefectCodeText
}
where Language = '3'
