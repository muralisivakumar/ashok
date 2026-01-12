@isTest
public class TaxDetailshandlerSOLI_Test {
	@isTest
    static void createSalesOrder(){
        Account acc = new account(name='test');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        varcpq__Sales_order__c so = new varcpq__Sales_order__c();
        so.Name = 'Test SO';
        so.varcpq__Client__c = acc.id;
        so.varcpq__Opportunity__c = opp.Id;
        insert so;
        
        varcpq__Sales_Order_Line_item__c soli = new varcpq__Sales_order_line_item__c();
        soli.varcpq__Quantity__c = 5;
        soli.varcpq__Sales_Order__c = so.id;
        soli.varcpq__Unit_Cost__c = 200;
        insert soli;
        
    }
}