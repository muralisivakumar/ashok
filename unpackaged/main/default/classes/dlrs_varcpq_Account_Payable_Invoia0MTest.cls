/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_varcpq_Account_Payable_Invoia0MTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_varcpq_Account_Payable_Ina0MTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new varcpq__Account_Payable_Invoice_Line_Item__c());
    }
}