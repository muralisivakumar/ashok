@isTest
public class SalesOrderDefaultFiles_Test {
    @testSetup
    static void setupTestData() {
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        insert acc;
        contact con = new contact(LastName='Test',email='test@test.com',accountId=acc.Id);
        insert con;
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.id,
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
            varcpq__Customer__c = acc.id,
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
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'SamplePDF'; 
        contentVersion.PathOnClient = 'SamplePDF.pdf'; 
        contentVersion.VersionData = Blob.valueOf('This is a sample PDF content.');
        Insert contentVersion;
        if (contentVersion.ContentDocumentId == null) {
            
            Test.startTest();
            Test.stopTest();
            contentVersion = [SELECT Id,Title,PathOnClient, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            System.debug('cv ContentDocumentId after Test.stopTest(): ' + contentVersion.ContentDocumentId);
        }
        ContentDocument contentDocument = [
            SELECT Id FROM ContentDocument WHERE Id = :contentVersion.ContentDocumentId
        ];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = opp.Id; 
        cdl.ContentDocumentId = contentDocument.Id;
        cdl.ShareType = 'I'; 
        cdl.Visibility = 'AllUsers';

        insert cdl;
        
        List<RecordType> recordTypes = [SELECT Id, DeveloperName, Name, IsActive, SobjectType 
                                        FROM RecordType 
                                        WHERE SobjectType = 'varcpq__DH_Supporting_Quote__c'];
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        for(RecordType recType : recordTypes){
            recordTypeMap.put(recType.Name , recType.Id);
        }
        varcpq__DH_Supporting_Quote__c suppQuoteFile = new varcpq__DH_Supporting_Quote__c(
            
            RecordTypeId = recordTypeMap.get('File Record') ,
            varcpq__DH_Status__c = 'Complete',
            varcpq__DH_ContentDocumentId__c = contentDocument.Id ,
            varcpq__DH_File_Name__c = contentVersion.Title,
            
            varcpq__DH_contentVersionID__c = contentVersion.Id,
            varcpq__Opportunity__c = opp.Id,
            varcpq__Processed_At__c = System.now(),
            varcpq__Uploaded_At__c = System.now()
        );
        insert suppQuoteFile;
        
        varcpq__DH_Supporting_Quote__c suppQuoteQuote = new varcpq__DH_Supporting_Quote__c(
            
            RecordTypeId = recordTypeMap.get('Quote Record'),
            varcpq__DH_Distributor_Name__c = 'Carahsoft Technology Corp',
            varcpq__DH_Expiration_Date__c = System.today().addDays(10),
            varcpq__DH_File_Name__c = contentVersion.PathOnClient,
            varcpq__DH_Quote_No__c = '9385066',
            varcpq__DH_Shipping_Cost__c = 250,
            varcpq__DH_Supporting_File_Quote__c = suppQuoteFile.Id,
            varcpq__DH_Total__c = 218453.7);
        insert suppQuoteQuote;
        
        varcpq__DH_Supporting_Quote__c suppQuotePart = new varcpq__DH_Supporting_Quote__c(

            RecordTypeId = recordTypeMap.get('Part'),
            varcpq__DH_Cost_Price__c = 76796,
            varcpq__DH_Description__c = 'BIG-IP Switch: 5250v FIPS Better Bundle (32G, Max SSL & Comp)',
            varcpq__DH_Extended_Price__c = 153592,
            varcpq__DH_List_Price__c = 95995,
            varcpq__DH_Part_No__c = 'F5-BIG-BR-5250V-F',
            varcpq__DH_Quantity__c = 2,
            varcpq__DH_Supporting_File_Quote__c = suppQuoteQuote.Id,
            varcpq__Part_Sequence_Number__c = 1);
        insert suppQuotePart;
        
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
            varcpq__ITEMDESC__c = 'Test Product',
            varcpq__DH_Supporting_Quote_Line_Item__c = suppQuotePart.Id
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
        
        
        
        
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Accepted',
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
        
        opp.SyncedQuoteId = quote.Id;
        update opp;
        
        ContentDocumentLink cdlQuote = new ContentDocumentLink();
        cdlQuote.LinkedEntityId = Quote.Id; 
        cdlQuote.ContentDocumentId = contentDocument.Id;
        cdlQuote.ShareType = 'I'; 
        cdlQuote.Visibility = 'AllUsers';

        insert cdlQuote;

    }
    
    @isTest
    static void testSalesOrderDF(){
        Quote qt = [SELECT Id FROM Quote];
        List<QuoteLineItem> qlis = [SELECT Id,QuoteId,Product2Id FROM QuoteLineItem WHERE QuoteId=:qt.Id];
        SalesOrderDefaultFilesHandler.triggerHandler(qlis);
    }
}