report 50120 "DIR WS SOAP Floatrate"
{
    Caption = 'WS SOAP Floatrate';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    var
        httpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Url: Text;
        XMLText: Text;
        XmlReadOptions: XmlReadOptions;
        xmlDoc: XmlDocument;
        XmlNodeList: XmlNodeList;
        XmlNode: XmlNode;
        ExchRateAmount: Decimal;
    begin
        Url := 'http://www.floatrates.com/daily/dkk.xml';
        httpClient.Get(Url, HttpResponse);
        with HttpResponse do begin
            if not IsSuccessStatusCode then
                Error('Not working - the error was:\\Status Code:%1\\Error %2',
                    HttpStatusCode,
                    ReasonPhrase);
            Content.ReadAs(XMLText);
        end;
        XmlReadOptions.PreserveWhitespace := true;
        XmlDocument.ReadFrom(XMLText, XmlReadOptions, xmlDoc);
        if xmlDoc.SelectNodes('//channel/item', XmlNodeList) then begin
            foreach XmlNode in XmlNodelist do begin
                if XmlNode.SelectSingleNode('pubDate', XmlNode) then
                    CurrencyRate."Starting Date" := ConvertDate(XmlNode.AsXmlElement.InnerText);

                if XmlNode.SelectSingleNode('../targetCurrency', XmlNode) then
                    CurrencyRate."Currency Code" := XmlNode.AsXmlElement.InnerText;

                if XmlNode.SelectSingleNode('../inverseRate', XmlNode) then
                    Evaluate(ExchRateAmount, XmlNode.AsXmlElement.InnerText);
                CurrencyRate."Relational Exch. Rate Amount" := ExchRateAmount * 100;

                CurrencyRate."Exchange Rate Amount" := 100;
                if CurrencyRate.Insert() then;
                CurrencyRate.Init();
            end;
            if page.runmodal(0, CurrencyRate) = action::Cancel then;
        end;
    end;

    var
        CurrencyRate: Record "Currency Exchange Rate" temporary;

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
}