trigger InvoiceToApiTrigger on varcpq__Invoice_Line_Item__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        InvoiceService.getAccountPayableInvoiceToInvoiceMap(Trigger.new);
    }
}