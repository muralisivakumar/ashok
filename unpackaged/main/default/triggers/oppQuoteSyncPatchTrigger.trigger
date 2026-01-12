trigger oppQuoteSyncPatchTrigger on OpportunityLineItem (After insert,After update,After delete, before delete) {
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        oppQuoteSyncPatch.syncPatchup(Trigger.new);
    }
    if(Trigger.isAfter && trigger.isDelete){
        System.debug(trigger.old);
        System.debug(trigger.old[0].opportunityId);
        if (Trigger.isAfter && Trigger.isDelete) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : Trigger.old) {
            oppIds.add(oli.OpportunityId);
        }
        if (!oppIds.isEmpty()) {
            System.enqueueJob(new UpdateOLIsFromQuoteQueueable(new List<Id>(oppIds)));
        }
    }
    }
}