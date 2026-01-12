/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_varcpq_Purchase_OrderTrigger on varcpq__Purchase_Order__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(varcpq__Purchase_Order__c.SObjectType);
}