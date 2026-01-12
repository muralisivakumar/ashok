trigger AVASFDC_RmaLineTaxTrigger on Return_Merchandise_Authorization_Line_It__c (before insert,before update) {
    TaxDetailsHandler.processTaxDetails(Trigger.new); 

}