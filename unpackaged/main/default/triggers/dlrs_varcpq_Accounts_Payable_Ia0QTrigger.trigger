/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_varcpq_Accounts_Payable_Ia0QTrigger on varcpq__Accounts_Payable_Invoice__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(varcpq__Accounts_Payable_Invoice__c.SObjectType);
}