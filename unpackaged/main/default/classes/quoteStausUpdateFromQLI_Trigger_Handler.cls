/***************************************************************************************************************************************************************************************
* @description       : Product Distributor Mismatched field update on Quote controller for QLI
* @author            : Aress Software - AS
* @Created date      : 30/10/2024
* @related class     : - 
* @trigger           : - 
* @test Class        : - quoteStausUpdateFromQLI_Trigger
* @last modified on  : - 30/10/2024
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class quoteStausUpdateFromQLI_Trigger_Handler {
    
    public static void updateQLI(Map<Id,QuoteLineItem> mapOfIdVsQLI){
        
        set<Id> product = New set<Id>();
        set<Id> quoteId = New set<Id>();
        Map<string,Product2> mapOfDistributerRecordTypeVsProd = New Map<string,Product2>();
        Map<string,Quote> mapOfAccountRecordTypeVsQuote = New Map<string,Quote>();
        List<Quote> quoteToUpdate = New List<Quote>();
        for(QuoteLineItem qliObj : mapOfIdVsQLI.values()){
            product.add(qliObj.Product2Id);
            quoteId.add(qliObj.QuoteId);
        }
        system.debug('product : '+product);
        system.debug('quoteId : '+quoteId);
        for(Product2 prodObj : [SELECT Id,varcpq__Distributor_Account__c,varcpq__Distributor_Account__r.recordType.Name
                                FROM Product2
                                WHERE Id IN : product]){
                                    mapOfDistributerRecordTypeVsProd.put(prodObj.varcpq__Distributor_Account__r.recordType.Name,prodObj);
                                }
        system.debug('mapOfDistributerRecordTypeVsProd : '+mapOfDistributerRecordTypeVsProd);
        
        for(Quote qtObj : [SELECT Id,AccountId,Account.RecordType.Name,QLI_from_different_country__c
                           FROM Quote
                           WHERE Id IN : quoteId]){
                               mapOfAccountRecordTypeVsQuote.put(qtObj.Account.RecordType.Name,qtObj);
                           }
        system.debug('mapOfAccountRecordTypeVsQuote : '+mapOfAccountRecordTypeVsQuote);
        
        for(string str : mapOfAccountRecordTypeVsQuote.keySet()){
            if(!mapOfDistributerRecordTypeVsProd.containsKey(str)){
                system.debug('Record Type Mismatch');
                Quote qtObj = New Quote();
                qtObj.Id = mapOfAccountRecordTypeVsQuote.get(str).Id;
                qtObj.QLI_from_different_country__c = true;
                quoteToUpdate.add(qtObj);
            }else if(mapOfDistributerRecordTypeVsProd.containsKey(str)){
                system.debug('Record Type match');
                Quote qtObj = New Quote();
                qtObj.Id = mapOfAccountRecordTypeVsQuote.get(str).Id;
                qtObj.QLI_from_different_country__c = false;
                quoteToUpdate.add(qtObj);
            }
        }
        system.debug('quoteToUpdate : '+quoteToUpdate);
        if(!quoteToUpdate.isEmpty()){
            Update quoteToUpdate;
        }
    }
}