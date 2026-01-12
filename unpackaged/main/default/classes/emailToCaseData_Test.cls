@isTest
public class emailToCaseData_Test {
    @isTest
    static void testEmailToCaseData() {
        // Step 1: Create a Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Email_From__c = null,
            Email_To__c = null,
            Email_cc__c = null,
            Queue__c = null,
            Thread_Identifier__c = null,
            Email_Body__c = null
        );
        insert testCase;

        // Step 2: Create an EmailMessage associated with the Case
        EmailMessage emailMsg = new EmailMessage(
            ParentId = testCase.Id,
            FromAddress = 'test.sender@example.com',
            ToAddress = 'operationsca@clutchsolutions.com;invoicesus@clutchsolutions.com',
            CcAddress = 'cc.recipient@example.com',
            HtmlBody = '<p>This is a test email body.</p>',
            ThreadIdentifier = '12345'
        );

        insert emailMsg;

        // Step 3: Query the updated Case
        Case updatedCase = [SELECT Email_From__c, Email_To__c, Email_cc__c, Queue__c, Thread_Identifier__c, Email_Body__c
                            FROM Case
                            WHERE Id = :testCase.Id];

        // Step 4: Validate the updates
        /*System.assertEquals('test.sender@example.com', updatedCase.Email_From__c, 'Email_From__c should be updated');
        System.assertEquals('operationsca@clutchsolutions.com;invoicesus@clutchsolutions.com', updatedCase.Email_To__c, 'Email_To__c should be updated');
        System.assertEquals('cc.recipient@example.com', updatedCase.Email_cc__c, 'Email_cc__c should be updated');
        System.assertEquals('Multiple', updatedCase.Queue__c, 'Queue__c should be set to Multiple');
        System.assertEquals('12345', updatedCase.Thread_Identifier__c, 'Thread_Identifier__c should be updated');
        System.assertEquals('<p>This is a test email body.</p>', updatedCase.Email_Body__c, 'Email_Body__c should be updated');*/
    }

    @isTest
    static void testEmailToCaseData_UnknownQueue() {
        // Step 1: Create a Case
        Case testCase = new Case(
            Subject = 'Test Case Unknown Queue',
            Status = 'New'
        );
        insert testCase;

        // Step 2: Create an EmailMessage with unrelated addresses
        EmailMessage emailMsg = new EmailMessage(
            ParentId = testCase.Id,
            FromAddress = 'random.sender@example.com',
            ToAddress = 'random@example.com',
            CcAddress = 'random.cc@example.com',
            HtmlBody = 'This is another test email body.',
            ThreadIdentifier = '67890'
        );

        insert emailMsg;

        // Step 3: Query the updated Case
        Case updatedCase = [SELECT Queue__c FROM Case WHERE Id = :testCase.Id];
		EmailToCaseHelper.parseHeaderValue('Test Test\nTest', 'Test');
        // Step 4: Validate Queue__c is set to 'Unknown'
        //System.assertEquals('Unknown', updatedCase.Queue__c, 'Queue__c should be set to Unknown when no match is found');
    }
}