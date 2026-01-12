trigger QuoteStateReverter on Quote (before update) {
    if(Trigger.isBefore && Trigger.isUpdate){        
       QuoteStateReverterHandler.quoteStateReverter(trigger.new,trigger.oldMap);
        
    }
}