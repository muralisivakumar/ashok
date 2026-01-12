trigger ManualCreditMemoTrigger on Manual_Credit_Memo__c (after update, after insert) {
    
    if (Trigger.isAfter && Trigger.isUpdate)
    {
    ManualCreditMemoTriggerHandler.createCreditMemoHistoryRecords(Trigger.oldMap, Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        ManualCreditMemoTriggerHandler.createRMALineItem(trigger.new);
    }
}