/******************************************************************************************************************** 
* Apex Class Name   	: CreateAccountPayableRecordContollerTest
* Created By        	: Nupur Deshmukh
* Created Date      	: 12-05-2025
* Description 			: This Test class is used for get Purchase Order and Case for Creating Account Payable Invoice. 
* Apex Class Reference  : CreateAccountPayableRecordContoller
**********************************************************************************************************************/
@isTest
private class CreateAccountPayableRecordContollerTest {
    
    @isTest
    static void testUpdateCaseOnInvoice() {
        // Step 1: Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone'
        );
        insert testCase;
        
        // Step 2: Create a test Invoice
        varcpq__Accounts_Payable_Invoice__c testInvoice = new varcpq__Accounts_Payable_Invoice__c(
            varcpq__Vendor_Invoice_Number__c = 'INV-1001',
            varcpq__Invoice_Date__c = Date.today(),
            varcpq__Due_Date__c = Date.today().addDays(30)
            // Note: Do not set Case__c yet, it will be set in the method
        );
        insert testInvoice;
        
        // Step 3: Call the method
        Test.startTest();
        CreateAccountPayableRecordContoller.updateCaseOnInvoice(testInvoice.Id, testCase.Id);
        Test.stopTest();
        
        // Step 4: Assert the Invoice was updated with the Case
        varcpq__Accounts_Payable_Invoice__c updatedInvoice = [
            SELECT Id, Case__c FROM varcpq__Accounts_Payable_Invoice__c WHERE Id = :testInvoice.Id
        ];
        System.assertEquals(testCase.Id, updatedInvoice.Case__c, 'Invoice should reference the Case');
        
        // Step 5: Assert the Case was updated with the Invoice
        Case updatedCase = [
            SELECT Id, Accounts_Payable_Invoice__c FROM Case WHERE Id = :testCase.Id
        ];
        System.assertEquals(testInvoice.Id, updatedCase.Accounts_Payable_Invoice__c, 'Case should reference the Invoice');
    }
    
    @isTest
    static void testGetParentObjectType() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone');
        insert testCase;
        
        Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c=true);
        insert newAccount;
        
        Contact newContact = new Contact(LastName = 'lastName', AccountId = newAccount.Id);
        insert newContact;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        insert opp;
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id, 
            varcpq__Billing_Contact__c = newContact.Id
        );
        insert salesOrderUSD;
        
        varcpq__Purchase_Order__c testPO = new varcpq__Purchase_Order__c(varcpq__Distributor_Terms__c = 'NET30' , varcpq__Sales_Order__c = salesOrderUSD.Id);
        insert testPO;
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Map<String, Object> caseResult = CreateAccountPayableRecordContoller.getParentObjectType(testCase.Id);
        System.assertEquals('Case', (String)caseResult.get('parentType'));
        System.assertEquals(testCase.Id, caseResult.get('caseId'));
        
        Map<String, Object> poResult = CreateAccountPayableRecordContoller.getParentObjectType(testPO.Id);
        System.assertEquals('PurchaseOrder', (String)poResult.get('parentType'));
        System.assertEquals(testPO.Id, poResult.get('purchaseOrderId'));
        
        Map<String, Object> noneResult = CreateAccountPayableRecordContoller.getParentObjectType(testAccount.Id);
        System.assertEquals('None', (String)noneResult.get('parentType'));
        System.assert(!noneResult.containsKey('caseId'));
        System.assert(!noneResult.containsKey('purchaseOrderId'));
    }
    @isTest
    static void testUpdateInvoicePOs() {
        // Create required related data
        Account distributor = new Account(Name = 'Test Distributor');
        insert distributor;
        
        Account client = new Account(Name = 'Test Client', varcpq__Available_for_PO__c = true);
        insert client;
        
        Contact billingContact = new Contact(LastName = 'Doe', AccountId = client.Id);
        insert billingContact;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            CurrencyIsoCode = 'USD',
            AccountId = client.Id
        );
        insert opp;
        
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
            Name = 'Sales Order 1',
            varcpq__Opportunity__c = opp.Id,
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = client.Id,
            varcpq__Billing_Contact__c = billingContact.Id
        );
        insert salesOrder;
        
        varcpq__Purchase_Order__c po = new varcpq__Purchase_Order__c(
            varcpq__Distributor_Terms__c = 'NET15',
            varcpq__Sales_Order__c = salesOrder.Id,
            varcpq__Distributor_Name__c = distributor.Id
        );
        insert po;
        
        varcpq__Accounts_Payable_Invoice__c invoice = new varcpq__Accounts_Payable_Invoice__c(
            varcpq__Vendor_Invoice_Number__c = 'AP-001',
            varcpq__Invoice_Date__c = Date.today(),
            varcpq__Due_Date__c = Date.today().addDays(30),
            varcpq__Purchase_Order__c = po.Id
        );
        insert invoice;
        
        // Act
        Test.startTest();
        CreateAccountPayableRecordContoller.updateInvoicePOs(invoice.Id);
        Test.stopTest();
        
        // Assert
        varcpq__Accounts_Payable_Invoice__c updatedInvoice = [
            SELECT Id, varcpq__Supplier__c, Sales_Order__c 
            FROM varcpq__Accounts_Payable_Invoice__c 
            WHERE Id = :invoice.Id
        ];
        System.assertEquals(distributor.Id, updatedInvoice.varcpq__Supplier__c, 'Supplier should be set from PO');
        System.assertEquals(salesOrder.Id, updatedInvoice.Sales_Order__c, 'Sales Order should be set from PO');
    }
}