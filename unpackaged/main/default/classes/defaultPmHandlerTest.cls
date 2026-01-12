@isTest
public class defaultPmHandlerTest {

    @istest
    public Static void createPM(){
        bt_stripe__Payment_Gateway__c pg = new bt_stripe__Payment_Gateway__c();
        pg.Name = 'Test PaymentGateway';
        pg.bt_stripe__Provider__c = 'Authorize.net';
        pg.bt_stripe__Default__c = true;
        pg.bt_stripe__Test_Mode__c = true;
        
        insert pg;  
        System.debug('pg in test class-->'+pg);
       
       Account newAccount = new Account(Name='Test Account');
       insert newAccount;
       System.debug('Account of test Class--->'+newAccount);
       
         //Payment Method Creation
        RecordType rt =[SELECT Id, Name, DeveloperName FROM RecordType WHERE Name = 'Card' AND SObjectType = 'bt_stripe__Payment_Method__c' LIMIT 1];
        bt_stripe__Payment_Method__c pm = new bt_stripe__Payment_Method__c();
        pm.RecordTypeId = rt.Id;
        pm.bt_stripe__Account__c = newAccount.Id;
        pm.bt_stripe__Card_Holder_Name__c = 'Test Card';
        pm.bt_stripe__Card_Expiration_Month__c ='11';
        pm.bt_stripe__Card_Expiration_Year__c ='2030';
        pm.bt_stripe__Card_Number__c ='4111111111111111';
        pm.bt_stripe__Billing_Postal_Code__c = '10001';
        pm.bt_stripe__CVV__c ='111';
        pm.bt_stripe__Payment_Gateway__c =pg.Id;
        pm.bt_stripe__Payment_Method_Status__c ='Valid';
        pm.bt_stripe__Card_Last_4_Digit__c = '1111';
        pm.bt_stripe__Default_Payment_Method__c = true;
        insert pm;
        System.debug('pm of test Class--->'+pm);
        System.debug('pmId of test Class--->'+pm.Id);
        
        bt_stripe__Payment_Method__c PMethod = new bt_stripe__Payment_Method__c();
        PMethod.RecordTypeId = rt.Id;
        PMethod.bt_stripe__Account__c = newAccount.Id;
        PMethod.bt_stripe__Card_Holder_Name__c = 'Test Card New';
        PMethod.bt_stripe__Card_Expiration_Month__c ='12';
        PMethod.bt_stripe__Card_Expiration_Year__c ='2030';
        PMethod.bt_stripe__Card_Number__c ='4111111111111111';
        PMethod.bt_stripe__Billing_Postal_Code__c = '10001';
        PMethod.bt_stripe__CVV__c ='111';
        PMethod.bt_stripe__Payment_Gateway__c =pg.Id;
        PMethod.bt_stripe__Payment_Method_Status__c ='Valid';
        PMethod.bt_stripe__Card_Last_4_Digit__c = '1111';
        PMethod.bt_stripe__Default_Payment_Method__c = true;
        insert PMethod;
        
        
    }
}