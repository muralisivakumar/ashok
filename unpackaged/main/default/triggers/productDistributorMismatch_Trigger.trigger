trigger productDistributorMismatch_Trigger on Product2 (After update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        productDistributorMismatch.updateQuote(Trigger.new);
    }
}