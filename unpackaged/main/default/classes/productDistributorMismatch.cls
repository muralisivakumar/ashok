/***************************************************************************************************************************************************************************************
* @description       : Product Distributor Mismatched field update on Quote controller for Product
* @author            : Aress Software - AS
* @Created date      : 31/10/2024
* @related class     : - 
* @trigger           : - productDistributorMismatch_Trigger
* @test Class        : - 
* @last modified on  : - 31/10/2024
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class productDistributorMismatch {
    public static void updateQuote(List<Product2> prodList){
        Set<Id> prodIds = new Set<Id>();
        for(Product2 prod : prodList){
            prodIds.add(prod.Id);
        }
        List<QuoteLineItem> qliList = [Select Id,QuoteId,Quote.Status, Quote.Account.RecordType.Name,
                                       product2.varcpq__Distributor_Account__r.RecordType.Name 
                                       from Quotelineitem 
                                       where Product2Id=:prodIds];
        System.debug('qliList '+qliList);
        Map<Id,quote> quotemap = new Map<id,quote>();
        List<Quote> quoteList = new List<Quote>();
        for(quoteLineItem qli: qliList){
            Quote quote = new Quote();
            if(qli.Quote.Status != 'Approved'){
                
                if(qli.Quote.Account.RecordType.Name != qli.Product2.varcpq__Distributor_Account__r.RecordType.Name){
                    quote.Id = qli.QuoteId;
                    quote.QLI_from_different_country__c = True;
                    if(!quoteMap.containsKey(qli.QuoteId)){    
                        quoteMap.put(qli.QuoteId,quote);
                        
                    }
                }else{
                    quote.Id = qli.QuoteId;
                    quote.QLI_from_different_country__c = False;
                    quoteMap.put(qli.QuoteId,quote);
                }
                system.debug('quote '+quote);
                
                
            }
            
           
        }
        System.debug('quoteMap '+quoteMap);
                
        for(Id qId: Quotemap.keyset()){
             quoteList.add(quoteMap.get(qId));
        }
        System.debug('quoteList '+quoteList);
        update quoteList;
    }
}