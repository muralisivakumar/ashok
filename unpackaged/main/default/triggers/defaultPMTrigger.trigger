trigger defaultPMTrigger on bt_stripe__Payment_Method__c (After insert) {

    if(trigger.isAfter && trigger.isInsert ){
       defaultPmHandler.paymentMethodDefault(trigger.new); 
    }
    
}