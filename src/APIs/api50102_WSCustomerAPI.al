page 50102 "DIR WS Customer API"
{
    Caption='WS Customer API';
    PageType = API;
    APIPublisher = 'DirectionsEMEA';
    APIGroup = 'APIs';
    APIVersion = 'v1.0';
    EntityName='WSCustomers';
    EntitySetName = 'WSCustomers';
    ApplicationArea = All;
    ODataKeyFields=SystemId;
    UsageCategory = Administration;
    SourceTable = Customer;
    DelayedInsert=true;
    
    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("No";"No.")
                {
                    ApplicationArea = All;
                }
                field(Name;Name)
                {
                    ApplicationArea = All;
                }
                field(DateFilter;"Date Filter")
                {
                    ApplicationArea = All;
                }
                field(SalesLCY;"Sales (LCY)")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}