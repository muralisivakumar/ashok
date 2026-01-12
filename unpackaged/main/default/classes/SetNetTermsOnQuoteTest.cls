@isTest
public class SetNetTermsOnQuoteTest {
  /*@testSetup
    static void testsetupData() {
         List<RecordType> accountRecordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name IN ('US Account', 'Canadian Account')];
        Id usRecordTypeId;
        Id canadianRecordTypeId;

        for (RecordType recordType : accountRecordTypes) {
            if (recordType.Name == 'US Account') {
                usRecordTypeId = recordType.Id;
            } else if (recordType.Name == 'Canadian Account') {
                canadianRecordTypeId = recordType.Id;
            }
        }
        
        
        Account usAccount = new Account(
            Name = 'US Account',
            RecordTypeId = usRecordTypeId,
            varcpq__NET_TERMS__c = 'NET45'
        );
        insert usAccount;

       
        Account canadianAccount = new Account(
            Name = 'Canadian Account',
            RecordTypeId = canadianRecordTypeId,
            varcpq__NET_TERMS__c = 'NET45'
        );
        insert canadianAccount;
    }*/
    @testSetup
    static void setupData() {
        
       
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c = true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;

        Id PricebookId = Test.getStandardPricebookId();
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;
        
        Account distributorAcc = new Account(Name = 'Test Distributor', Type = 'Supplier',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId(),
                                             varcpq__Net_terms__c = 'NET45', varcpq__available_for_po__c = true);
        insert distributorAcc;
        
        Account nonMatchingDistributorAcc = new Account(Name = 'Different Distributor', Type = 'Supplier',
                                                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId(),
                                                        varcpq__Net_terms__c = 'NET30', varcpq__available_for_po__c = true);
        insert nonMatchingDistributorAcc;
        
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, 
                                        varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product',
                                        varcpq__Distributor_Account__c = nonMatchingDistributorAcc.Id);
        insert product;
        
     
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPricebookEntry;
        
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert customPricebookEntry;
        
        List<RecordType> accountRecordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name IN ('US Account', 'Canadian Account')];
        Id usRecordTypeId;
        Id canadianRecordTypeId;
        for (RecordType recordType : accountRecordTypes) {
            if (recordType.Name == 'US Account') {
                usRecordTypeId = recordType.Id;
            } else if (recordType.Name == 'Canadian Account') {
                canadianRecordTypeId = recordType.Id;
            }
        }
		 Account usAccount = new Account(
            Name = 'US Account',
            RecordTypeId = usRecordTypeId,
            varcpq__NET_TERMS__c = 'NET45'
        );
        insert usAccount;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = usAccount.Id
        );
        insert opp;
        
       
        
        
       
        
    }   
    
    @isTest
    static void setNetTermsOnQuoteTest() {
        Opportunity opp = [Select Id from Opportunity Where Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
       Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            CurrencyIsoCode = 'USD'
        );
        insert quote;
		Test.stopTest();
        
     
        
    }

   
}