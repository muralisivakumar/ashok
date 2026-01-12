@isTest
public class QuoteApprovedAction_Test {
    @testSetup
    static void setupTestData() {
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;
        
        PricebookEntry integrationPbe = new PricebookEntry(
            Pricebook2Id = integrationPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbe;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        
         Quote quote1 = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote 1', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote1;
        
       
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;
        
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote1.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli1;
        
       
        
        opp.SyncedQuoteId = quote.Id;
        update opp;
        /*Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('recordId', quote.Id);
        
        Flow.Interview screenFlow = Flow.Interview.createInterview('varcpq__Quote_ly_Sync_Quote', flowInputs);
        
        
        screenFlow.start();*/
    }
    
    @isTest
    static void testClass(){
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote WHERE NAME = 'Test Quote'];
		QuoteApprovedAction.getQuoteInfo(quote.Id);
        QuoteApprovedAction.updateOtherQuotes(quote.Id);
        QuoteApprovedAction.getLossReasons();
        
    }
     @isTest
    static void testChangeQuoteStatus() {
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote  WHERE NAME = 'Test Quote'];
         
        quote.Status = 'Presented';
        Update quote;        
        QuoteApprovedAction.changeQuoteStatus(quote.Id, 'Yes', true, '');        
    }
    
    @isTest
    static void testChangeQuoteStatus1() {
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote  WHERE NAME = 'Test Quote']; 
        QuoteApprovedAction.changeQuoteStatus(quote.Id, 'No', true,'');
    }
    
    @isTest
    static void testChangeQuoteStatus2() {
       Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote  WHERE NAME = 'Test Quote']; 
         QuoteApprovedAction.changeQuoteStatus(quote.Id, 'No', false, 'Price');
    }
    
    @isTest
    static void testChangeQuoteStatusDeclined() {
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote  WHERE NAME = 'Test Quote'];
        
        QuoteApprovedAction.changeQuoteStatus(quote.Id, 'No', true,'');
        
    }
    @isTest
    static void testChangeQuoteStatusDeclined2() {
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote  WHERE NAME = 'Test Quote'];
        
        QuoteApprovedAction.changeQuoteStatus(quote.Id, 'No', false, 'Price');
    }
}