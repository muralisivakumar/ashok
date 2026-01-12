@isTest
public class cloneOppQuote_Test {
    @testsetup
    static void test_setup(){
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=false);
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
        varcpq__Manufacturer__c manuf = new varcpq__Manufacturer__c (Name='Stark enterprises');
        insert manuf;
        Account disti = new Account(name='abc suppliers',Type='Supplier',varcpq__Available_for_PO__c=true);
        Insert disti;
        Product2 prod = new Product2(
            Name = 'Test Product74874', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__Manufacturer__c = manuf.Id,
            varcpq__Distributor_Account__c = disti.Id,
            varcpq__PARTNUMBER__c = 'Test Product74874',
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
        Account account = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        Insert account;
        
        contact contact = new contact(LastName='Test',email='test@test.com',accountId=account.Id);
        Insert contact;
        
        
        // Create Opportunity record with the Split Teams disabled
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = account.Id
        );
        Insert opp;
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            varcpq__DH_Line__c = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;
  
    }
    
    @isTest
    static void testCloneQuoteopp(){
        Test.startTest();
        Quote quote = [SELECT Id,OpportunityId,AccountId,RecordType.Name FROM Quote LIMIT 1];
        cloneOppQuote.getQuoteInfo(quote.Id);
        Date closeDate = Date.newInstance(2025,10,10);
        List<user> defUsers=[SELECT Id FROM User WHERE Profile.Name='Clutch Default User' AND isActive=true];
        List<Id> userIds = new List<Id>();
        for(user user:defUsers){
            userIds.add(user.Id);
        }
        cloneOppQuote.cloneQuoteToNewOpp(quote.Id, quote.AccountId, quote.OpportunityId,'Advertisement', closeDate, quote.RecordType.Name, 0, 0, 'Yes', 'Yes', userIds);
        //cloneOppQuote.cloneQuote(quote.I,, quote.OpportunityId, quote.RecordTypeId);,
        Test.stopTest();
    }
    
}