/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Return_Merchandise_Authora3QTrigger on Return_Merchandise_Authorization_Line_It__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Return_Merchandise_Authorization_Line_It__c.SObjectType);
}