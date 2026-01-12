public class releaseTransactionsHandler {
@AuraEnabled
    public static LIST<bt_stripe__Transaction__c> sOTransactions(ID IdOfRecord){
      LIST<bt_stripe__Transaction__c> transactionsToRelease = new  LIST<bt_stripe__Transaction__c>();
      if(IdOfRecord != null){
      String objectApiName = IdOfRecord.getSObjectType().getDescribe().getName();
        if(objectApiName == 'varcpq__Sales_Order__c'){    
       transactionsToRelease = [SELECT ID,Name,Sales_Order__c,bt_stripe__Payment_Status__c,bt_stripe__Amount__c 
                                FROM bt_stripe__Transaction__c WHERE Sales_Order__c =:IdOfRecord AND bt_stripe__Payment_Status__c = 'Authorized'
                                ORDER BY CreatedDate ASC];   
         }else if(objectApiName == 'Quote'){
          transactionsToRelease = [SELECT ID,Name,Sales_Order__c,bt_stripe__Payment_Status__c,bt_stripe__Amount__c,Quote__c 
                                   FROM bt_stripe__Transaction__c WHERE Quote__c =:IdOfRecord AND bt_stripe__Payment_Status__c = 'Authorized'AND Sales_Order__c = null
                                   ORDER BY CreatedDate ASC];   
       }    
     if(!transactionsToRelease.isEmpty()){
            RETURN transactionsToRelease;  
      }
     }
         RETURN NULL;
    }
}