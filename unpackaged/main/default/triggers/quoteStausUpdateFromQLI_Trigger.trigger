trigger quoteStausUpdateFromQLI_Trigger on QuoteLineItem (after insert, after update) {
    
    if(Trigger.isAfter && (Trigger.isupdate || Trigger.isInsert)){
        System.debug('Its an after update on QLI');
        //if(!QuoteStatusUpdate.flag2){
            //QuoteStatusUpdate.updateQuoteStatusfromQLI(Trigger.new,Trigger.oldMap);
        //}
        quoteStausUpdateFromQLI_Trigger_Handler.updateQLI(Trigger.newMap);        
    }
}