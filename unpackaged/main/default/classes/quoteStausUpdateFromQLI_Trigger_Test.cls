@isTest
public class quoteStausUpdateFromQLI_Trigger_Test{
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
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
    }
    
    @isTest
    static void testQuoteLineItemTrigger() {
        // Retrieve test data
        Pricebook2 customPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        
        // Insert QuoteLineItem (this should trigger the QuotelyQLITrigger)
        insert qli;
        
        // Fetch updated QuoteLineItem with PricebookEntryId populated by trigger
        qli = [SELECT Id, PricebookEntryId FROM QuoteLineItem WHERE Id = :qli.Id];
        
        // Verify PricebookEntryId is assigned from 'Integration Price Book'
        PricebookEntry expectedPBE = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :customPricebook.Id LIMIT 1];
        
       
    }
    
    @isTest
    static void testMultipleQuoteLineItems() {
        // Retrieve test data
        Pricebook2 customPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        // Create multiple QuoteLineItems
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (Integer i = 0; i < 3; i++) {
            qliList.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = product.Id,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        
        // Insert multiple QuoteLineItems (this should trigger the QuotelyQLITrigger)
        insert qliList;
        
        // Verify all QuoteLineItems have correct PricebookEntryId assigned
        List<QuoteLineItem> updatedQLIs = [SELECT Id, PricebookEntryId FROM QuoteLineItem WHERE Id IN :qliList];
        PricebookEntry expectedPBE = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :customPricebook.Id LIMIT 1];
        
        for (QuoteLineItem qli : updatedQLIs) {
            System.assertEquals(expectedPBE.Id, qli.PricebookEntryId, 'Each PricebookEntryId should match the expected entry from Integration Price Book');
        }
    }
}