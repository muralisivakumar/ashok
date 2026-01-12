/***************************************************************************************************************************************************************************************
* @description       : Product Distributor Mismatched field update on Quote controller for Quote
* @author            : Aress Software - AS
* @Created date      : 29/10/2024
* @related class     : - 
* @test Class        : - 
* @trigger           : - QuoteLineItemTrigger
* @last modified on  : - 31/10/2024
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class distributorAccountValidationOnQuote {
    
    public static Boolean flag = false;
    
    public static void accValidation(List<Quote> quoteList){
        
        Set<String> quoteIds = new Set<String>();
        
        for(Quote qt:quoteList){
            quoteIds.add(qt.Id);
        }
        
        List<Quote> quoteProductList = [SELECT Id, Account.RecordTypeId, QLI_from_different_country__c, (SELECT Id, Product2Id, Product2.varcpq__Distributor_Account__r.RecordTypeId FROM QuoteLineItems) 
                                        FROM Quote WHERE Id =:quoteIds];
        
        Boolean isDiffDistributor = false;
        
        List<Quote> newQuoteList = new list<Quote>();
        
        for(Quote qt :quoteProductList){
            
            Id accRecType = qt.Account.RecordTypeId;
            ///System.debug('accRecType '+accRecType);
            
            if(qt.QuoteLineItems != null){
                for(QuoteLineItem qli :qt.QuoteLineItems){
                    Id qliDistributorRecType = qli.Product2.varcpq__Distributor_Account__r.RecordTypeId;
                    //System.debug('qliDistributorRecType '+qliDistributorRecType);
                    if(qliDistributorRecType != accRecType){
                        isDiffDistributor = true;
                        break;
                    }
                }
            }
            if(qt.QLI_from_different_country__c != isDiffDistributor){
                Quote quote = new Quote();
                quote.Id = qt.Id;
                quote.QLI_from_different_country__c  = isDiffDistributor;
                newQuoteList.add(quote);
            }
        }
        
        if(!newQuoteList.isEmpty()){
            System.debug('DistributorAccountValidationOnQuote '+newQuoteList);
            Update newQuoteList;
            flag = true;
        }
        
    }
    
}