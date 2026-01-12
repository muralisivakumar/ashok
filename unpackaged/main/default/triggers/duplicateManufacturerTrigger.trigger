trigger duplicateManufacturerTrigger on varcpq__Manufacturer__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        duplicateManufacturerTriggerHandler.checkForDuplicates(Trigger.new);
    }
}