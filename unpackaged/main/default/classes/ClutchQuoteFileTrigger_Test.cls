@isTest
public class ClutchQuoteFileTrigger_Test {
    @isTest
    static void testFileInsertAndDelete() {
        // Create a test Opportunity (required for Quote creation)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        // Create a Quote linked to the test Opportunity
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Status = 'Draft'
        );
        insert testQuote;

        // Insert a PDF file
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'ClutchQuote_TestFile',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert testContentVersion;

        // Re-query the ContentVersion to retrieve the ContentDocumentId
        testContentVersion = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :testContentVersion.Id
        ];

        // Query the ContentDocument using the ContentVersion's ContentDocumentId
        ContentDocument testContentDocument = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id = :testContentVersion.ContentDocumentId
        ];

        // Link the file to the Quote
        ContentDocumentLink testLink = new ContentDocumentLink(
            LinkedEntityId = testQuote.Id,
            ContentDocumentId = testContentDocument.Id,
            ShareType = 'V'
        );
        insert testLink;

        // Validate Quote_PDF_Count__c after linking
        testQuote = [SELECT Quote_PDF_Count__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals(1, testQuote.Quote_PDF_Count__c);

        // Delete the ContentDocumentLink
        delete testContentDocument;

        // Validate Quote_PDF_Count__c after deleting the ContentDocumentLink
        testQuote = [SELECT Quote_PDF_Count__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals(0, testQuote.Quote_PDF_Count__c);
    }
}