@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '[WMS] 재고조회(메인)'
define root view entity ZWMS_R_0013
  as select from    ZWMS_R_0013_01 as _Hstk
    join            I_Product                on _Hstk.Product = I_Product.Product
    left outer join I_ProductDescription     on I_ProductDescription.Product = I_Product.Product

    left outer join ZWMS_R_0013_02 as _Dostk on  _Hstk.Product         = _Dostk.Product
                                             and _Hstk.Plant           = _Dostk.Plant
                                             and _Hstk.StorageLocation = _Dostk.StorageLocation
    join            I_StorageLocation        on _Hstk.StorageLocation = I_StorageLocation.StorageLocation
  association [1..1] to I_CompanyCode as _Company on _Company.CompanyCode = '1000'
{

  key _Company.CompanyCode                    as Company,
  key _Hstk.Plant                             as Plant,
  key I_Product.Product                       as PartNum,
//  key I_Product.YY1_MAT_HB_PRD                as PartHB,  // 09/13주석
  key I_ProductDescription.ProductDescription               as PartHB,  // 09/13수정
      I_Product.YY1_MAT_JJ_PRD                as PartJJ,
      case when I_Product.YY1_MAT_CB_PRD is null then ''
      else I_Product.YY1_MAT_CB_PRD end       as PartCB,
      _Hstk.StorageLocation                   as WhseCode,
      I_StorageLocation.StorageLocationName   as WhseDesc,
      @Semantics.quantity.unitOfMeasure: 'IUM'
      _Hstk.MatlWrhsStkQtyInMatlBaseUnit      as OnhandQty,

      _Hstk.MaterialBaseUnit                  as IUM
}
where
      _Hstk.MatlWrhsStkQtyInMatlBaseUnit <> 0
  and I_ProductDescription.Language      =  '3'
