@isTest
public class CreateAccountController_Test {
	
    @isTest
    public static void test_method(){
        CreateAccountController.getUserProfileName();
        CreateAccountController.getPickListValues();
        CreateAccountController.getAccountRecordTypes();
        
        Account acc = new account();
        acc.Name = 'Test account';
        acc.Type = 'Customer';
        acc.varcpq__NET_TERMS__c = 'NET30';
        CreateAccountController.createAccountRecord(acc);
    }
}