page 50101 "DIR WS Customer OData"
{
    Caption='WS Customer OData';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Customer;
    
    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("No.";"No.")
                {
                    ApplicationArea = All;
                }
                field(Name;Name)
                {
                    ApplicationArea = All;
                }
                field("Date Filter";"Date Filter")
                {
                    ApplicationArea = All;
                }
                field("Sales (LCY)";"Sales (LCY)")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}