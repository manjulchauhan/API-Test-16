codeunit 50100 "DIR Install API Test"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        WebServiceManagement: codeunit "Web Service Management";
        ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber";
    begin
        WebServiceManagement.CreateTenantWebService(ObjectType::Page, page::"DIR WS Customer SOAP", 'WSCustomerSOAP', true);
        WebServiceManagement.CreateTenantWebService(ObjectType::Page, page::"DIR WS Customer OData", 'WSCustomerOData', true);
        WebServiceManagement.CreateTenantWebService(ObjectType::Page, page::"DIR WS Customer API", 'WSCustomerAPI', true);
    end;
}