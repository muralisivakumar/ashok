/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : InvoiceLineTriggers
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

trigger InvoiceLineTriggers on varcpq__Invoice_Line_Item__c (before insert) {

    if(trigger.isBefore && trigger.isInsert){
        Set<Id> InvIds = new Set<Id>();
        for(varcpq__Invoice_Line_Item__c InvLI : Trigger.new) {
            InvIds.add(InvLI.varcpq__Invoice__c);
        }
        
        Map<Id,String> InvIsoCode = new Map<Id,String>();
        for(varcpq__Invoice__c Inv: [SELECT Id, CurrencyIsoCode FROM varcpq__Invoice__c WHERE Id IN:InvIds]){
            InvIsoCode.put(Inv.Id,Inv.CurrencyIsoCode);
        }
        
        for(varcpq__Invoice_Line_Item__c InvLI : Trigger.new) {
            InvLI.CurrencyIsoCode = InvIsoCode.get(InvLI.varcpq__Invoice__c);
        }
    }

}