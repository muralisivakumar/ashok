@isTest
private class CustomNoteControllerTest {
    
    private static Account distributor1;
   
    // Helper method to create distributors and suppliers
    private static Account createDistributors() {
    varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=false);
    insert prosetting; 
    
    varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
    insert CLIN;
    
    // Query the Distributor RecordType ID dynamically
    RecordType distributorRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'US_Account' LIMIT 1];
    
    Account distributor1 = new Account(
        Name = 'Distributor A', 
        Type = 'Supplier', 
        varcpq__NET_TERMS__c = 'NET30',
        RecordTypeId = distributorRT.Id, 
        CurrencyIsoCode = 'USD', 
        varcpq__Available_for_PO__c = true
    );
    insert distributor1;
    return distributor1;
    }

    // Helper method to create Account
    private static Account createAccount() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        return a;
    }
   

    // Helper method to create Opportunity
    private static Opportunity createOpportunity(Account acc) {
        Opportunity o = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert o;
        return o;
    }

    // Helper method to create Quote (linked to Opportunity, NOT Account)
    private static Quote createQuote(Account acc) {
        Opportunity opp = createOpportunity(acc);
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            CurrencyIsoCode = 'USD',
    		Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;
        return q;
    }

    // Helper method to create Sales Order (Sales_Order__c)
    private static varcpq__Sales_Order__c createSalesOrder(Account acc) {
        varcpq__Sales_Order__c so = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order',
            //Account__c = acc.Id,
            varcpq__Client__c = acc.Id // example required field, adjust as needed
        );
        insert so;
        return so;
    }

    // Helper method to create Purchase Order
    private static varcpq__Purchase_Order__c createPurchaseOrder(varcpq__Sales_Order__c so) {
        varcpq__Purchase_Order__c po = new varcpq__Purchase_Order__c(
            //Name = 'Test Purchase Order',
            varcpq__Sales_Order__c = so.Id
        );
        insert po;
        return po;
    }

    // Helper method to create AP Invoice
    private static varcpq__Accounts_Payable_Invoice__c createAPInvoice(varcpq__Sales_Order__c so) {
        varcpq__Accounts_Payable_Invoice__c apinv = new varcpq__Accounts_Payable_Invoice__c(
            //Name = 'Test AP Invoice',
            Sales_Order__c = so.Id
        );
        insert apinv;
        return apinv;
    }

    // Helper method to create Invoice
    private static varcpq__Invoice__c createInvoice(varcpq__Sales_Order__c so) {
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            //Name = 'Test Invoice',
            varcpq__Sales_Order__c = so.Id
        );
        insert inv;
        return inv;
    }

    // Helper to get a valid picklist value from Note_Type__c
    private static String getValidNoteType() {
        List<String> values = CustomNoteController.getNoteTypePicklistValues();
        if (!values.isEmpty()) {
            return values[0];
        }
        // fallback if no picklist value is found
        return 'Internal - Billing';
    }

    // Generic test method for saveNoteRecord with dynamic parent record
    private static void testSaveNoteRecordForParent(SObject parent) {
        CustomNoteController.RecordContextWrapper context = new CustomNoteController.RecordContextWrapper();
        context.recordId = parent.Id;

        String noteType = getValidNoteType();

        List<Custom_Note__c> notes = [SELECT Id, Title__c, Note_Type__c, Supplier__c FROM Custom_Note__c 
            WHERE Title__c = :('Test Note for ' + parent.getSObjectType().getDescribe().getName()) 
            AND Note_Type__c = :noteType LIMIT 1];
        //System.assertEquals(1, notes.size(), 'Note should be inserted for ' + parent.getSObjectType().getDescribe().getName());
    }

    @isTest 
    static void testSaveNoteRecord_AllParents() {
        Account distributor1 = createDistributors();
        Account acct = createAccount();
        varcpq__Sales_Order__c so = createSalesOrder(acct);
        Opportunity opp = createOpportunity(acct);
        Quote q = createQuote(acct);
        varcpq__Purchase_Order__c po = createPurchaseOrder(so);
        varcpq__Accounts_Payable_Invoice__c apinv = createAPInvoice(so);
        varcpq__Invoice__c inv = createInvoice(so);

    // Pick a valid Note Type
    String noteType = getValidNoteType();

    // Save a note only for Opportunity
    CustomNoteController.RecordContextWrapper context = new CustomNoteController.RecordContextWrapper();
    context.recordId = opp.Id;

    Test.startTest();
    CustomNoteController.saveNoteRecord('Note for Opportunity', 'Test body', noteType, distributor1.Id, wrapRecord(opp.Id));
    CustomNoteController.saveNoteRecord('Note for Quote', 'Test body', noteType, distributor1.Id, wrapRecord(q.Id));
    CustomNoteController.saveNoteRecord('Note for Sales Order', 'Test body', noteType, distributor1.Id, wrapRecord(so.Id));
    CustomNoteController.saveNoteRecord('Note for PO', 'Test body', noteType, distributor1.Id, wrapRecord(po.Id));
    CustomNoteController.saveNoteRecord('Note for AP Invoice', 'Test body', noteType, distributor1.Id, wrapRecord(apinv.Id));
    CustomNoteController.saveNoteRecord('Note for Invoice', 'Test body', noteType, distributor1.Id, wrapRecord(inv.Id));
    Test.stopTest();

    List<Custom_Note__c> notes = [SELECT Id, Title__c FROM Custom_Note__c];
    System.assertEquals(6, notes.size(), 'Six notes should have been inserted for each parent record.');  
    
    }
    
    private static CustomNoteController.RecordContextWrapper wrapRecord(Id recordId) {
        CustomNoteController.RecordContextWrapper context = new CustomNoteController.RecordContextWrapper();
        context.recordId = recordId;
        return context;
    }


    @isTest static void testGetNoteTypePicklistValues() {
        List<String> values = CustomNoteController.getNoteTypePicklistValues();
        System.assert(values != null && values.size() > 0, 'Should return at least one picklist value');
    }

    @isTest static void testGetNotesForRecord() {
        Account acct = createAccount();
        varcpq__Sales_Order__c so = createSalesOrder(acct);

        Custom_Note__c note = new Custom_Note__c(
            Title__c = 'Test Note',
            Compose_Text__c = 'Test',
            Note_Type__c = getValidNoteType(),
            Sales_Order__c = so.Id,
            Supplier__c = acct.Id
        );
        insert note;

        List<Custom_Note__c> notes = CustomNoteController.getNotesForRecord(so.Id);
        System.assertEquals(1, notes.size());
        System.assertEquals(note.Id, notes[0].Id);
    }
    
 /*   @isTest
    static void testGetSuppliersByCurrency_Quote() {
        
		Account distributor1 = createDistributors();
        Account acct = createAccount();
        Quote q = createQuote(acct);

        Id PricebookId = Test.getStandardPricebookId();

        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'USD', IsActive = true);
        insert customPricebook;
        
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product', varcpq__Distributor_Account__c = distributor1.Id);
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
        

        QuoteLineItem qli = new QuoteLineItem(QuoteId = q.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = customPricebookEntry.Id);
        insert qli;

        Test.startTest();
        List<Account> suppliers = CustomNoteController.getSuppliersByCurrency(q.Id);
        Test.stopTest();

        System.assert(!suppliers.isEmpty(), 'Suppliers should be returned for Quote');
        //System.assert(suppliers.contains(distributor1), 'Distributor account should be in the supplier list');
    }*/
    
    @isTest 
    static void testGetSuppliersByCurrency_Quote() {
        
        Account distributor1 = createDistributors();
        Account acct = createAccount();
        Opportunity opp = createOpportunity(acct);
    
        Id standardPbId = Test.getStandardPricebookId();
    	PriceBook2 standardPricebook = new PriceBook2(Id = standardPbId);        
        update standardPricebook;
        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = standardPbId
        );
        insert q;
    
        // Product with required custom fields
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            varcpq__LISTPRICE__c = 100,
            varcpq__PARTNUMBER__c = 'PART123',
            varcpq__ITEMDESC__c = 'Test Desc',
            varcpq__Distributor_Account__c = distributor1.Id
        );
        insert product;
        
        // Standard PricebookEntry (required before custom pricebook entry)
        PricebookEntry standardPbe = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = standardPricebook.id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

    	// Custom Integration Price Book
        Pricebook2 customPb = new Pricebook2(
            Name = 'Integration Price Book',
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert customPb;
        
        // Pricebook Entry for Integration Price Book (IMPORTANT for trigger)
        PricebookEntry customPbe = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = customPb.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert customPbe;
    
        // Insert QuoteLineItem — trigger will assign correct PricebookEntryId
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 1,
            UnitPrice = 100,
            Product2Id = product.Id // <-- let the trigger assign PricebookEntryId
        );
        insert qli;
    
        // Now call the method being tested
        Test.startTest();
        List<Account> suppliers = CustomNoteController.getSuppliersByCurrency(q.Id);
        Test.stopTest();
    
        System.assert(!suppliers.isEmpty(), 'Suppliers should be returned for Quote');
    }

    
    @isTest
    static void testGetSuppliersByCurrency_SalesOrderBranch() {
        Account acct = createAccount();
        varcpq__Sales_Order__c so = createSalesOrder(acct);
        Account distributor1 = createDistributors();
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product', varcpq__Distributor_Account__c = distributor1.Id);
        insert product;
        
        // Create sales order line item referencing product
        varcpq__Sales_Order_Line_Item__c soli = new varcpq__Sales_Order_Line_Item__c(varcpq__Quantity__c = 1,varcpq__Sales_Order__c = so.Id,varcpq__List_Price__c = 100);
        insert soli;
        
        Test.startTest();
        List<Account> suppliers = CustomNoteController.getSuppliersByCurrency(so.Id);
        Test.stopTest();
        
        System.assert(!suppliers.isEmpty(), 'Should return distributor from sales order branch');
        //System.assert(suppliers.contains(distributor), 'Distributor must be included');
    }
    
    @isTest
    static void testGetSuppliersByCurrency_PurchaseOrderBranch() {
        Account acct = createAccount();
        varcpq__Sales_Order__c so = createSalesOrder(acct);
        Account distributor1 = createDistributors();
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product', varcpq__Distributor_Account__c = distributor1.Id);
        insert product;
        
        varcpq__Purchase_Order__c po = createPurchaseOrder(so);
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(varcpq__Quantity__c =1);
        
        Test.startTest();
        List<Account> suppliers = CustomNoteController.getSuppliersByCurrency(po.Id);
        Test.stopTest();
        
        System.assert(!suppliers.isEmpty(), 'Should return distributor from purchase order branch');
        //System.assert(suppliers.contains(distributor), 'Distributor must be included');
    }
    
    @isTest
    static void testSaveNoteRecord_MissingSupplier() {
        Account acct = createAccount();
        Opportunity opp = createOpportunity(acct);
        String noteType = getValidNoteType();
        
        CustomNoteController.RecordContextWrapper context = new CustomNoteController.RecordContextWrapper();
        context.recordId = opp.Id;
    
        Test.startTest();
        try {
            CustomNoteController.saveNoteRecord('Note with no supplier', 'Test body', noteType, null, context);
        } catch (Exception e) {
            System.assert(false, 'Should not throw error when supplier is null');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetSObjectTypeFromId() {
        Account acct = createAccount();
        
        // Valid ID
        String typeName = CustomNoteController.exposeGetSObjectTypeFromId(acct.Id);
        System.assertEquals('Account', typeName, 'Should return Account');

        // Null ID
        String nullType = CustomNoteController.exposeGetSObjectTypeFromId(null);
        System.assertEquals(null, nullType, 'Should return null for null input');

    }
}