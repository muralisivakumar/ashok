@isTest
public class AvataxToQuotelyforQuoteTest {

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
            CurrencyIsoCode = 'CAD',
            Tax = 10, 
            varcpq__Tax_Rate__c = 0.1,
            varcpq__Total_Tax__c = 10 
        );
        insert quote;
    }
    @isTest
    static void testUpdateQuotelyFields() {
      
        List<Quote> quotes = [SELECT Id, Tax, varcpq__Tax_Rate__c, varcpq__Total_Tax__c FROM Quote];
        Map<Id, Quote> oldQuoteMap = new Map<Id, Quote>(quotes);
        
       
        Pricebook2 customPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id, CurrencyIsoCode,Tax FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
       
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100,
            AVA_SFCLOUD__SalesTax_Line__c = 200,
            AVA_SFCLOUD__Sales_Tax_Rate__c = '8.623'
        );
        insert qli;
        
        
        qli = [SELECT Id, AVA_SFCLOUD__Sales_Tax_Rate__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
       
        for (Quote q : quotes) {
            if (q.Tax != null) {
               q.Tax += 5; 
           } 
       }
       update quotes;


        Test.startTest();
        AvataxToQuotelyforQuote.updateQuotelyFields(quotes, oldQuoteMap);
        Test.stopTest();

        
        Quote newQuote = new Quote();
        newQuote.Id = quote.Id;
        newQuote.varcpq__Total_Tax__c = quote.Tax;

        String taxRate = qli.AVA_SFCLOUD__Sales_Tax_Rate__c;
        taxRate = taxRate.removeEnd('%');
        newQuote.varcpq__Tax_Rate__c = Decimal.valueOf(taxRate);

    }
}