trigger AVASFDC_POLineItemTaxTrigger on varcpq__Purchase_Order_Line_Item__c (before insert, before update) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
      TaxDetailsHandler.processTaxDetails(Trigger.new);   
    }
}