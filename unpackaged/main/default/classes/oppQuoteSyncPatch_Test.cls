@isTest
public class oppQuoteSyncPatch_Test {
    @testSetup
    static void test_Setup(){
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;
        
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product');
        insert product;
        
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert standardPricebookEntry;
        
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert customPricebookEntry;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'CAD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100,
            varcpq__Unit_Cost__c = 80,
            varcpq__DH_Line__c = 1
        );
        insert qli;
    }
    @isTest
    public static void testOppQuoteSync(){
        Test.startTest();
        Quote quote = [Select id,opportunityId from Quote LIMIT 1];
        Opportunity opp = new Opportunity(Id = quote.OpportunityId);
        opp.SyncedQuoteId = quote.Id;
        update opp; 
        Test.stopTest();
        
    }
    @isTest
    public static void testOppQuoteSyncDelete(){
        Test.startTest();
        Quote quote = [Select id,opportunityId from Quote LIMIT 1];
        Opportunity opp = new Opportunity(Id = quote.OpportunityId);
        QuoteLineItem qli1 = [SELECT Id FROM QuoteLineItem WHERE varcpq__DH_Line__c = 1];
        Product2 product = [SELECT Id FROM Product2];
        opp.SyncedQuoteId = quote.Id;
        update opp; 
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100,
            varcpq__Unit_Cost__c = 80,
            varcpq__DH_Line__c = 2
        );
        insert qli;
        delete qli1;
        Test.stopTest();
        
    }
}