@isTest
public class QuoteCountryFieldUpdateHandlerTest {

    @testSetup
    Public static void createData(){
    
       List<RecordType> accountRecordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND 
                                              Name IN ('US Account', 'Canadian Account')];        
        Id usRecordTypeId;
        Id canadianRecordTypeId;
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
    public static void testQuoteCountryField(){
     Account canadianAccount = [SELECT Id FROM Account WHERE Name = 'Canadian Account' LIMIT 1];
     Account USAccount = [SELECT Id FROM Account WHERE Name ='US Account'  LIMIT 1];   
        
        Opportunity oppCAD = new Opportunity(
            Name = 'Opportunity for Canadian Account',
            AccountId = canadianAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
         insert oppCAD;
        
        Opportunity oppUS = new Opportunity(
            Name = 'Opportunity for US Account',
            AccountId = usAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
         insert oppUS;
        
        Opportunity OpportunityRec = [SELECT ID ,Name From Opportunity Where Name = 'Opportunity for Canadian Account'];
         Opportunity OpportunityRecUs = [SELECT ID ,Name From Opportunity Where Name = 'Opportunity for US Account'];
    
         Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = OpportunityRec.Id
        );
        Quote testQuoteUs = new Quote(
            Name = 'Test Quote',
            OpportunityId = OpportunityRecUs.Id
        );
        Test.StartTest();
        insert testQuote;
        insert testQuoteUs;
        Test.StopTest();
        
    }
}