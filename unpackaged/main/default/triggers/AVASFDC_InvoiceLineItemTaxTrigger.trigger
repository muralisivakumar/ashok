trigger AVASFDC_InvoiceLineItemTaxTrigger on varcpq__Invoice_Line_Item__c (before insert, before update) {
    
   // TriggerActivation__mdt triggerconfig = [SELECT ID,MasterLabel,IsActive__c FROM TriggerActivation__mdt WHERE MasterLabel = 'AVASFDC_InvoiceLineItemTaxTrigger'];
    //if( Test.isRunningTest()){ //triggerconfig.IsActive__c ||
     TaxDetailsHandler.processTaxDetails(Trigger.new); 
    //}
   
}