@isTest
public class QuoteStateReverter_Test {
	@testSetup
    static void setupData() {
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        // Create standard pricebook
        Id PricebookId = Test.getStandardPricebookId();

        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        // Create custom pricebook
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;
        
        // Create Product2
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product');
        insert product;
        
        // Create Standard Pricebook Entry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert standardPricebookEntry;
        
        // Create Custom Pricebook Entry for 'Integration Price Book'
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert customPricebookEntry;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'CAD'
        );
        insert opp;
        
        // Create Quote related to the Opportunity
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Status = 'Approved',
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );

        insert qli;
    }
    
    @isTest
    static void testStateReverterQt(){
        Quote quote = [SELECT Id,ShippingCity FROM Quote];
        quote.ShippingCity = 'Pune';
        update quote;
    }
    @istest
    static void testStateReverterQLI(){
        QuoteLineItem qli = [SELECT Id, UnitPrice FROM QuoteLineItem];
        qli.UnitPrice = 150;
        update qli;
    }
}