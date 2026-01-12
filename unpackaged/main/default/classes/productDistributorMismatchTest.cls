@isTest
public class productDistributorMismatchTest {
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
            //avaQuotely__Tax_Rate__c = 0.07,
            Status = 'Draft',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;
    }
    
    @isTest
    static void testProductDistributorMismatch(){
    Id standardPricebook = Test.getStandardPricebookId();
        Pricebook2 integrationPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id,varcpq__Distributor_Account__c,varcpq__Distributor_Account__r.RecordType.Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id,varcpq__Total_Margin_percent__c FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        
        
        Test.startTest();
        Account distAcc = new Account(Name='Test Distributor',Type='Supplier',
                                     RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId(),
                                     varcpq__Net_terms__c ='NET45', varcpq__available_for_po__c = true );
        insert distAcc;
		product.varcpq__Distributor_Account__c = distAcc.Id;
        update product;
        Test.stopTest();
    }
    
    
    @isTest
    static void testProductDistributorMismatch2(){
    Id standardPricebook = Test.getStandardPricebookId();
        Pricebook2 integrationPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Integration Price Book' LIMIT 1];
        Product2 product = [SELECT Id,varcpq__Distributor_Account__c,varcpq__Distributor_Account__r.RecordType.Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Quote quote = [SELECT Id,varcpq__Total_Margin_percent__c FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        
        
        Test.startTest();
        Account distAcc = new Account(Name='Test Distributor',Type='Supplier',
                                     RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId(),
                                     varcpq__Net_terms__c ='NET45', varcpq__available_for_po__c = true );
        insert distAcc;
		product.varcpq__Distributor_Account__c = distAcc.Id;
        update product;
        Test.stopTest();
    }
}