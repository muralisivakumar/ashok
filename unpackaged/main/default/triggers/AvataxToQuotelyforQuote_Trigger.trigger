trigger AvataxToQuotelyforQuote_Trigger on Quote (After update) {
    
    if(Trigger.isAfter && Trigger.isUpdate){
        if(!distributorAccountValidationOnQuote.flag){
            //AvataxToQuotelyforQuote.updateQuotelyFields(Trigger.new,Trigger.oldMap);
            distributorAccountValidationOnQuote.accValidation(Trigger.new);
        }
    }
}