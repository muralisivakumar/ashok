public class createSupplierCreditQueue {

    public static void createQueue(List<Manual_Credit_Memo__c>manualCreditMemos,Map<Id,Manual_Credit_Memo__c>mcmOldMap){
      
        List<Supplier_Credit_Queue__c> suppCreditQueue = new List<Supplier_Credit_Queue__c>();
        List<Supplier_Credit_Queue__c> suppCreditQueueExt = [SELECT Id,Supplier_Credit_Memo__c FROM Supplier_Credit_Queue__c WHERE Supplier_Credit_Memo__c
                                                             IN :mcmOldMap.keySet()];
        Map<Id,Id> scmVsScq = new  Map<Id,Id>();
        
        if(!suppCreditQueueExt.isEmpty()){      
         for(Supplier_Credit_Queue__c scqExt : suppCreditQueueExt){
           scmVsScq.put(scqExt.Supplier_Credit_Memo__c,scqExt.Id);
         }
        }
        
        for(Manual_Credit_Memo__c mcm : manualCreditMemos){
            
            if(mcm.Return_Merchandise_Authorization__c != null && mcm.Status__c == 'Approved' && mcm.Credit_Memo_Type__c == 'Supplier'){
                    if(scmVsScq.containsKey(mcm.Id)){
                        continue;
                    }    
               Supplier_Credit_Queue__c scq = new Supplier_Credit_Queue__c();
                scq.Linked_RMA__c = mcm.Return_Merchandise_Authorization__c;
                scq.Status__c = 'Open';
                scq.CurrencyIsoCode = mcm.CurrencyIsoCode; 
                scq.Supplier__c = mcm.Account__c;
                scq.Supplier_Credit_Memo__c = mcm.Id;
                scq.Credit_Amount__c = mcm.Credit_Amount__c;
                suppCreditQueue.add(scq);
            }
        }
        
        if(!suppCreditQueue.isEmpty()){
            INSERT suppCreditQueue;
        }
    }
}