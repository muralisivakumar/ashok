/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : SalesOrderLineTriggers
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

trigger SalesOrderLineTriggers on varcpq__Sales_Order_Line_Item__c (before insert) {

    if(trigger.isBefore && trigger.isInsert){
        Set<Id> SOIds = new Set<Id>();
        for(varcpq__Sales_Order_Line_Item__c SOLI : Trigger.new) {
            SOIds.add(SOLI.varcpq__Sales_Order__c);
        }
        
        Map<Id,String> SOIsoCode = new Map<Id,String>();
        for(varcpq__Sales_Order__c SO: [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE Id IN:SOIds]){
            SOIsoCode.put(SO.Id,SO.CurrencyIsoCode);
        }
        
        for(varcpq__Sales_Order_Line_Item__c SOLI : Trigger.new) {
            SOLI.CurrencyIsoCode = SOIsoCode.get(SOLI.varcpq__Sales_Order__c);
        }
    }
}