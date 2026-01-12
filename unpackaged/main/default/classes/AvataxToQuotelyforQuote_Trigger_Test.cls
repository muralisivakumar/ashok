@isTest
public class AvataxToQuotelyforQuote_Trigger_Test {
    
@isTest
    Static void testAvataxQuotelyForQuote(){
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN; 
        
        //Insert Account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type = 'Suppliers';
        insert acc;
        
        //Insert Opportunity
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.StageName = 'Prospecting';
        Opp.CloseDate = Date.today().addDays(30);
        Opp.AccountId = acc.Id;
            Opp.CurrencyIsoCode = 'CAD';
        
        insert opp;
        
        //Insert Product
        Product2 prod = new Product2(
        Name = 'Test Product', 
        varcpq__LISTPRICE__c = 100.0, 
        IsActive = true,
        varcpq__PARTNUMBER__c = 'Test Product',
        varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
        
        //Insert Quote
         Quote quote = new Quote(
         OpportunityId = opp.Id, 
         Name = 'Test Quote', 
         CurrencyIsoCode = 'CAD'
           );
        
        Test.StartTest();
        insert quote;
        Test.StopTest();
        
        
    }
}