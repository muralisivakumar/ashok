trigger CustomerAddressTrigger on varcpq__Customer_Address__c (after insert, after update) {
    if (Trigger.isAfter) {
        new AddressValidator().handleDefaultAddresses(Trigger.new, Trigger.oldMap);
    }
}