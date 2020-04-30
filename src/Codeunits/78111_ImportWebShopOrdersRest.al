codeunit 78111 "Import Orders Rest"
{
    trigger OnRun();
    var
        RestKey: Text;
        EndPointURL: Text;
        Filters: Text;
        StartDate: Text;
        StartingDate: Date;
        EndDate: Text;
        LoopDate: record Date;
        WebShopSetup: Record "Web Shop Setup";
        DayTxt: Text[2];
        MonthTxt: Text[2];
    begin
        WebShopSetup.get();
        if WebShopSetup."Last WS Retrieval Date" = 0D then
            WebShopSetup."Last WS Retrieval Date" := WorkDate();

        StartingDate := WebShopSetup."Last WS Retrieval Date";

        LoopDate.setfilter("Period Start", '%1..%2', StartingDate, WorkDate());
        if Loopdate.FindSet() then
            repeat
                DayTxt := format(Date2DMY(LoopDate."Period Start", 1));
                if (strlen(DayTxt) = 1) then
                    DayTxt := '0' + DayTxt;
                MonthTxt := format(Date2DMY(LoopDate."Period Start", 2));
                if (strlen(MonthTxt) = 1) then
                    MonthTxt := '0' + MonthTxt;

                StartDate := format(Date2DMY(LoopDate."Period Start", 3)) + '-' + MonthTxt + '-' + DayTxt;
                EndDate := StartDate;


                Filters := '/GetByDateInterval?start=' + startDate + '&end=' + endDate;

                EndPointURL := 'http://b-a.dk/admin/webapi/Endpoints/v1_0/OrderService/' + RestKey + '/' + Filters;
                HttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');
                if not HttpClient.get(EndPointURL, ResponseMessage) then
                    Error('The call to the web service failed.');
                if not ResponseMessage.IsSuccessStatusCode then
                    error('The web service returned an error message:\\' + 'Status code: %1\' + 'Description: %2', ResponseMessage.HttpStatusCode, ResponseMessage.ReasonPhrase);
                ResponseMessage.Content.ReadAs(JsonText);

                if not JsonArray.ReadFrom(JsonText) then
                    Error('Invalid response, expected an JSON array as root object');
                foreach jsonToken in JsonArray do begin
                    JsonObject := JsonToken.AsObject;
                    InsertOrder(LoopDate."Period Start");
                end;
                if LoopDate."Period Start" > WebShopSetup."Last WS Retrieval Date" then
                    WebShopSetup."Last WS Retrieval Date" := LoopDate."Period Start";
            until LoopDate.Next() = 0;
        WebShopSetup.Modify();



        if GuiAllowed() then
            MESSAGE('%1 Orders Created', OrderCounter);
    end;

    Local procedure InsertOrder(inPostingDate: Date);
    var
        TokenName: Text[50];
        LowerCurrCode: Text[10];
        OrderDateTxt: Text[30];
        PaymentFeeTxt: Text[20];
        PaymentRegisteredTxt: Text[20];
        ShippingFeeTxt: Text[20];
        TotalAmountTxt: Text[20];
        QuantityTxt: Text[20];
        UnitPriceTxt: Text[20];
        VatPctTxt: Text[20];
        VatPct: Decimal;
        FeeTxt: Text[20];
        IncompleteTxt: Text[20];
        GenLedgSetup: Record "General Ledger Setup";
        AppName: Record "BAC Extension 2";
        AppOrder: Boolean;

    begin
        // Fill the Sales order header from the JsonArray
        WebOrder.Init();

        TokenName := 'id';
        WebOrder."Order No." := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'incomplete';
        IncompleteTxt := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        if WebOrder.get(WebOrder."Order No.") or (IncompleteTxt = 'true') then
            exit;

        TokenName := 'customerInfo.attention';
        WebOrder."Cust Name" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.name';
        WebOrder."Cust  Company" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.address';
        WebOrder."Cust Address" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.address2';
        WebOrder."Cust Address 2" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.city';
        WebOrder."Cust City" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.country';
        WebOrder."Cust Country" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.email';
        WebOrder."Cust E-Mail" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.ean';
        WebOrder."Cust EAN" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.phone';
        WebOrder."Cust Phone" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.state';
        WebOrder."Cust State" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'vatRegNumber';
        WebOrder."Cust VAT" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'customerInfo.zipCode';
        WebOrder."Cust Zip Code" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        TokenName := 'currencyCode';
        WebOrder."Currency Code" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        GenLedgSetup.get();
        if (WebOrder."Currency Code" = GenLedgSetup."LCY Code") then
            WebOrder."Currency Code" := '';

        if StrPos(WebOrder."Currency Code", 'EUR') > 0 then
            WebOrder."Currency Code" := 'EUR';

        TokenName := 'createdDate';
        WebOrder."Order Date" := inPostingDate;

        GetCustomer();

        WebOrder."Customer No" := Customer."No.";

        WebOrder.Insert();

        // Loop the lines
        WebOrderLine.Init();
        NextLineNo := 10000;

        JsonTokenLine := SelectJsonToken(JsonObject, 'orderLines');
        JsonLineText := Format(JsonTokenLine);

        if not JsonArrayLine.ReadFrom(JsonLineText) then
            Error('Invalid response, expected an JSON array as root object');

        foreach jsonTokenLine in JsonArrayLine do begin
            JsonObjectLine := JsonTokenLine.AsObject();

            WebOrderLine."Order No." := WebOrder."Order No.";
            WebOrderLine."Line No." := NextLineNo;
            NextLineNo += 10000;

            TokenName := 'productId';
            WebOrderLine."Item No." := StripJsonToken(format(SelectJsonToken(JsonObjectLine, TokenName)));
            // *** TEMP
            if not AppOrder then
                AppOrder := AppName.get(WebOrderLine."Item No.");
            if AppOrder then begin
                WebOrder."App Order" := AppOrder;
                WebOrder.Modify();
            end;
            // *** TEMP 

            TokenName := 'productName';
            WebOrderLine.Description := copystr(StripJsonToken(format(SelectJsonToken(JsonObjectLine, TokenName))), 1, MaxStrLen(WebOrderLine.Description));

            TokenName := 'quantity';
            QuantityTxt := StripJsonToken(format(SelectJsonToken(JsonObjectLine, TokenName)));
            Evaluate(WebOrderLine.Quantity, QuantityTxt);

            TokenName := 'vatPct';
            VatPctTxt := StripJsonToken(format(SelectJsonToken(JsonObjectLine, TokenName)));
            VatPctTxt := DelChr(VatPctTxt, '=', ',');
            VatPctTxt := ConvertStr(VatPctTxt, '.', ',');
            Evaluate(VatPct, VatPctTxt);
            // >> PBA 23-02-2020
            WebOrderLine."VAT Pct" := VatPct;
            WebOrderLine."VAT Amount" := WebOrderLine."Unit Price" * (VatPct / 100);
            if VatPct <> 0 then begin
                WebOrder."Prices Incl. VAT" := true;
                Customer."Prices Including VAT" := true;
                Customer.Modify();
            end;
            // << PBA 23-02-2020
            WebOrderLine."Unit Price" := 0;
            TokenName := 'unitPrice';
            UnitPriceTxt := StripJsonToken(format(SelectJsonToken(JsonObjectLine, TokenName)));
            UnitPriceTxt := DelChr(UnitPriceTxt, '=', ',');
            UnitPriceTxt := ConvertStr(UnitPriceTxt, '.', ',');
            Evaluate(WebOrderLine."Unit Price", UnitPriceTxt);
            WebOrderLine."Unit Price" := WebOrderLine."Unit Price" + (WebOrderLine."Unit Price" * (VatPct / 100));
            WebOrderLine.Insert();

        end;
        if (WebOrderLine.Description = '') and (WebOrderLine."Item No." = '') then
            exit;
        // Create Payment Info
        TokenName := 'paymentInfo.fee';
        PaymentFeeTxt := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));
        PaymentFeeTxt := DelChr(PaymentFeeTxt, '=', ',');
        PaymentFeeTxt := ConvertStr(PaymentFeeTxt, '.', ',');
        Evaluate(WebOrder."Payment Fee", PaymentFeeTxt);

        TokenName := 'paymentInfo.name';
        WebOrder."Payment Method" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        // Create Shipping Info
        TokenName := 'shippingInfo.fee';
        ShippingFeeTxt := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));
        ShippingFeeTxt := DelChr(ShippingFeeTxt, '=', ',');
        ShippingFeeTxt := ConvertStr(ShippingFeeTxt, '.', ',');
        Evaluate(WebOrder."Shipping Fee", ShippingFeeTxt);

        TokenName := 'shippingInfo.name';
        WebOrder."Shipping Method" := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));

        // Create Total Price
        TokenName := 'totalPrice';
        TotalAmountTxt := StripJsonToken(format(SelectJsonToken(JsonObject, TokenName)));
        TotalAmountTxt := DelChr(TotalAmountTxt, '=', ',');
        TotalAmountTxt := ConvertStr(TotalAmountTxt, '.', ',');
        Evaluate(WebOrder."Total Amount", TotalAmountTxt);

        WebOrder.Modify();
        if (WebOrder."Total Amount" = 0) and not appOrder then
            exit;

        CreateOrderHeaders.Run(WebOrder);
        OrderCounter += 1;
    end;

    local procedure StripJsonToken(inText: text): Text
    begin
        exit(delchr(inText, '=', '"'));
    end;

    procedure SelectJsonToken(JsonObject: JsonObject; Path: text) JsonToken: JsonToken
    begin
        if not JsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;

    procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    var
        Customer: Record Customer;
        WebOrder: Record "Web Order Header";
        WebOrderLine: Record "Web Order Line";
        CreateOrderHeaders: Codeunit "BAC Create Order Header";
        HttpClient: HttpClient;
        ResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonTokenLine: JsonToken;
        JsonObject: JsonObject;
        JsonObjectLine: JsonObject;
        JsonArray: JsonArray;
        JsonArrayLine: JsonArray;
        JsonText: text;
        JsonLineText: text;

        NextLineNo: Integer;
        OrderCounter: Integer;

    procedure GetCustomer();
    var
        CustomerTemplate: Code[10];
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        ConfigTemplateHeader: Record "Config. Template Header";
        RecRef: RecordRef;
        CustChanged: Boolean;
    begin
        CLEAR(Customer);
        Customer.setrange("E-Mail", WebOrder."Cust E-Mail");
        if Customer.FindFirst() then begin
            if Customer.Address <> WebOrder."Cust Address" then begin
                Customer.Address := WebOrder."Cust Address";
                CustChanged := true;
            end;
            if Customer."Address 2" <> WebOrder."Cust Address 2" then begin
                Customer."Address 2" := WebOrder."Cust Address 2";
                CustChanged := true;
            end;
            if Customer."Post Code" <> WebOrder."Cust Zip Code" then begin
                Customer."Post Code" := WebOrder."Cust Zip Code";
                CustChanged := true;
            end;
            if Customer.City <> WebOrder."Cust City" then begin
                Customer.City := WebOrder."Cust City";
                CustChanged := true;
            end;
            if Customer."Phone No." <> WebOrder."Cust Phone" then begin
                Customer."Phone No." := WebOrder."Cust Phone";
                CustChanged := true;
            end;
            if Customer."VAT Registration No." <> WebOrder."Cust VAT" then begin
                Customer."VAT Registration No." := WebOrder."Cust VAT";
                CustChanged := true;
            end;
            if CustChanged then
                Customer.Modify();
            EXIT;
        end;

        // Create the new Customer - Use Numberseries
        Customer.Init();
        Customer.INSERT(true);

        //Find the Country Code from the Country Name
        Customer."Country/Region Code" := GetCountryCode(WebOrder."Cust Country");

        //Get and Apply the corrrect template
        CustomerTemplate := GetTemplate(Customer."Country/Region Code");
        RecRef.GETTABLE(Customer);
        ConfigTemplateHeader.get(CustomerTemplate);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
        RecRef.SETTABLE(Customer);

        //Fill the Customer Data
        if WebOrder."Cust  Company" <> '' then begin
            Customer.Name := WebOrder."Cust  Company";
            Customer.Contact := WebOrder."Cust Name";
        END ELSE
            Customer.Name := WebOrder."Cust Name";
        Customer.Address := WebOrder."Cust Address";
        Customer."Address 2" := WebOrder."Cust Address 2";
        Customer."Post Code" := WebOrder."Cust Zip Code";
        Customer.City := WebOrder."Cust City";
        Customer."Phone No." := WebOrder."Cust Phone";
        Customer."Fax No." := WebOrder."Cust Fax";
        Customer."E-Mail" := WebOrder."Cust E-Mail";
        Customer."VAT Registration No." := WebOrder."Cust VAT";
        //Customer."EAN No." := WebOrder."Cust EAN";
        Customer."Shipment Method Code" := GetShippingTerm(WebOrder."Shipping Method");
        Customer."Payment Method Code" := GetPaymentMethod(WebOrder."Payment Method");
        Customer."Payment Terms Code" := Customer."Shipment Method Code";
        Customer.Modify();
    end;

    procedure GetTemplate(inCountryCode: Code[10]): Code[10];
    begin
        CASE inCountryCode OF
            'DK':
                EXIT('CUST_DK');

            'AU', 'BE', 'EL', 'LT', 'PT',
            'BG', 'ES', 'LU', 'RO',
            'CZ', 'FR', 'HU', 'SI',
            'HR', 'MT', 'SK', 'DE',
            'IT', 'NL', 'FI', 'EE',
            'CY', 'AT', 'SE', 'IE',
            'LV', 'PL', 'UK':
                begin
                    if WebOrder."Cust VAT" <> '' then
                        EXIT('CUST_EU')
                    else
                        EXIT('CUST_EU2')
                end;
            ELSE
                EXIT('CUST_EXP');
        end;
    end;

    procedure IsNumeric(inText: Text[1]): Boolean;
    var
        iCounter: Integer;
    begin
        //IF inText IN ['0','1','2','3','4','5','6','7','8','9',',','.','-'] then 
        if inText IN ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '-'] then
            EXIT(true);

        EXIT(false)
    end;

    procedure GetCountryCode(inCountry: Text[50]): Code[10];
    var
        Country: Record "Country/Region";
        SearchString: Text[50];
    begin
        Country.Reset();
        SearchString := STRSUBSTNO('@%1', inCountry);
        Country.setfilter(Name, SearchString);
        if Country.FindFirst() then
            EXIT(Country.Code);
    end;

    procedure GetPaymentMethod(inPaymentMethod: Text[50]): Code[10];
    var
        PaymentMethod: Record "Payment Method";
        SearchString: Text[50];
    begin
        PaymentMethod.Reset();
        SearchString := STRSUBSTNO('@%1', inPaymentMethod);
        PaymentMethod.setfilter(Description, SearchString);
        if PaymentMethod.FindFirst() then
            EXIT(PaymentMethod.Code);
    end;

    procedure GetShippingTerm(inShipmentMethod: Text[50]): Code[10];
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.setfilter(Description, '@%1', inShipmentMethod);
        if ShipmentMethod.FindFirst() then
            EXIT(ShipmentMethod.Code);
    end;
}