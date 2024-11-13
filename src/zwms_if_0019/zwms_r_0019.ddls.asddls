@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: '[WMS] 배송처 조회'
define root view entity ZWMS_R_0019
//  with parameters
//    P_BP : zwms_e_0019
  as select from    I_BusinessPartner as _SoldToParty
    join            I_BusinessPartner as _ShipToParty on _SoldToParty.BusinessPartner = lpad(
      _ShipToParty.SearchTerm2, 10, '0'
    )

    join            I_Customer        as _Customer    on _Customer.Customer = _ShipToParty.BusinessPartner
    left outer join I_CountryText     as _CountryText on _CountryText.Country = _Customer.Country
  association [1..1] to I_CompanyCode  as _Company on _Company.CompanyCode = '1000'
  association [1..1] to ZCRM_R_0006_03 as _Plant   on _Plant.Plant = '1000'

{
  key _Company.CompanyCode,
  key _Plant.Plant,
  key _SoldToParty.BusinessPartner                                as SoldToParty,
      _SoldToParty.BusinessPartnerName                            as SoldToPartyName,
      _ShipToParty.BusinessPartner                                as ShipToPart,
      _ShipToParty.BusinessPartnerName                            as ShipToPartName,
      // 도시 + 도로주소 + 번지 + 우편번호
      concat_with_space(_Customer._AddressDefaultRepresentation.CityName, concat_with_space(_Customer._AddressDefaultRepresentation.StreetName, concat_with_space(_Customer._AddressDefaultRepresentation.HouseNumber,
      _Customer._AddressDefaultRepresentation.PostalCode,1),1),1) as Address,
      _Customer.Country,
//      _CountryText.CountryName, //사용여부에 따라 주석처리할것   09/23: 주석처리요청

      case
      when concat(_ShipToParty.LastChangeDate,_ShipToParty.LastChangeTime) = '00000000000000' then cast ( concat(_ShipToParty.CreationDate,_ShipToParty.CreationTime) as abap.char(20) )
      else cast ( concat(_ShipToParty.LastChangeDate,_ShipToParty.LastChangeTime) as abap.char(20) )
      end                                                         as LastChangeDateTime

}
where
       _CountryText.Language                = '3'
  and(
       _SoldToParty.BusinessPartnerGrouping = '1000'
    or _SoldToParty.BusinessPartnerGrouping = '1100'    -- 10/30: 조건 추가요청 
    or _SoldToParty.BusinessPartnerGrouping = '2000'
    or _SoldToParty.BusinessPartnerGrouping = '2100'
    or _SoldToParty.BusinessPartnerGrouping = '2200'
  )
//  and  _ShipToParty.SearchTerm2             = $parameters.P_BP

union all

select from       I_BusinessPartner as _SoldToParty
  join            I_Customer        as _Customer    on _Customer.Customer = _SoldToParty.BusinessPartner
  left outer join I_CountryText     as _CountryText on _CountryText.Country = _Customer.Country
association [1..1] to I_CompanyCode  as _Company on _Company.CompanyCode = '1000'
association [1..1] to ZCRM_R_0006_03 as _Plant   on _Plant.Plant = '1000'

{
  key _Company.CompanyCode,
  key _Plant.Plant,
  key _SoldToParty.BusinessPartner                                as SoldToParty,
      _SoldToParty.BusinessPartnerName                            as SoldToPartyName,
      _SoldToParty.BusinessPartner                                as ShipToPart,
      _SoldToParty.BusinessPartnerName                            as ShipToPartName,
      // 도시 + 도로주소 + 번지 + 우편번호
      concat_with_space(_Customer._AddressDefaultRepresentation.CityName, concat_with_space(_Customer._AddressDefaultRepresentation.StreetName, concat_with_space(_Customer._AddressDefaultRepresentation.HouseNumber,
      _Customer._AddressDefaultRepresentation.PostalCode,1),1),1) as Address,
      _Customer.Country,
//      _CountryText.CountryName, //사용여부에 따라 주석처리할것 09/23: 주석처리요청
      case
      when concat(_SoldToParty.LastChangeDate,_SoldToParty.LastChangeTime) = '00000000000000' then cast ( concat(_SoldToParty.CreationDate,_SoldToParty.CreationTime) as abap.char(20) )
      else cast ( concat(_SoldToParty.LastChangeDate,_SoldToParty.LastChangeTime) as abap.char(20) )
      end                                                         as LastChangeDateTime
}
where
       _CountryText.Language                = '3'
  and(
       _SoldToParty.BusinessPartnerGrouping = '1000'
    or _SoldToParty.BusinessPartnerGrouping = '1100'    -- 10/30: 조건 추가요청 
    or _SoldToParty.BusinessPartnerGrouping = '2000'
    or _SoldToParty.BusinessPartnerGrouping = '2100'
    or _SoldToParty.BusinessPartnerGrouping = '2200'
  )
//  and  _SoldToParty.BusinessPartner         = lpad( $parameters.P_BP, 10, '0' )
