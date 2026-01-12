trigger rmaLineItemTrigger on Return_Merchandise_Authorization_Line_It__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        rmaLineItemTriggerHandler.handleAfterInsert(Trigger.new);
    }
}