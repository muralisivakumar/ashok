/***************************************************************************************************************************************************************************************
* @description       : Trigger controller for updating Quotely fields with avatax values on Quote
* @author            : Aress Software - AS
* @Created date      : 29/10/2024
* @related class     : - 
* @test Class        : - AvaTaxToQuotelyforQuoteTest
* @last modified on  : - 11/06/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class AvataxToQuotelyforQuote {
    
    public static void updateQuotelyFields(List<Quote> newQuotes,Map<Id, Quote> oldQuoteMap) {
        
        System.debug('avataxtoqtly trigger NEW ' + newQuotes);
        
        Set<Id> quoteIds = new Set<Id>();
        for (Quote q : newQuotes) {
            if (q.Tax != oldQuoteMap.get(q.Id).Tax) {
                quoteIds.add(q.Id);
            }
        }
        if (quoteIds.isEmpty()) return;   
        
        List<Quote> quotesWithQLI = [
            SELECT Id, Tax,
            (SELECT Id, AVA_SFCLOUD__Sales_Tax_Rate__c,varcpq__TAX__c                  
             FROM QuoteLineItems
             WHERE AVA_SFCLOUD__Sales_Tax_Rate__c != null)
            FROM Quote
            WHERE Id IN :quoteIds
        ];
        
        List<Quote> updatedQuote = new List<Quote>();
        
        for (Quote q : quotesWithQLI) {
            
            Decimal bestRate = 0;                     
            for (QuoteLineItem qli : q.QuoteLineItems) {
                //if (qli.varcpq__TAX__c == 0) continue;     
                if (String.isBlank(qli.AVA_SFCLOUD__Sales_Tax_Rate__c)) continue;
                
                Decimal rate = Decimal.valueOf(
                    qli.AVA_SFCLOUD__Sales_Tax_Rate__c.replace('%','')
                );
                
                if (rate > 0 && (bestRate == 0 || rate > bestRate)) {
                    bestRate = rate;                   // keep the highest non-zero
                }
            }
            
            
            updatedQuote.add(new Quote(
                Id = q.Id,
                varcpq__Total_Tax__c = q.Tax,
                varcpq__Tax_Rate__c  = bestRate
            ));
            
        }
        
        
        if (!updatedQuote.isEmpty()) {
            update updatedQuote;
        }
    }
}

/*public class AvataxToQuotelyforQuote {

public static void updateQuotelyFields(List<Quote> quoteList, Map<Id,Quote> oldQuoteMap){
System.debug('avataxtoqtly trigger new '+quoteList);
List<Quote> newQuoteList = new list<Quote>();
Set<Id> qtIds = new Set<Id>();
for(quote qt : quoteList){
if(qt.Tax != oldQuoteMap.get(qt.Id).Tax){
qtIds.add(qt.Id);
}
}
List<Quote> qtWithQli = [SELECT Id, Tax, varcpq__Tax_Rate__c, varcpq__Total_Tax__c,
(Select Id,AVA_SFCLOUD__Sales_Tax_Rate__c from QuoteLineItems limit 1) 
FROM Quote 
WHERE Id=:qtIds];

for(quote qt:qtWithQli){
System.debug(qt.varcpq__Total_Tax__c);
if(qt.QuoteLineItems != null){
System.debug(qt.varcpq__Total_Tax__c);
for(QuoteLineItem qli:qt.QuoteLineItems){
System.debug(qt.varcpq__Total_Tax__c);

Quote newQuote = new Quote();
newQuote.Id = qt.Id;
newQuote.varcpq__Total_Tax__c = qt.Tax;

String taxRate = qli.AVA_SFCLOUD__Sales_Tax_Rate__c;
taxRate = taxRate.removeEnd('%');
newQuote.varcpq__Tax_Rate__c = Decimal.valueOf(taxRate);
System.debug(newQuote);

newQuoteList.add(newQuote);

}
}
}
if(!newQuoteList.isEmpty()){
update newQuoteList;
}
}
}*/