report 50102 "DIR Consume OData SB WS"
{
    Caption = 'Consume OData SB WS';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpRequestMessage: HttpRequestMessage;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: text;
        Customer: Record Customer temporary;
        Url: Text;
        UserName: Text;
        Password: Text;
        AuthTxt: Text;
        TempBlob: Record TempBlob;

    begin
        Url := 'https://api.businesscentral.dynamics.com/v1.0/Tenant/Sandbox/ODataV4/Company(''CRONUS%20Danmark%20A%2FS'')/Customers';

        UserName := 'user';
        Password := 'Web service key';
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method('GET');
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        
        HttpHeaders.Add('Content-Type', 'application/xml;charset=utf-8');
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('SOAPAction', 'urn:microsoft-dynamics-schemas/page/WSCustomerSOAP');
        // Basic authentication 
        if UserName <> '' then begin
            AuthTxt := strsubstno('%1:%2', UserName, Password);
            TempBlob.WriteAsText(AuthTxt, TextEncoding::Windows);
            HttpHeaders.Add('Authorization', StrSubstNo('Basic %1', TempBlob.ToBase64String()));
        end;
        HttpClient.send(HttpRequestMessage, HttpResponseMessage);
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