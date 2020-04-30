page 50100 "DIR WS Customer SOAP"
{
    Caption = 'WS Customer SOAP';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Customer;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field("Date Filter"; "Date Filter")
                {
                    ApplicationArea = All;
                }
                field("Sales (LCY)"; "Sales (LCY)")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}