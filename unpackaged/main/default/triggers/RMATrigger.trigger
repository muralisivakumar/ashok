trigger RMATrigger on Return_Merchandise_Authorization__c (after insert, after update, before delete, after undelete) {   
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        RMATriggerHandler.updateShippingInfo(Trigger.new);
        //RMATriggerHandler.createSupplierCrediMemo(Trigger.New);
        
        Set<Id> rmaIds = new Set<Id>();
        for (Return_Merchandise_Authorization__c r : Trigger.new) {
            rmaIds.add(r.Id);
        }
        if (!rmaIds.isEmpty() && !RMATriggerHandler.hasRunFuture) {
            
            RMATriggerHandler.hasRunFuture = true; 
            RMATriggerHandler.createSupplierCrediMemoFuture(new List<Id>(rmaIds));
        }
    }
    
    if(trigger.isBefore && trigger.isDelete){
        RMATriggerHandler.handleBeforeDelete(trigger.old);
    }
    
    /*if(trigger.isAfter && trigger.isUnDelete){
        RMATriggerHandler.handleAfterUndelete(trigger.new);
    }*/
}