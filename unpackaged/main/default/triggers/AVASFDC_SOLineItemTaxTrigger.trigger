trigger AVASFDC_SOLineItemTaxTrigger on varcpq__Sales_Order_Line_Item__c (before insert, before update) {
    TaxDetailsHandler.processTaxDetails(Trigger.new);
}