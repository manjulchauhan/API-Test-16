report 50121 "DIR WS REST Floatrate"
{
    Caption = 'WS REST Floatrate';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    var
        httpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Url: Text;
        JsonText: Text;
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
        Error('Result %1', JsonText);
    end;
}