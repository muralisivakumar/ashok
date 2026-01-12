/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : AccountPayableTrigger
* Created By                       : Quotely App Exchange Engineering Team
* Created Date                     : 14-10-2024
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                 Modification ID        Description 
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Quotely App Exchange Engineering 
* Team
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Note: This class/trigger was written by the Quotely Engineering team. Please do not update any instance of the code without consulting the Quotely App Exchange team.
******************************************************************************************************************************************************************************/

trigger AccountPayableTrigger on varcpq__Accounts_Payable_Invoice__c (before insert, after update) {

    if(trigger.isBefore && trigger.isInsert){
        
        Set<Id> POIds = new Set<Id>();
        for(varcpq__Accounts_Payable_Invoice__c API : Trigger.new) {
            POIds.add(API.varcpq__Purchase_Order__c );
        }
        
        Map<Id,String> poIsoCode = new Map<Id,String>();
        for(varcpq__Purchase_Order__c po: [SELECT Id, Name, CurrencyIsoCode FROM varcpq__Purchase_Order__c WHERE Id IN:POIds]){
            poIsoCode.put(po.Id,po.CurrencyIsoCode);
        }
        
        for(varcpq__Accounts_Payable_Invoice__c API : Trigger.new) {
            API.CurrencyIsoCode = poIsoCode.get(API.varcpq__Purchase_Order__c);
        }
    }
    
     if (Schema.SObjectType.varcpq__Accounts_Payable_Invoice__c.fields.getMap().containsKey('CurrencyIsoCode')) {
        
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> parentIds = new Set<Id>();
            Set<String> currencies = new Set<String>();
            Map<String, Decimal> exchangeRates = new Map<String, Decimal>();
            
            for(varcpq__Accounts_Payable_Invoice__c parent : Trigger.new) {
                varcpq__Accounts_Payable_Invoice__c oldParent = Trigger.oldMap.get(parent.Id);
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
                List<varcpq__Account_Payable_Invoice_Line_Item__c> children = [SELECT Id, Name, CurrencyIsoCode, varcpq__Accounts_Payable_Invoice__c, varcpq__PO_Unit_Cost__c, varcpq__Quantity_Invoiced__c, varcpq__Unit_Cost__c, 
                                                                      varcpq__Unit_Price__c, varcpq__Ext_Unit_Cost__c, varcpq__Ext_Unit_Price__c, varcpq__Ext_Variance_Amount__c, varcpq__Part_No__c, varcpq__Unit_Variance_Amount__c, 
                                                                      varcpq__Purchase_Order_Line_Item__c, varcpq__Notes__c, varcpq__Status__c FROM varcpq__Account_Payable_Invoice_Line_Item__c WHERE varcpq__Accounts_Payable_Invoice__c IN :parentIds];
                
                List<varcpq__Accounts_Payable_Invoice__c> parentRecords = [SELECT Id FROM varcpq__Accounts_Payable_Invoice__c WHERE Id IN :parentIds];
                
                String query = 'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode IN :currencies';
                List<SObject> rates = Database.query(query);

                for (SObject rate : rates) {
                    String isoCode = (String) rate.get('IsoCode');
                    Decimal conversionRate = (Decimal) rate.get('ConversionRate');
                    exchangeRates.put(isoCode, conversionRate);
                }
                System.debug('Exchange rate map: ' + exchangeRates);
                
                for (varcpq__Account_Payable_Invoice_Line_Item__c child : children) {
                    varcpq__Accounts_Payable_Invoice__c parent = Trigger.newMap.get(child.varcpq__Accounts_Payable_Invoice__c);
                    varcpq__Accounts_Payable_Invoice__c oldParent = Trigger.oldMap.get(child.varcpq__Accounts_Payable_Invoice__c);
                    
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
                            if(child.varcpq__PO_Unit_Cost__c != null){
                                child.varcpq__PO_Unit_Cost__c = (child.varcpq__PO_Unit_Cost__c / oldRate) * newRate;
                            }
                            if(child.varcpq__Unit_Price__c != null){
                                child.varcpq__Unit_Price__c = (child.varcpq__Unit_Price__c / oldRate) * newRate;
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