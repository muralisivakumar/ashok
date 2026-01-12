@isTest
public class PDFCounterService_Test {
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
        
        Pricebook2 integrationPricebookCad = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert integrationPricebookCad;
        
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
        PricebookEntry integrationPbeCad = new PricebookEntry(
            Pricebook2Id = integrationPricebookCad.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbeCad;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        Id CADAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId();
        
        List<account> accounts = new List<account>();
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        Account accCad = new Account(Name = 'Test Cad Account', RecordTypeId = CADAccRecType);
        accounts.add(acc);
        accounts.add(accCad);
        Insert accounts;
        
        Id cadAccId;
        Id usAccId;
        for(account account:accounts){
            if(account.RecordTypeId == USAccRecType){
                usAccId = account.Id;
            }else{
                cadAccId = account.Id;
            }
            
        }
        
        List<Contact> contacts = new List<Contact>();
        contact con = new contact(LastName='Test',email='test@test.com',accountId=usAccId);
        contact conCad = new contact(LastName = 'Test canada', email = 'testcad@test.com',accountId= cadAccId);
        contacts.add(con);
        contacts.add(conCad);
        Insert contacts;
        
        
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = usAccId,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
        
        varcpq__Customer_Address__c addship = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = usAccId,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Shipping_Address__c = true,
            Country__c = 'US');
        insert addShip;
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = usAccId
        );
        insert opp;
        Opportunity oppCad = new Opportunity(
            Name = 'Test Opportunity Cad',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = cadAccId
        );
        insert oppCad;
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
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;   
    }
    
    @isTest
    static void test_method(){
        Quote qt = [SELECT Id FROM Quote];
		// Create ContentVersion for testing PDF attachments
        ContentVersion cv = new ContentVersion(
            Title = 'ClutchQuote_00006278_20250218',
            PathOnClient = 'ClutchQuote_00006278_20250218.pdf',
            VersionData = Blob.valueOf('Test PDF Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Create ContentDocumentLink to link the PDF to Account
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        Test.startTest();
        Test.stopTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = conDocId,
            LinkedEntityId = qt.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        PDFCounterService pdfCount  = new PDFCounterService();
        set<Id> ids = new set<id>();
        ids.add(qt.Id);
        PDFCounterService.updatePDFCount(ids,'insert');
        
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id=:conDocId];
        DELETE doc;
        
        PDFCounterService.updatePDFCountAfterDelete(ids);
    }
}