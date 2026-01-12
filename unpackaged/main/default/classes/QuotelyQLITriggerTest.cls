/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : QuotelyQLITriggerTest
* Created By                       : Quotely App Exchange Engineering Team
* Created Date                     : 08-10-2024
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                 Modification ID        Description 
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Quotely App Exchange Engineering 
* Team
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Note: This class/trigger was written by the Quotely Engineering team. Please do not update any instance of the code without consulting the Quotely App Exchange team.
******************************************************************************************************************************************************************************/

@isTest
public class QuotelyQLITriggerTest {
    
    @testSetup
    static void setupData() {
        
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
    }
    
    @isTest
    static void testQuoteLineItemTrigger() {
        Pricebook2 customPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert qli;
        
        qli = [SELECT Id, PricebookEntryId FROM QuoteLineItem WHERE Id = :qli.Id];
        
        PricebookEntry expectedPBE = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :customPricebook.Id LIMIT 1];
        
        System.assertNotEquals(null, qli.PricebookEntryId, 'PricebookEntryId should not be null');
        System.assertEquals(expectedPBE.Id, qli.PricebookEntryId, 'PricebookEntryId should match the expected entry from Integration Price Book');
    }
    
    @isTest
    static void testMultipleQuoteLineItems() {
        Pricebook2 customPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (Integer i = 0; i < 3; i++) {
            qliList.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = product.Id,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        insert qliList;
        
        List<QuoteLineItem> updatedQLIs = [SELECT Id, PricebookEntryId FROM QuoteLineItem WHERE Id IN :qliList];
        PricebookEntry expectedPBE = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :customPricebook.Id LIMIT 1];
        
        for (QuoteLineItem qli : updatedQLIs) {
            System.assertEquals(expectedPBE.Id, qli.PricebookEntryId, 'Each PricebookEntryId should match the expected entry from Integration Price Book');
        }
    }
}