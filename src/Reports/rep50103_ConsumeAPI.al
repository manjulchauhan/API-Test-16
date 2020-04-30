report 50103 "DIR Consume API WS"
{
    Caption = 'Consume API WS';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: text;
        Customer: Record Customer temporary;
        Url: Text;
    begin
        Url := 'http://navtraining:7048/BC140/api/DirectionsEMEA/APIs/v1.0/companies(44da4ef3-d237-45cb-824a-527aa5e69cd9)/WSCustomers';
        HttpClient.UseWindowsAuthentication('Admin', '1<3VScode', 'NavTraining');
        if not HttpClient.Get(Url, HttpResponseMessage) then
            Error('The call to the web service failed.');
        if not HttpResponseMessage.IsSuccessStatusCode then
            error('The web service returned an error message:\\' + 'Status code: %1\' + 'Description: %2', HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
        HttpResponseMessage.Content.ReadAs(JsonText);
        error(JsonText);
        JsonText := '[' + JsonText + ']';
        if not JsonArray.ReadFrom(JsonText) then
            Error('Invalid response, expected an JSON array as root object');
        foreach jsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject;
        end;
    end;
}