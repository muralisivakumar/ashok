/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : SalesOrderTrigger
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

trigger SalesOrderTrigger on varcpq__Sales_Order__c (before insert, after update) {
    
    if(trigger.isBefore && trigger.isInsert){
        
        Set<Id> opportunityIds = new Set<Id>();
        for(varcpq__Sales_Order__c SO : Trigger.new) {
            opportunityIds.add(SO.varcpq__Opportunity__c);
        }
        
        Map<Id,String> oppIsoCode = new Map<Id,String>();
        for(Opportunity opp: [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id IN:opportunityIds]){
            oppIsoCode.put(opp.Id,opp.CurrencyIsoCode);
        }
        
        for(varcpq__Sales_Order__c SO : Trigger.new) {
            SO.CurrencyIsoCode = oppIsoCode.get(SO.varcpq__Opportunity__c);
        }
    }
    
    if (Schema.SObjectType.varcpq__Sales_Order__c.fields.getMap().containsKey('CurrencyIsoCode')) {
        
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> parentIds = new Set<Id>();
            Set<String> currencies = new Set<String>();
            Map<String, Decimal> exchangeRates = new Map<String, Decimal>();

            for(varcpq__Sales_Order__c parent : Trigger.new) {
                varcpq__Sales_Order__c oldParent = Trigger.oldMap.get(parent.Id);
                String newCurrencyIsoCode = (String) parent.get('CurrencyIsoCode');
                String oldCurrencyIsoCode = (String) oldParent.get('CurrencyIsoCode');
                
                if (newCurrencyIsoCode != oldCurrencyIsoCode) {
                    parentIds.add(parent.Id);
                    currencies.add(newCurrencyIsoCode);    
                    currencies.add(oldCurrencyIsoCode); 
                }
            }
            System.debug('Currencies involved: ' + currencies);
            System.debug('parentIds-->'+parentIds);
            
            if (!parentIds.isEmpty()) {
                List<varcpq__Sales_Order_Line_Item__c> children = [SELECT Id, Name, varcpq__Sales_Order__c, varcpq__Unit_Cost__c, varcpq__Unit_Price__c, varcpq__Total_Ext_Cost__c, varcpq__Total_Ext_Price__c, varcpq__List_Price__c, 
                                                                   varcpq__Contract_Fee__c, varcpq__Ext_Margin__c, varcpq__Total_Tax__c FROM varcpq__Sales_Order_Line_Item__c WHERE varcpq__Sales_Order__c IN :parentIds];
                
                List<varcpq__Sales_Order__c> parentRecords = [SELECT Id FROM varcpq__Sales_Order__c WHERE Id IN :parentIds];
                
                String query = 'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode IN :currencies';
                List<SObject> rates = Database.query(query);
                
                for (SObject rate : rates) {
                    String isoCode = (String) rate.get('IsoCode');
                    Decimal conversionRate = (Decimal) rate.get('ConversionRate');
                    exchangeRates.put(isoCode, conversionRate);
                }
                System.debug('Exchange rate map: ' + exchangeRates);
                
                for (varcpq__Sales_Order_Line_Item__c child : children) {
                    varcpq__Sales_Order__c parent = Trigger.newMap.get(child.varcpq__Sales_Order__c);
                    varcpq__Sales_Order__c oldParent = Trigger.oldMap.get(child.varcpq__Sales_Order__c);
                    
                    String parentNewCurrency = (String) parent.get('CurrencyIsoCode');
                    String parentOldCurrency = (String) oldParent.get('CurrencyIsoCode');
                    
                    if (exchangeRates.containsKey(parentOldCurrency) && exchangeRates.containsKey(parentNewCurrency)) {
                        Decimal oldRate = exchangeRates.get(parentOldCurrency);
                        Decimal newRate = exchangeRates.get(parentNewCurrency);
                        System.debug('Old Rate: ' + oldRate + ', New Rate: ' + newRate);
                        
                        if (oldRate != null && newRate != null) {
                            if(child.varcpq__Unit_Cost__c != null){
                                child.varcpq__Unit_Cost__c = (child.varcpq__Unit_Cost__c / oldRate) * newRate;
                            }
                            if(child.varcpq__Unit_Price__c != null){
                                child.varcpq__Unit_Price__c = (child.varcpq__Unit_Price__c / oldRate) * newRate;
                            }
                            if(child.varcpq__List_Price__c != null){
                                child.varcpq__List_Price__c = (child.varcpq__List_Price__c / oldRate) * newRate;
                            }
                            if(child.varcpq__Contract_Fee__c != null){
                                child.varcpq__Contract_Fee__c = (child.varcpq__Contract_Fee__c / oldRate) * newRate;
                            }
                        }
                    }
                    child.put('CurrencyIsoCode', parentNewCurrency);
                }
                
                if (!children.isEmpty()) {
                    update children;  
                }
            }
        }
    }
    
}