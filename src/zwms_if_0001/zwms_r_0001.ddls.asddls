@EndUserText.label: '[WMS] 납품지시 조회'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_WMS_R_0001_GET'
define custom entity ZWMS_R_0001

{
      @UI.lineItem  : [{label:'ShipHold' }]
  key ShipHold      : abap.char(1);
      @UI.lineItem  : [{label:'Comment' }]
  key CommentText   : abap.char(1000);
      @UI.lineItem  : [{label:'DO 번호' }]
  key DONum         : abap.char(10);
      @UI.lineItem  : [{label:'DO Item번호' }]
  key DOLine        : abap.char(5);
      @UI.lineItem  : [{label:'판매처ID' }]
      CustID        : abap.char(10);
      @UI.lineItem  : [{label:'판매처명' }]
      CustName      : abap.char(50);
      @UI.lineItem  : [{label:'자재코드' }]
      PartNum       : abap.char(40);
      @UI.lineItem  : [{label:'형번' }]
      PartHB        : abap.char(40);
      @UI.lineItem  : [{label:'재종' }]
      PartJJ        : abap.char(50);
      @UI.lineItem  : [{label:'CB' }]
      PartCB        : abap.char(50);
      @UI.lineItem  : [{label:'수량단위' }]
      IUM           : abap.unit(3);

      @UI.lineItem  : [{label:'판매오더 수량' }]
      @Semantics.quantity.unitOfMeasure: 'IUM'
      OrderQty      : abap.dec(20,3);

      @UI.lineItem  : [{label:'판매오더 - DO수량' }]
      @Semantics.quantity.unitOfMeasure: 'IUM'
      UnShippedQty  : abap.dec(20,3);

      @UI.lineItem  : [{label:'DO수량' }]
      @Semantics.quantity.unitOfMeasure: 'IUM'
      ReqQty        : abap.dec(20,3);

      @UI.lineItem  : [{label:'판매단가(외화)' }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      DocUnitPrice  : abap.dec(20,2);

      @UI.lineItem  : [{label:'판매단가' }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      UnitPrice     : abap.dec(20,2);

      @UI.lineItem  : [{label:'통화키' }]
      CurrencyCode  : abap.cuky(5);

      @UI.lineItem  : [{label:'판매오더번호-라인번호' }]
      OrderNum      : abap.char(18);
      @UI.lineItem  : [{label:'납품처내역' }]
      ShipToName    : abap.char(50);
      @UI.lineItem  : [{label:'납품주소' }]
      ShipToAddress : abap.char(100);
      
      @UI.lineItem  : [{label:'단가(KRW) x 출하지시수량' }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Amount        : abap.dec(20,2);

      @UI.lineItem  : [{label:'TaxCode' }]
      TaxCode       : abap.char(2);
      @UI.lineItem  : [{label:'TaxDesc' }]
      TaxDesc       : abap.char(50);
      @UI.lineItem  : [{label:'TaxRate' }]
      TaxRate       : abap.dec(20,3);
      @UI.lineItem  : [{label:'세액' }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TaxAmount     : abap.dec(20,2);
      @UI.lineItem  : [{label:'납품요청일' }]
      ReqDate       : abap.char(10);
      @UI.lineItem  : [{label:'판매오더 생성일' }]
      OrderDate     : abap.char(10);
      @UI.lineItem  : [{label:'판매오더의 고객PO참조필드' }]
      PONum         : abap.char(10);
      @UI.lineItem  : [{label:'출하창고' }]
      DefaultWhse   : abap.char(5);
      @UI.lineItem  : [{label:'출하유형' }]
      ShipViaCode   : abap.char(2);
      @UI.lineItem  : [{label:'오더유형' }]
      Type          : abap.char(4);
      @UI.lineItem  : [{label:'생성자(출하지시자)' }]
      EntryPerson : abap.char(12);
      @UI.lineItem  : [{label:'배송처BP코드' }]
      Shipto      : abap.char(10);
      @UI.lineItem  : [{label:'출하방법내역' }]
      ShipViaDesc : abap.char(20);
      @UI.lineItem  : [{label:'긴급여부' }]
      LPRIO : abap.char(4);

}
