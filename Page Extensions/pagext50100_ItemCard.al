pageextension 50100 "DIR Item Card" extends "Item Card"
{
    actions
    {
        addfirst(Functions)
        {
            action("DIR Download Picture")
            {
                Caption = 'Download Picture';
                Image = ImportCodes;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    HttpClient: HttpClient;
                    HttpResponse: HttpResponseMessage;
                    InStr: InStream;
                    Url: Label 'http://ba-consult.dk/downloads/bicycle.jpg';
                begin
                    HttpClient.Get(Url, HttpResponse);
                    HttpResponse.Content.ReadAs(Instr);
                    Picture.ImportStream(InStr, 'Default Image');
                    CurrPage.Update(true);
                end;
            }
        }
    }
}