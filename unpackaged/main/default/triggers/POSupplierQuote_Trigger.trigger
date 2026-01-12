trigger POSupplierQuote_Trigger on varcpq__Purchase_Order__c (after insert) {
    if(trigger.isInsert && trigger.isAfter){
      POSupplierQuoteHandler.fileHandler(trigger.new); 
        System.debug('trigger.new'+trigger.new);
    }
}