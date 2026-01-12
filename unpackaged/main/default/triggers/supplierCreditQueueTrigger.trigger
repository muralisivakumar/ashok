trigger supplierCreditQueueTrigger on Manual_Credit_Memo__c (After Update) {

    if(trigger.isAfter && trigger.isUpdate){
        createSupplierCreditQueue.createQueue(trigger.new,trigger.oldMap);
    }
}