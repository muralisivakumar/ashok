trigger QuoteLineItemTrigger on QuoteLineItem (after update, after delete) {
    Set<Id> quoteIds = new Set<Id>();

    // Collect Quote IDs from updated or deleted QuoteLineItems
    if (Trigger.isAfter && Trigger.isDelete) {
        for (QuoteLineItem qli : (Trigger.isDelete ? Trigger.old : Trigger.new)) {
            quoteIds.add(qli.QuoteId);
        }

        if (!quoteIds.isEmpty()) {
            // Retrieve Quotes associated with the affected QuoteLineItems
            List<Quote> quotesToValidate = [SELECT Id FROM Quote WHERE Id IN :quoteIds];
            // Call the validation method
            distributorAccountValidationOnQuote.accValidation(quotesToValidate);
        }
    }
}