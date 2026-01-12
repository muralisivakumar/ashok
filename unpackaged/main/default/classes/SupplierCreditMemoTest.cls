@isTest
public class SupplierCreditMemoTest {
    
    // Helper to create Supplier (Account)
    private static Account createTestSupplier() {
        Account acc = new Account(Name = 'Test Supplier');
        insert acc;
        return acc;
    }
    
    // Helper to create Sales Order
    private static varcpq__Sales_Order__c createTestSalesOrder(Account supplier) {
        varcpq__Sales_Order__c so = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order',
            varcpq__Client__c = supplier.Id,
            varcpq__Billing_City__c = 'Test City',
            varcpq__Billing_Street__c = '123 Test St',
            Billing_Contact_Name__c = 'Billing Contact',
            Billing_Email__c = 'billing@example.com',
            Billing_Phone__c = '1234567890'
        );
        insert so;
        return so;
    }
    
    // Helper to create Invoice with Sales Order lookup
    private static varcpq__Invoice__c createTestInvoice(Account supplier, varcpq__Sales_Order__c so) {
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Client__c = supplier.Id,
            varcpq__Sales_Order__c = so.Id
            //Total_Credit_Amount__c = 500
        );
        insert inv;
        return inv;
    }
    
    // Helper to create Accounts Payable Invoice
    private static varcpq__Accounts_Payable_Invoice__c createTestAPInvoice(Account supplier, Id invoiceId) {
        varcpq__Accounts_Payable_Invoice__c apinv = new varcpq__Accounts_Payable_Invoice__c(
            varcpq__Supplier__c = supplier.Id,
            CurrencyIsoCode = 'USD',
            Invoice__c = invoiceId
        );
        insert apinv;
        return apinv;
    }
    
    // Helper to create RMA
    private static Return_Merchandise_Authorization__c createTestRMA(Id relatedInvoiceId) {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            Related_Invoice__c = relatedInvoiceId
            //Total_Amount__c = 250
        );
        insert rma;
        return rma;
    }
    
    @isTest
    static void testGetAPInvoiceDetails_withSalesOrder() {
        Account supplier = createTestSupplier();
        varcpq__Sales_Order__c so = createTestSalesOrder(supplier);
        varcpq__Invoice__c invoice = createTestInvoice(supplier, so);
        varcpq__Accounts_Payable_Invoice__c apInvoice = createTestAPInvoice(supplier, invoice.Id);
        Return_Merchandise_Authorization__c rma = createTestRMA(invoice.Id);
        
        Test.startTest();
        Map<String, Object> result = SupplierCreditMemo.getAPInvoiceDetails(apInvoice.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetAPInvoiceDetails_NotFound() {
        Test.startTest();
        Map<String, Object> result = SupplierCreditMemo.getAPInvoiceDetails('001000000000000AAA');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Result map should be empty for non-existent record');
    }
    
    @isTest
    static void testCreateAPCreditMemoWithFiles() {
        Account testSupplier = createTestSupplier();
        varcpq__Sales_Order__c testSO = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order',
            Billing_Contact_Name__c = 'Test Contact',
            varcpq__Client__c = testSupplier.Id
        );
        insert testSO;
        
        varcpq__Invoice__c testInvoice = new varcpq__Invoice__c(
            varcpq__Client__c = testSupplier.Id,
            varcpq__Sales_Order__c = testSO.Id
        );
        insert testInvoice;
        
        varcpq__Accounts_Payable_Invoice__c testAPInvoice = createTestAPInvoice(testSupplier, testInvoice.Id);
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.pdf',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id contentDocId = insertedCv.ContentDocumentId;
        
        Map<String, Object> creditMemoData = new Map<String, Object>{
            'Account__c' => testSupplier.Id,
            'Invoice_Reference__c' => testInvoice.Id,
            'Justification__c' => 'Unit Test Justification',
            'Bill_Only_Indicator__c' => true,
            'Reason_Code__c' => 'Test Reason',
            'Credit_Amount__c' => 123.45,
            'Accounts_Payable_Invoice__c' => testAPInvoice.Id
        };
        
        Test.startTest();
        Id creditMemoId = SupplierCreditMemo.createAPCreditMemoWithFiles(creditMemoData, new List<Id>{contentDocId});
        Test.stopTest();
        
        Manual_Credit_Memo__c creditMemo = [SELECT Id, Account__c, Invoice_Reference__c, Justification__c, Bill_Only_Indicator__c,
            Reason_Code__c, Credit_Amount__c, Status__c, Credit_Memo_Type__c, Accounts_Payable_Invoice__c
            FROM Manual_Credit_Memo__c WHERE Id = :creditMemoId];
        
        System.assertEquals(testSupplier.Id, creditMemo.Account__c);
        System.assertEquals(testInvoice.Id, creditMemo.Invoice_Reference__c);
        System.assertEquals('Unit Test Justification', creditMemo.Justification__c);
        System.assertEquals(true, creditMemo.Bill_Only_Indicator__c);
        System.assertEquals('Test Reason', creditMemo.Reason_Code__c);
        System.assertEquals(123.45, creditMemo.Credit_Amount__c);
        System.assertEquals('Supplier', creditMemo.Credit_Memo_Type__c);
        System.assertEquals(testAPInvoice.Id, creditMemo.Accounts_Payable_Invoice__c);
        System.assertEquals('Draft', creditMemo.Status__c);
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :creditMemoId];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should be linked to the Credit Memo.');
        System.assertEquals(contentDocId, links[0].ContentDocumentId, 'The linked ContentDocument Id should match.');
    }
    
    @isTest
    static void testGetCreditAmountByRma() {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
           // Total_Amount__c = 200.00
        );
        insert rma;
        
        Test.startTest();
        Decimal amount = SupplierCreditMemo.getCreditAmountByRma(rma.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetCreditAmountByRma_NoRecord() {
        Test.startTest();
        Decimal amount = SupplierCreditMemo.getCreditAmountByRma('000000000000000AAA');
        Test.stopTest();
        
        System.assertEquals(0, amount);
    }
}



/*@isTest
public class SupplierCreditMemoTest {
    
    // Helper to create a test Account (Supplier) record
    private static Account createTestSupplier() {
        Account acc = new Account(Name = 'Test Supplier');
        insert acc;
        return acc;
    }
    
    // Helper to create test AP Invoice record with related Invoice lookup
    private static varcpq__Accounts_Payable_Invoice__c createTestAPInvoice(Account supplier, Id invoiceId) {
        varcpq__Accounts_Payable_Invoice__c apinv = new varcpq__Accounts_Payable_Invoice__c(
            varcpq__Supplier__c = supplier.Id,
            CurrencyIsoCode = 'USD',
            Invoice__c = invoiceId
        );
        insert apinv;
        return apinv;
    }
    
    // Helper to create test Invoice for linking to AP Invoice
    private static varcpq__Invoice__c createTestInvoice(Account supplier) {
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Client__c = supplier.Id
            //Total_Credit_Amount__c = 500
        );
        insert inv;
        return inv;
    }
    
    // Helper to create Return Merchandise Authorization record
    private static Return_Merchandise_Authorization__c createTestRMA(Id relatedInvoiceId) {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            Related_Invoice__c = relatedInvoiceId
           // Total_Amount__c = 250
        );
        insert rma;
        return rma;
    }
    
   /* @isTest
    static void testGetAPInvoiceDetails_Found() {
        Account testSupplier = createTestSupplier();
        varcpq__Invoice__c testInvoice = createTestInvoice(testSupplier);
        varcpq__Accounts_Payable_Invoice__c testAPInvoice = createTestAPInvoice(testSupplier, testInvoice.Id);
        Return_Merchandise_Authorization__c testRMA = createTestRMA(testInvoice.Id);
        
        Test.startTest();
        //Map<String, Object> result = SupplierCreditMemo.getAPInvoiceDetails(testAPInvoice.Id);
        Test.stopTest();
    }*/
    
    /*@isTest
    static void testGetAPInvoiceDetails_NotFound() {
        Test.startTest();
        Map<String, Object> result = SupplierCreditMemo.getAPInvoiceDetails('001000000000000AAA');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Result map should be empty for non-existent record');
    }
    
    @isTest
    static void testCreateAPCreditMemoWithFiles() {
        Account testSupplier = createTestSupplier();
        varcpq__Sales_Order__c testSO = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order',
            Billing_Contact_Name__c = 'Test Contact',
            varcpq__Client__c = testSupplier.Id
        );
        insert testSO;
        
        varcpq__Invoice__c testInvoice = new varcpq__Invoice__c(
            varcpq__Client__c = testSupplier.Id,
            varcpq__Sales_Order__c = testSO.Id
        );
        insert testInvoice;
        
        varcpq__Accounts_Payable_Invoice__c testAPInvoice = createTestAPInvoice(testSupplier, testInvoice.Id);
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.pdf',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id contentDocId = insertedCv.ContentDocumentId;
        
        Map<String, Object> creditMemoData = new Map<String, Object>{
            'Account__c' => testSupplier.Id,
            'Invoice_Reference__c' => testInvoice.Id,
            'Justification__c' => 'Unit Test Justification',
            'Bill_Only_Indicator__c' => true,
            'Reason_Code__c' => 'Test Reason',
            'Credit_Amount__c' => 123.45,
            'Accounts_Payable_Invoice__c' => testAPInvoice.Id
        };
        
        Test.startTest();
        Id creditMemoId = SupplierCreditMemo.createAPCreditMemoWithFiles(creditMemoData, new List<Id>{contentDocId});
        Test.stopTest();
        
        Manual_Credit_Memo__c creditMemo = [SELECT Id, Account__c, Invoice_Reference__c, Justification__c, Bill_Only_Indicator__c,
            Reason_Code__c, Credit_Amount__c, Status__c, Credit_Memo_Type__c, Accounts_Payable_Invoice__c
            FROM Manual_Credit_Memo__c WHERE Id = :creditMemoId];
        
        System.assertEquals(testSupplier.Id, creditMemo.Account__c);
        System.assertEquals(testInvoice.Id, creditMemo.Invoice_Reference__c);
        System.assertEquals('Unit Test Justification', creditMemo.Justification__c);
        System.assertEquals(true, creditMemo.Bill_Only_Indicator__c);
        System.assertEquals('Test Reason', creditMemo.Reason_Code__c);
        System.assertEquals(123.45, creditMemo.Credit_Amount__c);
        System.assertEquals('Supplier', creditMemo.Credit_Memo_Type__c);
        System.assertEquals(testAPInvoice.Id, creditMemo.Accounts_Payable_Invoice__c);
        System.assertEquals('Draft', creditMemo.Status__c);
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :creditMemoId];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should be linked to the Credit Memo.');
        System.assertEquals(contentDocId, links[0].ContentDocumentId, 'The linked ContentDocument Id should match.');
    }
    
   @isTest
    static void testGetCreditAmountByRma() {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
           // Total_Amount__c = 200.00
        );
        insert rma;
        
        Test.startTest();
        Decimal amount = SupplierCreditMemo.getCreditAmountByRma(rma.Id);
        Test.stopTest();
        
        //System.assertEquals(200.00, amount, 'Credit amount should be returned');
    }
    
    @isTest
    static void testGetCreditAmountByRma_NoRecord() {
        Test.startTest();
        Decimal amount = SupplierCreditMemo.getCreditAmountByRma('000000000000000AAA');
        Test.stopTest();
        
        System.assertEquals(0, amount, 'Credit amount should be zero if no RMA record found');
    }
}*/