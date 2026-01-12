@isTest
public class searchSupplierCreditQueueTest {

    @testSetup
    public static void createData(){
        
     Datetime dt = Datetime.now();
    Account acc = new Account();
    acc.Name ='Test Account';
    acc.Type = 'Supplier';
    insert acc;
        
    Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c();
       rma.Status__c = 'Approved'; 
       insert rma;
        
       Supplier_Credit_Queue__c scq = new Supplier_Credit_Queue__c();
       scq.Status__c = 'Open';
       scq.Linked_RMA__c = rma.Id;
       scq.Supplier__c = acc.Id;
       scq.Timestamp_Processed__c= dt;
        scq.Timestamp_Received__c = dt;
        insert scq; 
        
        Supplier_Credit_Queue__c scq1 = new Supplier_Credit_Queue__c();
       scq1.Status__c = 'Open';
       scq1.Linked_RMA__c = rma.Id;
       scq1.Supplier__c = acc.Id;
       scq1.Timestamp_Processed__c= dt;
       scq1.Timestamp_Received__c = dt;
       insert scq1;
    }
    
    @isTest
    public static void creditques(){
        
        List<Supplier_Credit_Queue__c> scQueue = [Select Id,Name,Status__c,Supplier__c,CurrencyIsoCode,Linked_RMA__c
                                                  ,Timestamp_Processed__c,Timestamp_Received__c from Supplier_Credit_Queue__c order By Id ASC];
        
 
        string currentUserId = UserInfo.getUserId();
        String supplierId = String.valueOf(scQueue[0].Supplier__c);
        string rmaId = String.valueOf(scQueue[0].Linked_RMA__c);
        List<Id>scqList = new List<Id>();
        scqList.add(scQueue[0].Id);
        Test.startTest();
        searchSupplierCreditQueueHandler.creditQueues('Test Account',scQueue[0].Name,supplierId,scQueue[0].Status__c,rmaId,
                                                    scQueue[0].CurrencyIsoCode,currentUserId,scQueue[0].Timestamp_Processed__c,
                                                    scQueue[0].Timestamp_Received__c);
        
        /*searchSupplierCreditQueueHandler.loadMoreData(scQueue[0].Id,'Test Account',scQueue[0].Name,supplierId,scQueue[0].Status__c,rmaId,
                                                    scQueue[0].CurrencyIsoCode,currentUserId,scQueue[0].Timestamp_Processed__c,
                                                    scQueue[0].Timestamp_Received__c);*/
        
        searchSupplierCreditQueueHandler.updateStatus(scqList, 'Applied');
        Test.stopTest();
    }
    
    
    
}