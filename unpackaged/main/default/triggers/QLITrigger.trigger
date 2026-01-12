trigger QLITrigger on QuoteLineItem (before update) {
    for (QuoteLineItem qli : Trigger.new) {
        QuoteLineItem oldQLI = Trigger.oldMap.get(qli.Id);

        // Check if tax line changed and new tax rate is present
        Boolean salesTaxChanged = qli.AVA_SFCLOUD__SalesTax_Line__c != oldQLI.AVA_SFCLOUD__SalesTax_Line__c;
        Boolean hasTaxRate = qli.AVA_SFCLOUD__Sales_Tax_Rate__c != null;

        if (salesTaxChanged && hasTaxRate) {
            qli.varcpq__TAXABLE__c = true;

            if (qli.AVA_SFCLOUD__SalesTax_Line__c != null && qli.AVA_SFCLOUD__SalesTax_Line__c > 0) {
                qli.varcpq__TAX__c = qli.AVA_SFCLOUD__SalesTax_Line__c;
                qli.varcpq__Tax_Rate__c = qli.TaxRateQLI__c;
            } else {
                qli.varcpq__Tax_Rate__c = 0;
                qli.varcpq__TAX__c = qli.AVA_SFCLOUD__SalesTax_Line__c;
            }
        }
    }
}