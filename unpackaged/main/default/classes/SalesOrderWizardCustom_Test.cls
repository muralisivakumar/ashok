@isTest
public class SalesOrderWizardCustom_Test {
    @testSetup
    static void setupTestData() {
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        /* Id PricebookId = Test.getStandardPricebookId();

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
insert integrationPbe;*/
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPricebookId,
            IsActive = true,
            Name = 'Standard Price Book'
        );
        upsert standardPricebook;
        
        // create a product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product',
            CurrencyIsoCode = 'USD'
        );
        insert prod;
        
        // ✅ first create standard price entry
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPbe;
        
        // now your custom integration pricebook
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        // ✅ then custom pricebook entry (depends on the standard one)
        PricebookEntry integrationPbe = new PricebookEntry(
            Pricebook2Id = integrationPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPbe;
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
            varcpq__Total_Margin__c = 3,
            varcpq__Unit_Cost__c = 50,
            varcpq__DH_Line__c = 1
           
        );
        insert qli;
        
        opp.SyncedQuoteId = quote.Id;
        update opp;
        
    }
    @isTest
    static void testSOWizrd(){
        Quote qt = [SELECT ID,Name From Quote];
        Id quoteId = qt.Id;
        SalesOrderWizardCustom.getQuoteMargin(quoteId);
        SalesOrderWizardCustom.getContact(quoteId, '');
        SalesOrderWizardCustom.getContact(quoteId, 'Test');
        SalesOrderWizardCustom.getCustomerAddress(quoteId, '');
        SalesOrderWizardCustom.getCustomerAddress(quoteId, 'Test');
        //        SalesOrderWizardCustom.getPartialInvoiceSett();
        SalesOrderWizardCustom.getRenewalProduct(quoteId);
        SalesOrderWizardCustom.getQuoteFiles(quoteId);
    } 
    
    @isTest
    static void testSoWizrd2(){
        Quote qt = [SELECT ID,Name,status From Quote];
        Id quoteId = qt.Id;
        varcpq__Partial_Invoice_Setting__c pis = new varcpq__Partial_Invoice_Setting__c();
        pis.varcpq__Allow_Partial_Invoice__c = true;
        insert pis;
        varcpq__sales_order__c so = SalesOrderWizardCustom.insertSO(quoteId);
        contact con = [select id from contact];
        Product2 prod = [Select id From product2];
        varcpq__Customer_Address__c add = [select id from varcpq__Customer_Address__c where Default_Billing_Address__c =true];
        varcpq__Customer_Address__c addship = [select id from varcpq__Customer_Address__c where Default_Shipping_Address__c =true];
        
        Account disti = new Account(name='supplier acc',type='Supplier',varcpq__Available_for_PO__c = true); insert disti;
        Test.startTest();
        //varcpq__sales_order__c so = [Select id from varcpq__sales_order__C];
        List<SalesOrderWizardCustom.RenewalWrapper> renewalProducts = new List<SalesOrderWizardCustom.RenewalWrapper>();
        SalesOrderWizardCustom.RenewalWrapper renewalWrapper = new SalesOrderWizardCustom.RenewalWrapper();
        renewalWrapper.prodId = prod.Id;
        renewalWrapper.startDate = System.today();
        renewalWrapper.endDate = System.today().addYears(1);
        renewalWrapper.trackRenewal = 'false';
        renewalProducts.add(renewalWrapper);
        Map<String,String> supplierPONoteMap = new Map<String,String>();
        supplierPONoteMap.put(disti.Id,'Notes for Supplier');
        SalesOrderWizardCustom.soResponse soResp = new SalesOrderWizardCustom.soResponse();
        soResp.soId = so.Id;
        soResp.shipConId = con.Id; // Set Shipping Contact ID
        soResp.billConId = con.Id; // Set Billing Contact ID
        soResp.shipAddId = addShip.Id; // Set Shipping Address ID
        soResp.billAddId = add.Id; // Set Billing Address ID
        soResp.customerFacingShippingNote = 'Shipping notes'; // Set Shipping Note
        soResp.customerFacingBillingNote = 'Billing notes'; // Set Billing Note
        soResp.internalBillingNote = 'internal billing notes'; // Set Shipping Note
        soResp.internalShippingNote = 'internal shipping notes'; // Set Billing Note
        soResp.customerPONum = 'PO12345'; // Set Customer PO Number
        soResp.supplierPONotes = supplierPONoteMap;
        soResp.files = new List<String>(); 
        String soRespJSON = JSON.serialize(soResp);
        
        SalesOrderWizardCustom.createSalesOrder(soRespJSON, renewalProducts);
        SalesOrderWizardCustom.getQuoteInfo(quoteId);
        SalesOrderWizardCustom.getNetTerms();
        SalesOrderWizardCustom.deleteSO(so.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testPOFiles(){
        Quote qt = [SELECT Id from quote];
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'TestPO.pdf',
            PathOnClient = 'TestPO.pdf',
            VersionData = Blob.valueOf('This is the content of the test PO document.')
        );
        
        
        insert testContentVersion;
        
        Test.startTest();
        Test.stopTest();
        ContentVersion cv = [SELECT Id,contentDocumentId FROM ContentVersion WHERE Id=:testContentVersion.Id];
        
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = qt.Id,
            ShareType = 'V', // 'V' stands for Viewer permission
            Visibility = 'AllUsers'
        );
        insert contentLink;
        SalesOrderWizardCustom.getPOFiles(qt.Id);
        SalesOrderWizardCustom.savePOFile(qt.Id, cv.ContentDocumentId,cv.Id);
        SalesOrderWizardCustom.getAccCreditDetails(qt.Id);
        SalesOrderWizardCustom.getQuoteCustomerPO(qt.Id);
    }
      @IsTest
    static void testDefaultErrorMessage() {
        Exception exCaught;

        // Create an unrelated exception
        try {
            // force exception without CMDT substring
            Integer x = 5 / 0;
        } catch (Exception ex) {
            exCaught = ex;
        }

        Test.startTest();
        String result = SalesOrderWizardCustom.getUserErrorMessage(exCaught);
        Test.stopTest();
    }
    
}