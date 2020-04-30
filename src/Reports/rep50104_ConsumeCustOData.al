report 50104 "DIR WS Rest Cust OData"
{
    Caption = 'WS Rest Cust OData';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;


    trigger OnInitReport()
    var
        httpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        HttpRequest: HttpRequestMessage;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        Url: Text;
        UserID: Text;
        PasswordTxt: Text;
        AuthTxt: Text;
        XMLText: Text;
        TempBlob: Record TempBlob;

    begin
        UserID := 'User';
        PasswordTxt := 'Password!23';
        Url := 'http://navtraining:7047/BC160_Webservice/WS/Page/WSCustomerSOAP';
        XMLText := '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                 '  <Body>' +
                 '   <ReadMultiple xmlns="urn:microsoft-dynamics-schemas/page/wscustomersoap">' +
                 '    <filter>' +
                 '       <Field>No</Field>' +
                 '        <Criteria />' +
                 '    </filter>' +
                 '    <bookmarkKey />' +
                 '    <setSize>0</setSize>' +
                 '   </ReadMultiple>' +
                 '  </Body>' +
                 '</Envelope>';

        HttpRequest.SetRequestUri(Url);
        HttpRequest.Method('POST');

        HttpContent.WriteFrom(XMLText);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-type');
        HttpHeaders.Add('Content-type', 'application/xml;charset=utf-8');
        HttpRequest.Content := HttpContent;
        HttpRequest.GetHeaders(HttpHeaders);
        HttpHeaders.Add('SOAPAction', 'urn:microsoft-dynamics-schemas/page/wscustomersoap');
        if UserID <> '' then begin
            AuthTxt := StrSubstNo('%1:%2', UserID, PasswordTxt);
            TempBlob.WriteAsText(AuthTxt, TextEncoding::Windows);
            HttpHeaders.Add('Authorization',StrSubstNo('Basic %1', TempBlob.ToBase64String()));
        end else begin
            //httpClient.UseWindowsAuthentication('Admin','D365BC_RW2','NavTraining');
        end;
        httpClient.Send(HttpRequest,HttpResponse);
        HttpResponse.Content.ReadAs(XMLText);
        error('Result %1',XMLText);


    end;
}