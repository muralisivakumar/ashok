//AuthTransactionTrigger Marks SO CheckBox to false When Transaction gets Authorized Successfully When we send Authlink to customer.

trigger AuthTransactionTrigger on bt_stripe__Transaction__c (After Update) {
    
    if(trigger.isAfter && trigger.isUpdate){
      transactionProcessingHandler.updateSOAuthLink(trigger.new,trigger.oldMap);  
    }
    
    
    
    
    
}