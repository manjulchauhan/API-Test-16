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
        Error('Result %1', XMLText);
    end;
}