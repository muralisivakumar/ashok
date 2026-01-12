public class QuoteApprovedAction {
    @AuraEnabled
    public static Quote getQuoteInfo(Id quoteId){
        if(quoteId!=null){
            Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId FROM Quote WHERE Id=:quoteId];
            return quote;
        }
        return null;
    }
    @AuraEnabled
    public static boolean changeQuoteStatus(Id quoteId,String quoteStat,Boolean isChancetoWin, String lossReason){
        boolean multiQuotes = false;
        if(quoteId!=null){
            Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId,opportunity.StageName FROM Quote WHERE Id=:quoteId];
            Opportunity opp = new Opportunity();
            if(quote.Status == 'Presented' && quote.IsSyncing && quoteStat =='Yes'){
                quote.Status = 'Accepted';
                multiQuotes = checkMultipleQuote(quote.OpportunityId,quote.Id);
            }else if(quote.Status == 'Presented' && quoteStat =='No' && isChancetoWin){
                quote.Status = 'Declined';
            }else if(quote.Status == 'Presented' && quoteStat =='No' && !isChancetoWin){
                quote.Status = 'Declined';
                opp.id = quote.OpportunityId;
                opp.StageName = 'Closed Lost';
                opp.Loss_Reason__c = lossReason;
            }
            if(quote!=null){
                update quote;
            }
            if(opp.Id!=null){
                System.debug('opp -->'+opp);
                update opp;
            }
        }
        return multiQuotes;
    }
    
    
    public static boolean checkMultipleQuote(Id oppId, Id QuoteId){
        List<Quote> quotes = [SELECT Id, opportunityId,Status FROM Quote WHERE OpportunityId =:oppId AND Id !=:QuoteId];
        if(!quotes.isEmpty()){
            return true;
        }
        return false;
    }
    
    @AuraEnabled
    public static void updateOtherQuotes(Id QuoteId){
        Quote quote = [SELECT Id,Name,Status,isSyncing,opportunityId,opportunity.StageName FROM Quote WHERE Id=:quoteId];
        List<Quote> quotes = [SELECT Id, opportunityId,Status FROM Quote WHERE OpportunityId =:quote.OpportunityId AND Id !=:QuoteId];
        List<Quote> newQuotes = new List<Quote>();
        for(Quote qt:quotes){
            if(qt.Status != 'Declined' || qt.Status != 'Sales Order Created'){
                qt.Status = 'Declined';
                newQuotes.add(qt);
            }
        }
        if(!newQuotes.isEmpty()){
            update newQuotes;
        }
    }
    
    @AuraEnabled
    public static list<String> getLossReasons(){
        List<string> picklistvalues = new List<string>();
        
        for( Schema.PicklistEntry pickListVal : Opportunity.Loss_Reason__c.getDescribe().getPicklistValues()){
            picklistvalues.add(pickListVal.getLabel());
        }
        return picklistvalues;
        
    }
    
    /*@AuraEnabled
public static void updateOpportunityStatus(String opportunityId) {

Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

// Update the Opportunity status
opp.StageName = status;

try {
// Update the Opportunity record
update opp;
} catch (DmlException e) {
throw new AuraHandledException('Error updating Opportunity status: ' + e.getMessage());
}
}*/
}