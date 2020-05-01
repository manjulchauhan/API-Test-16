report 50100 "DIR Consume SOAP WS"
{
    Caption = 'Consume SOAP WS';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    var
        XMLText: Text;
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;

        Url: Text;

        XMLoptions: XmlReadOptions;
        XMLDoc: XmlDocument;
        XmlNodeList: XmlNodeList;
        XmlNode: XmlNode;
        TempCust: Record Customer temporary;
        BalanceLCY: Decimal;
        RootNode: XmlNode;
        NamespaceMgr: XmlNamespaceManager;
        AuthTxt: Text;
        UserName: Text;
        Password: Text;
        TempBlob: Record TempBlob;

    begin
        // Prepare the XML Request message 
        XMLText := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
                    '  <soap:Body>' +
                    '   <ReadMultiple xmlns="urn:microsoft-dynamics-schemas/page/wscustomersoap">' +
                    '     <filter>' +
                    '         <Field>No</Field>' +
                    '         <Criteria />' +
                    '     </filter>' +
                    '     <bookmarkKey />' +
                    '     <setSize>0</setSize>' +
                    '   </ReadMultiple>' +
                    '  </soap:Body>' +
                    '</soap:Envelope>';
        // Set the URL
        Url := 'http://navtraining:7047/BC160_WebService/WS/CRONUS%20International%20Ltd./Page/WSCustomerSOAP';
        // Use Windows authentication
        UserName := 'User';
        Password := 'Password!23';

        // Prepare the Request message and the Respons message
        HttpRequest.SetRequestUri(URL);
        HttpRequest.Method('POST');
        // Set the Content
        HttpContent.WriteFrom(XMLtext);

        //Assign the Headers to the content
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/xml;charset=utf-8');
        // Put the content in the Request
        HttpRequest.Content := HttpContent;

        HttpRequest.GetHeaders(HttpHeaders);
        HttpHeaders.Add('SOAPAction', 'urn:microsoft-dynamics-schemas/page/WSCustomerSOAP');
        // Basic authentication 
        if UserName <> '' then begin
            AuthTxt := strsubstno('%1:%2', UserName, Password);
            TempBlob.WriteAsText(AuthTxt, TextEncoding::Windows);
            HttpHeaders.Add('Authorization', StrSubstNo('Basic %1', TempBlob.ToBase64String()));
        end else begin
            // Windows Authentication
            HttpClient.UseWindowsAuthentication('Admin', '1<3VScode', 'NavTraining');
        end;
        HttpClient.send(HttpRequest, HttpResponse);

        // Handle the result
        if not HttpResponse.IsSuccessStatusCode() then
            error(format(HttpResponse.HttpStatusCode()) + ' , ' + HttpResponse.ReasonPhrase())
        else begin
            clear(XMLtext);
            HttpResponse.Content().ReadAs(XMLtext);
            XMLoptions.PreserveWhitespace := false;
            XmlDocument.ReadFrom(xmlText, XMLoptions, XMLDoc);
            error('%1', XMLDoc);
            RootNode := XMLDoc.AsXmlNode();
            NamespaceMgr.NameTable(RootNode.AsXmlDocument().NameTable);
            NamespaceMgr.AddNamespace('soap', 'http://schemas.xmlsoap.org/soap/envelope/');
            if RootNode.SelectNodes('//WSCustomerSOAP', NamespaceMgr, XmlNodeList) then
                foreach XmlNode in XmlNodeList do begin
                    if XmlNode.SelectSingleNode('No', XmlNode) then
                        TempCust."No." := XmlNode.AsXmlElement.InnerText;

                    if XmlNode.SelectSingleNode('Name', XmlNode) then
                        TempCust.Name := XmlNode.AsXmlElement.InnerText;

                    if XmlNode.SelectSingleNode('City', XmlNode) then
                        TempCust.City := XmlNode.AsXmlElement.InnerText;

                    if XmlNode.SelectSingleNode('Balance_LCY', XmlNode) then begin
                        evaluate(BalanceLCY, XmlNode.AsXmlElement.InnerText);
                        TempCust."Budgeted Amount" := BalanceLCY;
                    end;

                    if (TempCust."No." <> '') and
                    (TempCust.Name <> '') and
                    (TempCust.City <> '') and
                    (TempCust."Budgeted Amount" <> 0) then begin
                        TempCust.Insert;
                        TempCust.init;
                    end;
                end;
        end;

        page.run(0, TempCust);
    end;
}