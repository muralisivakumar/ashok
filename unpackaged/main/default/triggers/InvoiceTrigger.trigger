/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : InvoiceTrigger
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

trigger InvoiceTrigger on varcpq__Invoice__c (after update, before insert) {
    
    if(trigger.isBefore && trigger.isInsert){
        
        Set<Id> InvIds = new Set<Id>();
        for(varcpq__Invoice__c Inv : Trigger.new) {
            InvIds.add(Inv.varcpq__Sales_Order__c);
        }
        
        Map<Id,String> soIsoCode = new Map<Id,String>();
        for(varcpq__Sales_Order__c so: [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE Id IN:InvIds]){
            soIsoCode.put(so.Id,so.CurrencyIsoCode);
        }
        
        for(varcpq__Invoice__c Inv : Trigger.new) {
            Inv.CurrencyIsoCode = soIsoCode.get(Inv.varcpq__Sales_Order__c);
        }
    }
    
    if (Schema.SObjectType.varcpq__Invoice__c.fields.getMap().containsKey('CurrencyIsoCode')) {
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> parentIds = new Set<Id>();
            Set<String> currencies = new Set<String>();
            Map<String, Decimal> exchangeRates = new Map<String, Decimal>();
            
            for(varcpq__Invoice__c parent : Trigger.new) {
                varcpq__Invoice__c oldParent = Trigger.oldMap.get(parent.Id);
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
                List<varcpq__Invoice_Line_Item__c> children = [SELECT Id, Name, varcpq__Invoice__c, varcpq__Total_Cost__c, varcpq__Unit_Price__c,
                                                               varcpq__Contract_Fees__c FROM varcpq__Invoice_Line_Item__c WHERE varcpq__Invoice__c IN :parentIds];
                
                List<varcpq__Invoice__c> parentRecords = [SELECT Id FROM varcpq__Invoice__c WHERE Id IN :parentIds];
                
                String query = 'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode IN :currencies';
                List<SObject> rates = Database.query(query);

                for (SObject rate : rates) {
                    String isoCode = (String) rate.get('IsoCode');
                    Decimal conversionRate = (Decimal) rate.get('ConversionRate');
                    exchangeRates.put(isoCode, conversionRate);
                }
                System.debug('Exchange rate map: ' + exchangeRates);
                
                for (varcpq__Invoice_Line_Item__c child : children) {
                    varcpq__Invoice__c parent = Trigger.newMap.get(child.varcpq__Invoice__c);
                    
                    varcpq__Invoice__c oldParent = Trigger.oldMap.get(child.varcpq__Invoice__c);
                    String parentNewCurrency = (String) parent.get('CurrencyIsoCode');
                    String parentOldCurrency = (String) oldParent.get('CurrencyIsoCode');
                    
                    if (exchangeRates.containsKey(parentOldCurrency) && exchangeRates.containsKey(parentNewCurrency)) {
                        Decimal oldRate = exchangeRates.get(parentOldCurrency);
                        Decimal newRate = exchangeRates.get(parentNewCurrency);
                        System.debug('Old Rate: ' + oldRate + ', New Rate: ' + newRate);
                        
                        if (oldRate != null && newRate != null) {
                            if(child.varcpq__Total_Cost__c != null){
                                child.varcpq__Total_Cost__c = (child.varcpq__Total_Cost__c / oldRate) * newRate;
                            }
                            if(child.varcpq__Unit_Price__c != null){
                                child.varcpq__Unit_Price__c = (child.varcpq__Unit_Price__c / oldRate) * newRate;
                            }
                            if(child.varcpq__Contract_Fees__c != null){
                                child.varcpq__Contract_Fees__c = (child.varcpq__Contract_Fees__c / oldRate) * newRate;
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