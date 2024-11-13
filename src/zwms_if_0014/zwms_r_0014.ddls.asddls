@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 품목 조회'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZWMS_R_0014
  as select from    I_Product
    left outer join I_ProductDescription on I_ProductDescription.Product = I_Product.Product
    left outer join I_CompanyCode        on I_CompanyCode.CompanyCode = '1000'
{
  key I_CompanyCode.CompanyCode                                                              as CompanyCode,
  key I_Product.Product                                                                      as ProductSpecId,
      //        concat(I_Product.YY1_MAT_HB_PRD, concat('|', concat( I_Product.YY1_MAT_JJ_PRD, concat('|', I_Product.YY1_MAT_CB_PRD)))) as Description,   //09/13 주석
      concat(I_ProductDescription.ProductDescription, concat('|', I_Product.YY1_MAT_CB_PRD)) as Description,
      I_ProductDescription.ProductDescription                                                as ModelNum,
      I_Product.YY1_MAT_JJ_PRD                                                               as Grade,

//      case when I_Product.YY1_MAT_CB_PRD is null then ' '
//      else I_Product.YY1_MAT_CB_PRD end                                                      as ChipBreaker,

      I_Product.BaseUnit                                                                     as IUM,

      case
      when concat(I_Product.LastChangeDate, I_Product.LastChangeTime) = '00000000000000' then cast ( concat(I_Product.CreationDate, I_Product.CreationTime) as abap.char(20) )
      else cast( concat(I_Product.LastChangeDate, I_Product.LastChangeTime) as abap.char(20) )
      end                                                                                    as LastChangeDateTime


}
where
  I_ProductDescription.Language = '3'
