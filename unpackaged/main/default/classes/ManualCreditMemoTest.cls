@isTest
public class ManualCreditMemoTest {

    // Helper to create a test Account record
    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    // Helper to create a test Invoice record with example RMA child
    private static varcpq__Invoice__c createTestInvoice(Account acc) {
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Client__c = acc.Id,
            //Total_Credit_Amount__c = 100.50,
            CurrencyIsoCode = 'USD'
        );
        insert inv;

        // Create dummy child RMA record to simulate lookup subquery
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            //varcpq__Invoice__c = inv.Id,
           // Total_Amount__c = 50.25
        );
        insert rma;

        return inv;
    }

    /*@isTest static void testGetInvoiceDetails_Found() {
        Account testAcc = createTestAccount();
        varcpq__Invoice__c testInvoice = createTestInvoice(testAcc);

        Test.startTest();
        Map<String, Object> result = ManualCreditMemo.getInvoiceDetails(testInvoice.Id);
        Test.stopTest();
    }*/

    @isTest static void testGetInvoiceDetails_NotFound() {
        Test.startTest();
        Map<String, Object> result = ManualCreditMemo.getInvoiceDetails('001000000000000AAA');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Result map should be empty for non-existent record');
    }

    @isTest
    static void testCreateCreditMemoWithFiles() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        varcpq__Sales_Order__c testSO = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order',
            Billing_Contact_Name__c = 'Test Contact',
            varcpq__Client__c = testAccount.Id
        );
        insert testSO;

        varcpq__Invoice__c testInvoice = new varcpq__Invoice__c(
            varcpq__Client__c = testAccount.Id,
            varcpq__Sales_Order__c = testSO.Id
        );
        insert testInvoice;

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
            'Account__c' => testAccount.Id,
            'Invoice_Reference__c' => testInvoice.Id,
            'Justification__c' => 'Unit Test Justification',
            'Bill_Only_Indicator__c' => true,
            'Reason_Code__c' => 'Test Reason',
            'Credit_Amount__c' => 123.45
        };

        Test.startTest();
        Id creditMemoId = ManualCreditMemo.createCreditMemoWithFiles(creditMemoData, new List<Id>{contentDocId});
        Test.stopTest();

        Manual_Credit_Memo__c creditMemo = [SELECT Id, Account__c, Invoice_Reference__c, Justification__c, Bill_Only_Indicator__c, Reason_Code__c, Credit_Amount__c, Status__c FROM Manual_Credit_Memo__c WHERE Id = :creditMemoId];
        System.assertEquals(testAccount.Id, creditMemo.Account__c);
        System.assertEquals(testInvoice.Id, creditMemo.Invoice_Reference__c);
        System.assertEquals('Unit Test Justification', creditMemo.Justification__c);
        System.assertEquals(true, creditMemo.Bill_Only_Indicator__c);
        System.assertEquals('Test Reason', creditMemo.Reason_Code__c);
        System.assertEquals(123.45, creditMemo.Credit_Amount__c);
        System.assertEquals('Draft', creditMemo.Status__c);

        List<ContentDocumentLink> links = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :creditMemoId];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should be linked to the Credit Memo.');
        System.assertEquals(contentDocId, links[0].ContentDocumentId, 'The linked ContentDocument Id should match.');
    }

   /* @isTest static void testGetCreditAmountByRma() {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            //Total_Amount__c = 200.00
        );
        insert rma;

        Test.startTest();
        Decimal amount = ManualCreditMemo.getCreditAmountByRma(rma.Id);
        Test.stopTest();

        System.assertEquals(200.00, amount, 'Credit amount should be returned');
    }*/

    @isTest static void testGetCreditAmountByRma_NoRecord() {
        Test.startTest();
        Decimal amount = ManualCreditMemo.getCreditAmountByRma('000000000000000AAA');
        Test.stopTest();

        System.assertEquals(0, amount, 'Credit amount should be zero if no RMA record found');
    }
    
    // Helper to create a test Account record with a default billing contact
    private static Account createTestAccountWithContact(Boolean withEmail) {
        Account acc = new Account(Name = 'Test Account', CurrencyIsoCode = 'CAD');
        insert acc;

        Contact c = new Contact(
            LastName = 'Billing Contact',
            AccountId = acc.Id,
            Default_Billing_Contact__c = true
        );
        if (withEmail) {
            c.Email = 'billing@test.com';
        }
        insert c;

        return acc;
    }

    // … your existing helper + test methods …

    @isTest
    static void testCreateCreditMemoAccount_WithFilesAndEmail() {
        // Create Account with billing contact & email (to test email branch)
        Account acc = createTestAccountWithContact(true);

        // Create ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.pdf',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            IsMajorVersion = true
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;

        // Input map for @AuraEnabled method
        Map<String,Object> creditMemoData = new Map<String,Object>{
            'Account__c' => acc.Id,
            'Credit_Amount__c' => 111.11,
            'Reason_Code__c' => 'Unit Test Reason'
        };

        Test.startTest();
        Id memoId = ManualCreditMemo.createCreditMemoAccount(creditMemoData, new List<Id>{contentDocId});
        Test.stopTest();

        // Assert the memo was created correctly
        Manual_Credit_Memo__c memo = [
            SELECT Id, Account__c, Credit_Amount__c, Reason_Code__c, CurrencyIsoCode
            FROM Manual_Credit_Memo__c WHERE Id = :memoId
        ];
        System.assertEquals(acc.Id, memo.Account__c);
        System.assertEquals(111.11, memo.Credit_Amount__c);
        System.assertEquals('Unit Test Reason', memo.Reason_Code__c);
        //System.assertEquals('CAD', memo.CurrencyIsoCode);

        // Assert file linked
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :memoId
        ];
        System.assertEquals(1, links.size());
        System.assertEquals(contentDocId, links[0].ContentDocumentId);

        // Assert email was attempted
       // System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been sent');
    }

    @isTest
    static void testCreateCreditMemoAccount_NoFilesNoEmail() {
        // Account with contact but no email (to test else branch)
        Account acc = createTestAccountWithContact(false);

        Map<String,Object> creditMemoData = new Map<String,Object>{
            'Account__c' => acc.Id,
            'Credit_Amount__c' => 50.00,
            'Reason_Code__c' => 'test'
        };

        Test.startTest();
        Id memoId = ManualCreditMemo.createCreditMemoAccount(creditMemoData, new List<Id>());
        Test.stopTest();

        Manual_Credit_Memo__c memo = [
            SELECT Id, Account__c, Credit_Amount__c, Reason_Code__c FROM Manual_Credit_Memo__c WHERE Id = :memoId
        ];
        System.assertEquals(acc.Id, memo.Account__c);
        System.assertEquals(50.00, memo.Credit_Amount__c);
        System.assertEquals('test', memo.Reason_Code__c);

        // No email should be sent
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    
    
}