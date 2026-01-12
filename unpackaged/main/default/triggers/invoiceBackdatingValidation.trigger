trigger invoiceBackdatingValidation on varcpq__Invoice__c (before update) {
    List<varcpq__invoice__c> invoices = new List<varcpq__invoice__c>();
    for(varcpq__invoice__c invoice: Trigger.new){
        if(Trigger.oldmap.get(invoice.Id).varcpq__Issued_Date__c != invoice.varcpq__Issued_Date__c && !invoice.Issue_Date_Override__c){
            invoices.add(invoice);
        }
    }
    preventBackdatingController.invoiceBackdating(Invoices);
}