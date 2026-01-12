/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : QuotelyQLITrigger
* Created By                       : Quotely App Exchange Engineering Team
* Created Date                     : 08-10-2024
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                 Modification ID        Description 
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Quotely App Exchange Engineering 
* Team
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Note: This class/trigger was written by the Quotely Engineering team. Please do not update any instance of the code without consulting the Quotely App Exchange team.
******************************************************************************************************************************************************************************/

trigger QuotelyQLITrigger on QuoteLineItem (before insert) {
    
    if(trigger.isBefore && trigger.isInsert){
        
        List<Pricebook2> pricebooks = [SELECT Id, Name, CurrencyIsoCode FROM Pricebook2 WHERE Name = 'Integration Price Book'];
        System.debug('pricebooks-->' + pricebooks);
        
        Pricebook2 pbook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        Map<String, String> pricebookMap = new Map<String, String>();
        
        for (Pricebook2 pb : pricebooks) {
            pricebookMap.put(pb.CurrencyIsoCode, pb.Id);
        }
        
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        
        for (QuoteLineItem qli : Trigger.new) {
            quoteIds.add(qli.QuoteId);
            prodIds.add(qli.Product2Id);
        }
        
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, CurrencyIsoCode, OpportunityId, Pricebook2Id FROM Quote WHERE Id IN :quoteIds]);
        
        for (Id quo : quoteMap.keySet()) {
            opportunityIds.add(quoteMap.get(quo).OpportunityId);
        }
        
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id IN :opportunityIds]);
        Id quotePriceBookId;
        
        for (Quote quote : quoteMap.values()) {
            if (quote.OpportunityId != null && opportunityMap.containsKey(quote.OpportunityId)) {
                Opportunity opp = opportunityMap.get(quote.OpportunityId);
                //System.debug('opp '+opp);
                if (pricebookMap.containsKey(opp.CurrencyIsoCode)) {
                    quote.Pricebook2Id = pricebookMap.get(opp.CurrencyIsoCode);
                    System.debug('Pricebook2Id --->' + quote.Pricebook2Id);
                    quotePriceBookId = quote.Pricebook2Id;
                    //System.debug('quotePriceBookId -->'+quotePriceBookId);
                }
            }
        }
        
        update quoteMap.values();
        
        List<Product2> prodList = [SELECT Id, Name, varcpq__LISTPRICE__c FROM Product2 WHERE Id IN :prodIds];
        
        Pricebook2 pbookId = [SELECT Id, CurrencyIsoCode FROM Pricebook2 WHERE Id =:quotePriceBookId];
        
        Map<String, PricebookEntry> stdExistingPBEMap = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id, Pricebook2Id, CurrencyIsoCode FROM PricebookEntry WHERE Product2Id IN :prodIds AND Pricebook2Id =: pbook.Id AND CurrencyIsoCode =: pbookId.CurrencyIsoCode]) {
            String compositeKey = pbe.Pricebook2Id + '-' + pbe.Product2Id;
            stdExistingPBEMap.put(compositeKey, pbe);
        } 
        
        System.debug('stdExistingPBEMap -->' + stdExistingPBEMap);
        
        Map<String, PricebookEntry> stdPBEMap = new Map<String, PricebookEntry>();
        
        for (Product2 prod : prodList) {
            String compositeKey = pbook.Id + '-' + prod.Id;
            if (!stdExistingPBEMap.containsKey(compositeKey)) {
                PricebookEntry standardPrice = new PricebookEntry(
                    Pricebook2Id = pbook.Id,
                    Product2Id = prod.Id,
                    UnitPrice = prod.varcpq__LISTPRICE__c,
                    CurrencyIsoCode = pbookId.CurrencyIsoCode,
                    IsActive = true 
                );
                stdPBEMap.put(compositeKey, standardPrice);
            }
        }
        
        if (!stdPBEMap.isEmpty()) {
            Upsert stdPBEMap.values();
        }
        
        Map<String, PricebookEntry> customExistingPBEMap = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id, Pricebook2Id, CurrencyIsoCode FROM PricebookEntry WHERE Product2Id IN :prodIds AND Pricebook2Id = :quotePriceBookId]) {
            String compositeKey = pbe.Pricebook2Id + '-' + pbe.Product2Id;
            customExistingPBEMap.put(compositeKey, pbe);
        }
        
        System.debug('customExistingPBEMap -->' + customExistingPBEMap);
        
        Map<String, PricebookEntry> customPBEMap = new Map<String, PricebookEntry>();
        
        if(Trigger.new.size() == 1 && pbookId.CurrencyIsoCode != 'USD'){
            String compositeKey;
            for (Product2 prod : prodList) {
                compositeKey = pricebookMap.get(pbookId.CurrencyIsoCode) + '-' + prod.Id;
                PricebookEntry customPrice = new PricebookEntry(
                    Pricebook2Id = pricebookMap.get(pbookId.CurrencyIsoCode),
                    IsActive = true,
                    Product2Id = prod.Id,
                    UnitPrice = prod.varcpq__LISTPRICE__c,
                    CurrencyIsoCode = pbookId.CurrencyIsoCode
                );
                customPBEMap.put('compositeKey', customPrice);
            }
            System.debug('customPBEMap-->'+customPBEMap);
            System.debug('customExistingPBEMap-->'+customExistingPBEMap.containsKey(compositeKey));
            if(customExistingPBEMap.containsKey(compositeKey)){
                if(customExistingPBEMap.get(compositeKey).CurrencyIsoCode == customPBEMap.get('compositeKey').CurrencyIsoCode){
                    customPBEMap.clear();
                }
            }
        }
        
        if(Trigger.new.size() > 1 && pbookId.CurrencyIsoCode != 'USD'){
            for (Product2 prod : prodList) {
                String compositeKey = pricebookMap.get(pbookId.CurrencyIsoCode) + '-' + prod.Id;
                if (!customExistingPBEMap.containsKey(compositeKey)) {
                    PricebookEntry customPrice = new PricebookEntry(
                        Pricebook2Id = pricebookMap.get(pbookId.CurrencyIsoCode),
                        IsActive = true,
                        Product2Id = prod.Id,
                        UnitPrice = prod.varcpq__LISTPRICE__c,
                        CurrencyIsoCode = pbookId.CurrencyIsoCode
                    );
                    customPBEMap.put(compositeKey, customPrice);
                }
            }
        }
        
        
        if (!customPBEMap.isEmpty()) {
            Upsert customPBEMap.values();
        }
        
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id, Pricebook2.Name, Pricebook2.CurrencyIsoCode FROM PricebookEntry WHERE Product2Id IN :prodIds AND Pricebook2.Name = 'Integration Price Book' AND Pricebook2.CurrencyIsoCode =:pbookId.CurrencyIsoCode]) {
            pricebookEntryMap.put(pbe.Product2Id, pbe);
        }
        
        for (QuoteLineItem qli : Trigger.new) {
            if(pricebookEntryMap.get(qli.Product2Id).Id != null){
                qli.PricebookEntryId = pricebookEntryMap.get(qli.Product2Id).Id;
            }
        }
    }
}