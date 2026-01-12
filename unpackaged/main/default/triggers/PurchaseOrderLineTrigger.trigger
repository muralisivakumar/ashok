/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : PurchaseOrderLineTrigger
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

trigger PurchaseOrderLineTrigger on varcpq__Purchase_Order_Line_Item__c (before insert) {

    if(trigger.isBefore && trigger.isInsert){
        Set<Id> POIds = new Set<Id>();
        for(varcpq__Purchase_Order_Line_Item__c POLI : Trigger.new) {
            POIds.add(POLI.varcpq__Purchase_Order__c);
        }
        
        Map<Id,String> POIsoCode = new Map<Id,String>();
        for(varcpq__Purchase_Order__c PO: [SELECT Id, CurrencyIsoCode FROM varcpq__Purchase_Order__c WHERE Id IN:POIds]){
            POIsoCode.put(PO.Id,PO.CurrencyIsoCode);
        }
        
        for(varcpq__Purchase_Order_Line_Item__c POLI : Trigger.new) {
            POLI.CurrencyIsoCode = POIsoCode.get(POLI.varcpq__Purchase_Order__c);
        }
    }
}