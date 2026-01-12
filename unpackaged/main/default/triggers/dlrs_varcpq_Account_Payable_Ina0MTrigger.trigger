/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_varcpq_Account_Payable_Ina0MTrigger on varcpq__Account_Payable_Invoice_Line_Item__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(varcpq__Account_Payable_Invoice_Line_Item__c.SObjectType);
}