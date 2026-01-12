/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_varcpq_Purchase_OrderTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_varcpq_Purchase_OrderTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new varcpq__Purchase_Order__c());
    }
}