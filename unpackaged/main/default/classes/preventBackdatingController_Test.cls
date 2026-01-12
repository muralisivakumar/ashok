@isTest
public class preventBackdatingController_Test {
    @isTest
    static void testBackdate(){
        Accounting_configuration__c accConfig = new Accounting_configuration__c();
        accConfig.Name = 'Clutch Accounting Config';
        accConfig.Days_AR_Issue_Date_Remain_Open__c = 10;
        accConfig.AP_Closed_Books_Date__c = Date.newInstance(2025,09,31);
        accConfig.Is_Active__c = true;
        Insert accConfig;
        
        Id usRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        Account acc = new Account(Name='Test Account', RecordTypeId=usRecTypeId);
        insert acc;
        
        Contact con = new Contact(FirstName='John', LastName='Doe', Email='john.doe@example.com', AccountId=acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id, StageName='Prospecting', CloseDate=Date.today().addDays(10));
        insert opp;
        varcpq__Sales_Order__c so = new varcpq__Sales_Order__c(
            Name = 'Test SO',
            varcpq__Opportunity__c = opp.Id,
            varcpq__Client__c = acc.Id,
            CurrencyIsoCode = 'USD',
            Billing_Email__c = 'bill@example.com',
            Shipping_Email__c = 'ship@example.com'
        );
        insert so;
        
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Sales_Order__c = so.Id
        );
        insert inv;
        varcpq__Invoice__c inv2 = inv;
        inv2.varcpq__Issued_Date__c = Date.newInstance(2025,20,7);
        update inv2;
        
        
    }
}