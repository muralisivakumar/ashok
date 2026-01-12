trigger QuoteLineStateReverter on QuoteLineItem (After Update) {
    if(trigger.isAfter && trigger.isUpdate){
        QuoteStateReverterHandler.quoteLineStateReverter(trigger.new,Trigger.oldMap);
    }
}