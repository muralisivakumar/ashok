/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Customer_Invoice_PaymentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Customer_Invoice_PaymentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Customer_Invoice_Payment__c());
    }
}