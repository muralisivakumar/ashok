// Trigger
trigger CustomerInvoiceStatusTrigger on varcpq__Invoice__c (after update) {
    if (!CustomerInvoiceStatusTriggerHelper.skipTrigger) {
        CustomerInvoiceStatusTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}