report 50121 "DIR WS REST Floatrate"
{
    Caption = 'WS REST Floatrate';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    //UseRequestPage = false;

    var
        JsonText: Text;
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        Currency: Record Currency;
        CurrRate: Record "Currency Exchange Rate" temporary;

    trigger OnInitReport()
    var
        httpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Url: Text;

    begin
        Url := 'http://www.floatrates.com/daily/dkk.json';
        httpClient.Get(Url, HttpResponse);
        with HttpResponse do begin
            if not IsSuccessStatusCode then
                Error('Not working - the error was:\\Status Code:%1\\Error %2',
                    HttpStatusCode,
                    ReasonPhrase);
            Content.ReadAs(JsonText);
        end;
        JsonText := '[' + JsonText + ']';
        if not JsonArray.ReadFrom(JsonText) then
            Error('Not a Json object');
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            if Currency.FindSet() then
                repeat
                    InsertCurrencyRate(Currency.Code);
                until Currency.Next() = 0;
            if Page.RunModal(0, CurrRate) = Action::Cancel then;
        end;

    end;

    local procedure InsertCurrencyRate(inCurrCode: code[10])
    var
        TokenName: Text[50];
        LowerCurrCode: Text[50];
        InvExchRate: Decimal;
    begin
        CurrRate.Init();
        LowerCurrCode := LowerCase(inCurrCode);
        if not JsonObject.get(LowerCurrCode, JsonToken) then
            exit;
        TokenName := '$.' + LowerCurrCode + '.code';
        CurrRate."Currency Code" := Format(SelectJsonToken(JsonObject, TokenName));
        CurrRate."Exchange Rate Amount" := 100;
        TokenName := '$.' + LowerCurrCode + '.inverseRate';
        Evaluate(InvExchRate, Format(SelectJsonToken(JsonObject, TokenName)));
        CurrRate."Relational Exch. Rate Amount" := InvExchRate * 100;
        TokenName := '$.' + LowerCurrCode + '.date';
        CurrRate."Starting Date" := ConvertDate(Format(SelectJsonToken(JsonObject, TokenName)));
        if CurrRate.Insert() then;
    end;

    local procedure ConvertDate(inDateTxt: Text[50]): Date;
    var
        DayTxt: Text[10];
        MonthTxt: Text[10];
        YearTxt: Text[10];
        DayNo: Integer;
        MonthNo: Integer;
        YearNo: Integer;
        DateTxt: Text[50];

    begin
        //date":"Thu, 27 Sep 2018 00:00:01
        DateTxt := copystr(inDateTxt, strpos(inDateTxt, ',') + 1);
        DateTxt := DelChr(DateTxt, '<', ' ');
        DayTxt := CopyStr(DateTxt, 1, StrPos(DateTxt, ' '));
        DateTxt := copystr(DateTxt, strpos(DateTxt, ' ') + 1);
        MonthTxt := CopyStr(DateTxt, 1, StrPos(DateTxt, ' '));
        DateTxt := copystr(DateTxt, strpos(DateTxt, ' ') + 1);
        YearTxt := CopyStr(DateTxt, 1, StrPos(DateTxt, ' '));
        evaluate(DayNo, DayTxt);
        evaluate(YearNo, YearTxt);
        case lowercase(delchr(MonthTxt, '=', ' ')) of
            'jan':
                MonthNo := 1;
            'feb':
                MonthNo := 2;
            'mar':
                MonthNo := 3;
            'apr':
                MonthNo := 4;
            'may':
                MonthNo := 5;
            'jun':
                MonthNo := 6;
            'jul':
                MonthNo := 7;
            'aug':
                MonthNo := 8;
            'sep':
                MonthNo := 9;
            'oct':
                MonthNo := 10;
            'nov':
                MonthNo := 11;
            'dec':
                MonthNo := 12;
        end;
        exit(DMY2Date(DayNo, MonthNo, YearNo));
    end;

    procedure SelectJsonToken(JsonObject: JsonObject; Path: text) JsonToken: JsonToken
    begin
        if not JsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;
}