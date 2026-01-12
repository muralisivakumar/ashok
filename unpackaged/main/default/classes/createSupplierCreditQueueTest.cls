@isTest
public class createSupplierCreditQueueTest {

    @testSetup
    public static void createTestData(){
    Account acc = new Account();
    acc.Name ='Test Account';
    acc.Type = 'Supplier';
    insert acc;
        
    Account accCust = new Account();
    accCust.Name ='Test Account Customer';
    accCust.Type = 'Customer';
    insert accCust;
  
    
    Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c();
    rma.Account__c = accCust.Id; 
    Insert rma;
        
     Manual_Credit_Memo__c mcm = new Manual_Credit_Memo__c();
     mcm.Credit_Memo_Type__c = 'Supplier';
     mcm.CurrencyIsoCode = 'USD' ;
     mcm.Credit_Amount__c = 10.00;
     mcm.Account__c = acc.Id; 
     mcm.Return_Merchandise_Authorization__c = rma.Id;
     mcm.Reason_Code__c = 'Test Code';
     mcm.Justification__c = 'Test Justification';
     insert mcm;
        
    }
    
    @isTest
    public static void testCreateQueue(){
        List<Manual_Credit_Memo__c> mcm = [SELECT ID, Status__c FROM Manual_Credit_Memo__c];
        mcm[0].Status__c = 'Approved';
        Update mcm;
        
    }
    
    
}