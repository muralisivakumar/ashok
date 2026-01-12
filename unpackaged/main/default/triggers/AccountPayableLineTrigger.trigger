/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : AccountPayableLineTrigger
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
trigger AccountPayableLineTrigger on varcpq__Account_Payable_Invoice_Line_Item__c (before insert) {

    if(trigger.isBefore && trigger.isInsert){
        Set<Id> APILIIds = new Set<Id>();
        for(varcpq__Account_Payable_Invoice_Line_Item__c APILI : Trigger.new) {
            APILIIds.add(APILI.varcpq__Accounts_Payable_Invoice__c );
        }
        
        Map<Id,String> APILIIsoCode = new Map<Id,String>();
        for(varcpq__Accounts_Payable_Invoice__c API: [SELECT Id, CurrencyIsoCode FROM varcpq__Accounts_Payable_Invoice__c WHERE Id IN:APILIIds]){
            APILIIsoCode.put(API.Id,API.CurrencyIsoCode);
        }
        
        for(varcpq__Account_Payable_Invoice_Line_Item__c APILI : Trigger.new) {
            APILI.CurrencyIsoCode = APILIIsoCode.get(APILI.varcpq__Accounts_Payable_Invoice__c);
            System.debug('APILI.CurrencyIsoCode :: '+APILI.CurrencyIsoCode);
        }
    }
}