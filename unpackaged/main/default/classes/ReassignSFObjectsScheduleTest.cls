@IsTest
private class ReassignSFObjectsScheduleTest {

    @IsTest
    static void testScheduledBatchExecution() {
        // 12:00 PM every day: 0 0 12 * * ?
        String cronExpr = '0 0 12 * * ?';
        String jobName = 'TestReassignBatchJob';

        Test.startTest();
            // Schedule the job (won't actually run the batch in test context)
            System.schedule(jobName, cronExpr, new ReassignSFObjectsSchedule());
        Test.stopTest();
    }
}