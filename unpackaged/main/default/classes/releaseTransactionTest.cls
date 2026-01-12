@isTest
public class releaseTransactionTest {

    @testSetup
   public static void createTestData(){
       
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
        
        
        Contact newContact = new Contact(LastName = 'lastName', AccountId = newAccount.Id,Email = 'pooja.pawar@aressindia.net');
        insert newContact;
        System.debug('Contact of test Class--->'+newContact);
        
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = newAccount.id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
          System.debug('CustAdd of test Class--->'+add);
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        insert opp;
        System.debug('Opp of test Class--->'+opp);
        
        Quote quote = new Quote(
           
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Bill_to_email__c = 'ashwini.pande@aressindia.net',
            BillingName = 'TestConQuote',
            Quote_Net_Terms__c = 'NET30'
           
        );
        insert quote;
         System.debug('Quote of test Class--->'+quote);
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id,
            SO_Net_Terms__c = 'NET30',
            Pending_Credit_Card_Preauthorization__c = true,
            Captured_Charges__c = 0
            
        );
        insert salesOrderUSD;
        System.debug('SalesOrder of test Class--->'+salesOrderUSD);
        
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
        insert pm;
        System.debug('pm of test Class--->'+pm);
         System.debug('pmId of test Class--->'+pm.Id);     
        
        //Transaction Creation
        Id recTypeId = [SELECT Id, Name, SobjectType, IsActive FROM RecordType where SobjectType = 'bt_stripe__Transaction__c' AND Name = 'Charge' LIMIT 1].Id;
        
        bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();
        tran.CurrencyIsoCode = 'USD';
        tran.RecordTypeId = recTypeId;
        tran.bt_stripe__Amount__c = 100.00;
        tran.bt_stripe__Related_Account__c = newAccount.Id; 
        tran.Quote__c = quote.Id;
        tran.Sales_Order__c = salesOrderUSD.Id;
        //tran.Invoice__c = Inv.Id;
        tran.bt_stripe__Payment_Method__c = pm.Id;
        tran.bt_stripe__Transaction_Status__c = 'Authorized';
        tran.Status_Of_Transaction__c = 'Completed';
        
        Insert tran;
       
        bt_stripe__Transaction__c tra = new bt_stripe__Transaction__c();
        tra.CurrencyIsoCode = 'USD';
        tra.RecordTypeId = recTypeId;
        tra.bt_stripe__Amount__c = 10.00;
        tra.bt_stripe__Related_Account__c = newAccount.Id; 
        tra.Quote__c = quote.Id;
        //tra.Sales_Order__c = salesOrderUSD.Id;
        tran.bt_stripe__Payment_Method__c = pm.Id;
        tra.bt_stripe__Payment_Status__c = 'Authorized';
        
        Insert tra;
      
    }
    @isTest
    public static void testReleaseTransaction(){
        Quote quote = [Select Id,Name From Quote  WHERE Name = 'Test Quote'];
        varcpq__Sales_Order__c salesOrderUSD = [SELECT ID,SO_Net_Terms__c FROM varcpq__Sales_Order__c WHERE  SO_Net_Terms__c = 'NET30' LIMIT 1];
         Test.startTest();
        releaseTransactionsHandler.sOTransactions(quote.Id);
         releaseTransactionsHandler.sOTransactions(salesOrderUSD.Id);
        Test.stopTest();
    }
}