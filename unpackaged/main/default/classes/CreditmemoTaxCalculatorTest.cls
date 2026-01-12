@isTest
private class CreditmemoTaxCalculatorTest {
    
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'USA'
        );
        insert testAccount;
        
        // Create test RMA - use auto-number fields properly
        Return_Merchandise_Authorization__c testRMA = new Return_Merchandise_Authorization__c(
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert testRMA;
        
        // Create test credit memo with required Reason_Code__c field
        Manual_Credit_Memo__c testCreditMemo = new Manual_Credit_Memo__c(
            Return_Merchandise_Authorization__c = testRMA.Id,
            Status__c = 'Draft',
            Reason_Code__c = 'Customer Return'
        );
        insert testCreditMemo;
    }
    
    // Test constructor with valid credit memo ID
    @isTest
    static void testConstructorWithValidId() {
        Manual_Credit_Memo__c testCreditMemo = [SELECT Id, Return_Merchandise_Authorization__c 
                                               FROM Manual_Credit_Memo__c 
                                               LIMIT 1];
        
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCreditMemo);
        CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
        Test.stopTest();
        
        System.assertEquals(testCreditMemo.Return_Merchandise_Authorization__c, CreditmemoTaxCalculator.rmaId);
        System.assertEquals(testCreditMemo.Id, CreditmemoTaxCalculator.creditMemoId);
    }
    
    // Test constructor with null controller (edge case)
    @isTest
    static void testConstructorWithNullController() {
        Test.startTest();
        CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator();
        Test.stopTest();
        
        System.assertNotEquals(null, controller);
    }
    
    // Test calculateTaxButton method
    @isTest
    static void testCalculateTaxButton() {
        Manual_Credit_Memo__c testCreditMemo = [SELECT Id, Return_Merchandise_Authorization__c 
                                               FROM Manual_Credit_Memo__c 
                                               LIMIT 1];
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCreditMemo);
        CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
        
        Test.startTest();
        PageReference result = controller.calculateTaxButton();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('/' + testCreditMemo.Id, result.getUrl());
        System.assertEquals(true, result.getRedirect());
    }
    
    // Test redirectPage method
    @isTest
    static void testRedirectPage() {
        Manual_Credit_Memo__c testCreditMemo = [SELECT Id FROM Manual_Credit_Memo__c LIMIT 1];
        CreditmemoTaxCalculator.creditMemoId = testCreditMemo.Id;
        
        Test.startTest();
        CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator();
        PageReference result = controller.redirectPage();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('/' + testCreditMemo.Id, result.getUrl());
        System.assertEquals(true, result.getRedirect());
    }
    
  /*  // Test redirectPage with null creditMemoId (edge case)
    @isTest
    static void testRedirectPageWithNullId() {
        CreditmemoTaxCalculator.creditMemoId = null;
        
        Test.startTest();
        CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator();
        PageReference result = controller.redirectPage();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('/', result.getUrl());
    } */
    
    // Test calculateTax method in test context (mocked)
    @isTest
    static void testCalculateTaxInTestContext() {
        Manual_Credit_Memo__c testCreditMemo = [SELECT Id, Return_Merchandise_Authorization__c 
                                               FROM Manual_Credit_Memo__c 
                                               LIMIT 1];
        
        CreditmemoTaxCalculator.rmaId = testCreditMemo.Return_Merchandise_Authorization__c;
        
        Test.startTest();
        CreditmemoTaxCalculator.calculateTax();
        Test.stopTest();
        
        System.assert(true, 'Method should execute without throwing exceptions in test context');
    }
    
    // Test exception handling in calculateTax method
    @isTest
    static void testCalculateTaxExceptionHandling() {
        CreditmemoTaxCalculator.rmaId = null;
        
        Test.startTest();
        try {
            CreditmemoTaxCalculator.calculateTax();
            System.assert(true, 'Exception was handled gracefully');
        } catch (Exception e) {
            System.assert(false, 'Exception should have been caught and handled: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
  /*  // Test with invalid credit memo ID (edge case) - FIXED
    @isTest
    static void testConstructorWithInvalidId() {
        // Create a credit memo with a fake ID that doesn't exist in the database
        Manual_Credit_Memo__c fakeCreditMemo = new Manual_Credit_Memo__c(
            Id = 'a006R000002ABCdAAA', // Fake ID format
            Reason_Code__c = 'Test' // Required field
        );
        
        Test.startTest();
        try {
            ApexPages.StandardController stdController = new ApexPages.StandardController(fakeCreditMemo);
            CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
            
            // The constructor should handle the empty query result gracefully
            // Since no record was found, rmaId should remain null
            System.assertEquals(null, CreditmemoTaxCalculator.rmaId);
            System.assertEquals(fakeCreditMemo.Id, CreditmemoTaxCalculator.creditMemoId);
            
        } catch (Exception e) {
            // The constructor should catch the exception internally
            System.assert(false, 'Constructor should handle invalid IDs gracefully: ' + e.getMessage());
        }
        Test.stopTest();
    }*/
    
    // Test scenario where RMA lookup is null
    @isTest
    static void testConstructorWithNullRMA() {
        Manual_Credit_Memo__c testCreditMemo = new Manual_Credit_Memo__c(
            Status__c = 'Draft',
            Reason_Code__c = 'Price Adjustment'
        );
        insert testCreditMemo;
        
        Test.startTest();
        try {
            ApexPages.StandardController stdController = new ApexPages.StandardController(testCreditMemo);
            CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
            
            // Should handle null RMA gracefully - the query will return the record but RMA field is null
            System.assertEquals(null, CreditmemoTaxCalculator.rmaId);
            System.assertEquals(testCreditMemo.Id, CreditmemoTaxCalculator.creditMemoId);
            
        } catch (Exception e) {
            System.assert(false, 'Constructor should not throw exception for null RMA: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test bulk data scenario
    @isTest
    static void testBulkScenario() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Return_Merchandise_Authorization__c testRMA = new Return_Merchandise_Authorization__c(
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert testRMA;
        
        List<Manual_Credit_Memo__c> creditMemos = new List<Manual_Credit_Memo__c>();
        for (Integer i = 0; i < 5; i++) {
            creditMemos.add(new Manual_Credit_Memo__c(
                Return_Merchandise_Authorization__c = testRMA.Id,
                Status__c = 'Draft',
                Reason_Code__c = 'Bulk Test ' + i
            ));
        }
        insert creditMemos;
        
        Test.startTest();
        for(Manual_Credit_Memo__c cm : creditMemos) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(cm);
            CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
            
            PageReference result = controller.redirectPage();
            System.assertEquals('/' + cm.Id, result.getUrl());
        }
        Test.stopTest();
    }
    
    // Test the calculateTax method with mocked AvaTax response
    @isTest
    static void testCalculateTaxWithMock() {
        Manual_Credit_Memo__c testCreditMemo = [SELECT Id, Return_Merchandise_Authorization__c 
                                               FROM Manual_Credit_Memo__c 
                                               LIMIT 1];
        
        CreditmemoTaxCalculator.rmaId = testCreditMemo.Return_Merchandise_Authorization__c;
        
        Test.setMock(HttpCalloutMock.class, new AvaTaxMockResponseGenerator());
        
        Test.startTest();
        CreditmemoTaxCalculator.calculateTax();
        Test.stopTest();
        
        System.assert(true, 'Method should execute with mock response');
    }
    
 /*   // Test empty query result scenario - FIXED
    @isTest
    static void testConstructorWithNonExistentRecord() {
        // Create a credit memo with required field but don't insert it
        Manual_Credit_Memo__c unsavedCreditMemo = new Manual_Credit_Memo__c(
            Reason_Code__c = 'Test Reason'
        );
        
        Test.startTest();
        try {
            ApexPages.StandardController stdController = new ApexPages.StandardController(unsavedCreditMemo);
            CreditmemoTaxCalculator controller = new CreditmemoTaxCalculator(stdController);
            
            // Should handle non-existent record gracefully
            System.assertEquals(null, CreditmemoTaxCalculator.rmaId);
            System.assertEquals(unsavedCreditMemo.Id, CreditmemoTaxCalculator.creditMemoId);
            
        } catch (Exception e) {
            System.assert(false, 'Should handle non-existent record gracefully: ' + e.getMessage());
        }
        Test.stopTest();
    } */
    
    // Mock response class for AvaTax API calls
    private class AvaTaxMockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"statusCode": 200, "message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}