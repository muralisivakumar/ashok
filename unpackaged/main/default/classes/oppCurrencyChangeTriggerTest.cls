@isTest
public class oppCurrencyChangeTriggerTest {

    @testSetup
    static void setupData() {
        //Account Record Type
       List<RecordType> accountRecordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name IN ('US Account', 'Canadian Account')];
        Id usRecordTypeId;
        Id canadianRecordTypeId;
        
         //checking Account Record type is Us Or Canadian
        for (RecordType recordType : accountRecordTypes) {
            if (recordType.Name == 'US Account') {
                usRecordTypeId = recordType.Id;
            } else if (recordType.Name == 'Canadian Account') {
                canadianRecordTypeId = recordType.Id;
            }
        }
        
        //US Account
        Account usAccount = new Account(
            Name = 'US Account',
            RecordTypeId = usRecordTypeId
        );
        insert usAccount;

       //Canadian Account
        Account canadianAccount = new Account(
            Name = 'Canadian Account',
            RecordTypeId = canadianRecordTypeId
        );
        insert canadianAccount;
    }
    
    @isTest
    static void testCurrencyChangeForUSAccount() {
        
        Account usAccount = [SELECT Id FROM Account WHERE Name = 'US Account' LIMIT 1];

        
        Opportunity oppUS = new Opportunity(
            Name = 'Opportunity for US Account',
            AccountId = usAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
        Test.StartTest();
        insert oppUS;
        Test.StopTest();
        
    }

    @isTest
    static void testCurrencyChangeForCanadianAccount() {
       
        Account canadianAccount = [SELECT Id FROM Account WHERE Name = 'Canadian Account' LIMIT 1];

       
        Opportunity oppCAD = new Opportunity(
            Name = 'Opportunity for Canadian Account',
            AccountId = canadianAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
        Test.StartTest();
        insert oppCAD;
        Test.StopTest();
       
    }

}