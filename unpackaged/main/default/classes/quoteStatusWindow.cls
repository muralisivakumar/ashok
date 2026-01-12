public class quoteStatusWindow {
    @AuraEnabled
    public static Boolean quoteStatusValidator(Id quoteId){
        Boolean isApproved = False;
        Quote quote = [SELECT Id, Status,Quote_PDF_Count__c  from Quote WHERE id=:quoteId];
        if(quote.Status == 'Approved' && quote.Quote_PDF_Count__c >=1){
            isApproved = True;
        }
        return isApproved;
    }
    @AuraEnabled
    public static void updateStatus(Id quoteId){
        Quote quote = [SELECT Id, Status,Quote_PDF_Count__c  from Quote WHERE id=:quoteId];
        if(quote.Status == 'Approved' && quote.Quote_PDF_Count__c >=1){
            quote.Status = 'Presented';
            update quote;   
        }      
    }
}