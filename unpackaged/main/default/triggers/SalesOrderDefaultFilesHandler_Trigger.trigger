trigger SalesOrderDefaultFilesHandler_Trigger on QuoteLineItem (After Insert) {
    if(Trigger.isInsert && Trigger.isAfter){
        SalesOrderDefaultFilesHandler.triggerHandler(Trigger.new);
    }
}