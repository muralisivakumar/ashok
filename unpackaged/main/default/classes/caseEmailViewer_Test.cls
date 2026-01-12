@isTest
public class caseEmailViewer_Test {
	@isTest
    static void testCaseEmailViewer(){
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'This is a test case.'
        );
        insert testCase;

        // Step 2: Create the EmailMessage
        EmailMessage testEmail = new EmailMessage(
            Subject = 'Test Email Subject',
            HtmlBody = '<p>This is a test email body.</p>',
            FromAddress = 'sender@example.com',
            ToAddress = 'recipient@example.com',
            RelatedToId = testCase.Id,
            Status = '3' 
        );

        
        insert testEmail;
        
        caseEmailViewer.getEmailBody(testCase.Id);
    }
    
}