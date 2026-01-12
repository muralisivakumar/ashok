public class QuoteCountryFieldUpdateHandler {
    
    public Static Void updateCountryHandler(List<Quote>quoteList){
       Set<Id> oppIds = new Set<Id>();
        for(Quote objQuote : quoteList ){
           oppIds.add(objQuote.OpportunityId); 
        }
        
    List<Opportunity>oppList = [SELECT ID, AccountId,Account.RecordType.Name FROM Opportunity WHERE Id IN: oppIds];
       Map<Id,String>oppVsAccTypeMap = new Map<Id,String>();       
        for(Opportunity objOpp : oppList){
            if(objOpp.AccountId!=null){
                oppVsAccTypeMap.put(objOpp.Id,objOpp.Account.RecordType.Name);
            }
        }       
        for(Quote objQuote : quoteList ){
            if(oppVsAccTypeMap.ContainsKey(objQuote.OpportunityId)){
              String accountRecordType = oppVsAccTypeMap.get((objQuote.OpportunityId)); 
               if (accountRecordType == 'US Account') {
                objQuote.varcpq__Country__c = 'US';
            } else if (accountRecordType == 'Canadian Account') {
                objQuote.varcpq__Country__c = 'CA';
            }                                        
            }
        }
        
   }    
}