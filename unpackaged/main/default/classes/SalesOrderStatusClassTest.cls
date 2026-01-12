@isTest
public class SalesOrderStatusClassTest {

     @testSetup
   public static void setupTestData() {
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
            varcpq__Stage__c = 'Send Sales Order to Customer',
            varcpq__Billing_Contact__c = newContact.Id
        );
        insert salesOrderUSD;
    }
    
    @istest
    public static void CheckSoStatus(){
         varcpq__Sales_Order__c SO = [SELECT ID,Name,varcpq__Stage__c FROM varcpq__Sales_Order__c WHERE Name =: 'Test Sales Order USD'];
              
        SalesOrderStatusClass.changeSoStatus(SO.Id);    
        
    }
    
}