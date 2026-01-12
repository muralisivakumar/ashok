@IsTest
private class AvalaraTaxHelper_Test {
    @TestSetup
    
    static void setupTestData() {
        
        Account acc = new Account(
            Name = 'Test Account'
        );	
        Insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = acc.Id);
        insert opp;
        varcpq__Sales_Order__c testSO = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id
        );
        
        insert testSO;
    }
    
    @IsTest
    static void testSalesOrderTaxCalculation() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        Set<Id> recordIds = new Set<Id>{so.Id};
            
            Test.startTest();
        //System.assertEquals(false, AvalaraTaxHelper.isProcessing);
        
        AvalaraTaxHelper helper = new AvalaraTaxHelper(recordIds, 'varcpq__Sales_Order__c');
        //System.enqueueJob(helper);
        
        Test.stopTest();
        
        //System.assertEquals(false, AvalaraTaxHelper.isProcessing);
    }
    
    @IsTest
    static void testInvalidObjectType() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        Set<Id> recordIds = new Set<Id>{so.Id};
            
            Test.startTest();
        AvalaraTaxHelper helper = new AvalaraTaxHelper(recordIds, 'InvalidObject__c');
        System.enqueueJob(helper);
        Test.stopTest();
        
        //System.assertEquals(false, AvalaraTaxHelper.isProcessing);
    }
}