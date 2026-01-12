trigger invoiceContactTrigger on varcpq__Invoice__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        invoiceContactHandler.handleSOtoInvoiceContact(Trigger.new);
    }
}