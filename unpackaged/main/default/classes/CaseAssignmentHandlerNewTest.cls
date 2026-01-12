@isTest
private class CaseAssignmentHandlerNewTest {
    @isTest
    static void testCaseAssignment() {
        // Create test case with known rule conditions
        Case testCase = new Case(
            Subject = 'Test Case',
            Queue__c = 'Multiple', // Starting with different queue
            Category__c = 'Unable to Categorize',
            Status = 'New'
        );
        insert testCase;
        
        // Update case to trigger assignment
        testCase.Queue__c = 'Operations US';
        testCase.Category__c = 'Amazon';
        
        Test.startTest();
        update testCase;
        Test.stopTest();
        
        // Verify case was processed and assigned to the correct user
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('005al000002lKAD', updatedCase.OwnerId, 
            'Case should have been assigned to the specified user');
    }
    
    @isTest
    static void testInvoicePostedToQuickBooksAssignment() {
        // Query the existing Customer Billings Queue
        Group customerBillingsQueue = [SELECT Id FROM Group 
                         WHERE DeveloperName = 'Customer_Billings' 
                         AND Type = 'Queue' 
                         LIMIT 1];
        
        // Create test case
        Case testCase = new Case(
            Queue__c = 'Accounting US',
            Category__c = 'Supplier Invoice and Credit Memo Management',
            Subject = 'Test Invoice Case',
            Status = 'New',
            Invoice_Posted_to_QuickBooks__c = false
        );
        insert testCase;
        
        // Update both Queue__c and Invoice_Posted_to_QuickBooks__c to trigger the assignment
        testCase.Queue__c = 'Accounting US';  // Change to same value to trigger field change
        testCase.Invoice_Posted_to_QuickBooks__c = true;
        
        Test.startTest();
        update testCase;
        Test.stopTest();
        
        // Verify case was assigned to Customer_Billings queue
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(customerBillingsQueue.Id, updatedCase.OwnerId, 
            'Case should have been assigned to Customer Billings queue');
    }
    
    // Adding new test method for invoice assignment without queue change
    @isTest
    static void testInvoicePostedToQuickBooksAssignmentWithoutQueueChange() {
        // Query the existing Customer Billings Queue
        Group customerBillingsQueue = [SELECT Id FROM Group 
                         WHERE DeveloperName = 'Customer_Billings' 
                         AND Type = 'Queue' 
                         LIMIT 1];
        
        // Create test case
        Case testCase = new Case(
            Queue__c = 'Accounting US',
            Category__c = 'Supplier Invoice and Credit Memo Management',
            Subject = 'Test Invoice Case',
            Status = 'New',
            Invoice_Posted_to_QuickBooks__c = false
        );
        insert testCase;
        
        // Only update Invoice_Posted_to_QuickBooks__c
        testCase.Invoice_Posted_to_QuickBooks__c = true;
        
        Test.startTest();
        update testCase;
        Test.stopTest();
        
        // Verify case was assigned to Customer_Billings queue even without queue change
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(customerBillingsQueue.Id, updatedCase.OwnerId, 
            'Case should have been assigned to Customer Billings queue even without queue change');
    }
}