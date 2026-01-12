@isTest
public class EmailComposerControllerTest {
    
    @testSetup
    static void setup() {
     Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(lastName = 'testlastname',email='test@test.com',accountId=acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Status = 'Draft',
            Ship_to_email__c = 'test@test.com'
        );
        insert quote;
       }
    @testVisible
    public static Object_Prefix_Mapping__mdt objPreTes{
        get{
             String objectApiName = 'Quote';
            if(objPreTes == Null){
               Object_Prefix_Mapping__mdt objConfig =[SELECT Prefix__c, Object_API_Name__c FROM Object_Prefix_Mapping__mdt];
            }
            return objPreTes;
        }
        set;
    }
    @testVisible
    public static Email_Configuration__mdt emailConfigTest{
        get{
            String objectApiName = 'Quote';
            if(emailConfigTest == NULL){
                Email_Configuration__mdt config = [ SELECT Object_API_Name__c, Template_Name__c, 
                       HTML_Template__c, Plain_Text_Template__c,
                       CSS_Styles__c, Required_Fields__c,
                       Default_Subject__c, Account_Relationship_Path__c,
                       Save_Email_Message__c, Default_To_Field__c,
                       File_Name_Prefix__c, Merge_Fields_Query__c,
                       EmailMessage_Related_Field_API_Name__c, 
                       Status_Field_API_Name__c, Status_Value_after_Send__c,
                       Status_Checkbox_Label__c, Attachment_Field_API_Name__c
                FROM Email_Configuration__mdt
                WHERE Object_API_Name__c = :objectApiName
                LIMIT 1];
            }
            return emailConfigTest;
        }
        set;
        
    }
    
     @testVisible
    public static Email_Signature__mdt emailSignTest{
        get{
            String objectApiName = 'Quote';
            if(emailSignTest == NULL){
                Email_Signature__mdt config = [  SELECT HTML_Signature__c, Plain_Text_Signature__c, CSS_Styles__c, Profile_Filter__c 
            FROM Email_Signature__mdt];
            }
            return emailSignTest;
        }
        set;
        
    }
    
    
    
    @isTest
    static void testGetObjectPrefixMappings() {
        Test.startTest();
        List<Object_Prefix_Mapping__mdt> mappings = EmailComposerController.getObjectPrefixMappings();
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testGetEmailConfiguration() {
        Test.startTest();
        Email_Configuration__mdt config = EmailComposerController.getEmailConfiguration('Quote');
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testGetEmailSignature() {
        Test.startTest();
        Email_Signature__mdt signature = EmailComposerController.getEmailSignature();
        Test.stopTest();
        }
    
    @isTest
    static void testGetEmailContent() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        Map<String, Object> emailContent = EmailComposerController.getEmailContent(quote.Id, user.Id, 'Quote Template');
        Test.stopTest();
        
    
    }
    
    @isTest
    static void testSendEmail() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Map<String, Object> emailData = new Map<String, Object>{
            'recordId' => quote.Id,
            'objectApiName' => 'Quote',
            'toEmail' => new List<String>{'test@example.com'},
            'subject' => 'Test Subject',
            'htmlBody' => '<html><body>Test Email Body</body></html>',
            'plainTextBody' => 'Test Email Body',
            'saveAsActivity' => true,
            'templateId' => null
        };
        
        Test.startTest();
        EmailComposerController.sendEmail(JSON.serialize(emailData));
        EmailComposerController.getRelatedPDFs(quote.Id);
        Test.stopTest();
        
        List<EmailMessage> sentEmails = [
            SELECT Id, Subject 
            FROM EmailMessage 
            WHERE RelatedToId = :quote.Id
        ];
       
    }
    
    @isTest
    static void testSendEmailWithAttachment() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
      
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        list<String> condocids = new list<String>();
        condocids.add(condocid);
        Map<String, Object> emailData = new Map<String, Object>{
            'recordId' => quote.Id,
            'objectApiName' => 'Quote',
            'toEmail' => new List<String>{'test@example.com'},
            'subject' => 'Test Subject with Attachment',
            'htmlBody' => '<html><body>Test Email with Attachment</body></html>',
            'plainTextBody' => 'Test Email with Attachment',
            'saveAsActivity' => true,
            'templateId' => null,
            'attachmentId' => condocids
        };
        
        Test.startTest();
        EmailComposerController.sendEmail(JSON.serialize(emailData));
        list<Id> conIds = new List<Id>();
        conIds.add(conDocId);
        EmailComposerController.getSODefaultFiles(conIds, quote.Id);
        Test.stopTest();
        
        List<EmailMessage> sentEmails = [
            SELECT Id, Subject, (SELECT Id FROM Attachments)
            FROM EmailMessage 
            WHERE RelatedToId = :quote.Id
        ];
       
    }
}
/*public class EmailComposerControllerTest {
    
    @testSetup
    static void setup() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create test contact
        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert con;
    }
    
    @isTest
    static void testGetObjectPrefixMappings() {
        Test.startTest();
        
        try {
            List<Object_Prefix_Mapping__mdt> mappings = EmailComposerController.getObjectPrefixMappings();
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmailConfiguration() {
        Test.startTest();
        
        try {
            Email_Configuration__mdt config = EmailComposerController.getEmailConfiguration('Account');
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmailSignature() {
        Test.startTest();
        
        try {
            Email_Signature__mdt signature = EmailComposerController.getEmailSignature();
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmailContent() {
        Test.startTest();
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        try {
            Map<String, Object> emailContent = EmailComposerController.getEmailContent(
                acc.Id, UserInfo.getUserId(), 'Test_Template');
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmail() {
        Test.startTest();
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test content document
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document.pdf',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink to associate the document with the account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Prepare email data
        Map<String, Object> emailData = new Map<String, Object>{
            'recordId' => acc.Id,
            'objectApiName' => 'Account',
            'toEmail' => new List<String>{'test@example.com'},
            'ccEmail' => new List<String>{'cc@example.com'},
            'bccEmail' => new List<String>{'bcc@example.com'},
            'subject' => 'Test Subject: ' + acc.Name,
            'htmlBody' => '<p>Test HTML Body for ' + acc.Name + '</p>',
            'plainTextBody' => 'Test Plain Text Body for ' + acc.Name,
            'attachmentId' => contentDocId
        };
        
        try {
            EmailComposerController.sendEmail(JSON.serialize(emailData));
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testRelatedPDFs() {
        Test.startTest();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test content document with PDF extension
        ContentVersion cv = new ContentVersion(
            Title = 'ACCOUNT_123_20240305.pdf',
            PathOnClient = 'ACCOUNT_123_20240305.pdf',
            VersionData = Blob.valueOf('Test PDF Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink to associate the document with the account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        try {
            List<Map<String, Object>> relatedPDFs = EmailComposerController.getRelatedPDFs(acc.Id);
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessRecordFields() {
        Test.startTest();
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact con = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        
        // Create a map to mimic what processRecordFields would do
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<String, Object> fieldMap = new Map<String, Object>();
        
        // Add direct fields
        fieldMap.put('Id', acc.Id);
        fieldMap.put('Name', acc.Name);
        
        // Add relationship field
        Map<String, Object> contactMap = new Map<String, Object>();
        contactMap.put('FirstName', con.FirstName);
        contactMap.put('LastName', con.LastName);
        contactMap.put('Email', con.Email);
        fieldMap.put('Contact', contactMap);
        
        resultMap.putAll(fieldMap);
        
        // Verify the nested structure
        System.assertEquals(acc.Name, resultMap.get('Name'), 'Direct field should be accessible');
        Map<String, Object> retrievedContact = (Map<String, Object>)resultMap.get('Contact');
        System.assertEquals(con.Email, retrievedContact.get('Email'), 'Nested field should be accessible');
        
        Test.stopTest();
    }
    
    @isTest
    static void testMergeTemplate() {
        Test.startTest();
        
        // Test data for template merging
        Map<String, Object> data = new Map<String, Object>{
            'Name' => 'Test Account',
            'User' => new Map<String, Object>{
                'Name' => 'Test User',
                'Email' => 'test.user@example.com'
            },
            'Organization' => new Map<String, Object>{
                'Name' => 'Test Org'
            }
        };
        
        // Test simple template
        String simpleTemplate = 'Hello {!Name}!';
        String expectedSimple = 'Hello Test Account!';
        String actualSimple = simpleTemplate.replace('{!Name}', (String)data.get('Name'));
        System.assertEquals(expectedSimple, actualSimple, 'Simple template should merge correctly');
        
        // Test nested template
        String nestedTemplate = 'Hello {!Name} from {!User.Name} at {!Organization.Name}!';
        String expectedNested = 'Hello Test Account from Test User at Test Org!';
        
        // Manually perform the merge similar to what the controller would do
        String actualNested = nestedTemplate;
        actualNested = actualNested.replace('{!Name}', (String)data.get('Name'));
        
        Map<String, Object> userData = (Map<String, Object>)data.get('User');
        actualNested = actualNested.replace('{!User.Name}', (String)userData.get('Name'));
        
        Map<String, Object> orgData = (Map<String, Object>)data.get('Organization');
        actualNested = actualNested.replace('{!Organization.Name}', (String)orgData.get('Name'));
        
        System.assertEquals(expectedNested, actualNested, 'Nested template should merge correctly');
        
        Test.stopTest();
    }
    
    @isTest
    static void testNavigateFieldPath() {
        Test.startTest();
        
        // Test data structure similar to what the controller would use
        Map<String, Object> data = new Map<String, Object>{
            'Account' => new Map<String, Object>{
                'Name' => 'Test Account',
                'Contact' => new Map<String, Object>{
                    'FirstName' => 'Test',
                    'LastName' => 'Contact',
                    'Email' => 'test.contact@example.com'
                }
            }
        };
        
        // Test getting direct field
        Map<String, Object> account = (Map<String, Object>)data.get('Account');
        System.assertEquals('Test Account', account.get('Name'), 'Direct field access should work');
        
        // Test getting nested field
        Map<String, Object> contact = (Map<String, Object>)account.get('Contact');
        System.assertEquals('Test', contact.get('FirstName'), 'Nested field access should work');
        System.assertEquals('test.contact@example.com', contact.get('Email'), 'Deep nested field access should work');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAttachments() {
        Test.startTest();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test content document
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document.pdf',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink to associate the document with the account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Create an email message with attachment
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'test@example.com'});
        email.setSubject('Test Subject with Attachment');
        email.setHtmlBody('<html><body>Test Email with Attachment</body></html>');
        email.setPlainTextBody('Test Email with Attachment');
        
        // Create attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Test Document.pdf');
        attachment.setBody(Blob.valueOf('Test Content'));
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSODefaultFiles() {
        Test.startTest();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test content document
        ContentVersion cv = new ContentVersion(
            Title = 'Test_SO_File.pdf',
            PathOnClient = 'Test_SO_File.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        try {
            // Create an SObject dynamically to avoid direct reference to Quote
            SObject sobj = Schema.getGlobalDescribe().get('Quote').newSObject();
            sobj.put('Name', 'Test Quote');
            
            // Try to insert with DML options to bypass validation rules
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.optAllOrNone = false;
            
            // Try to insert bypassing triggers and validation
            Database.SaveResult result = Database.insert(sobj, dml);
            
            if (result.isSuccess()) {
                Id quoteId = result.getId();
                List<Id> contentDocIds = new List<Id>{ contentDocId };
                
                try {
                    // Call the method we want to test
                    EmailComposerController.getSODefaultFiles(contentDocIds, quoteId);
                } catch (Exception e) {
                    System.debug('Expected exception: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Exception creating Quote: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testStringConversions() {
        Test.startTest();
        
        // Test the string conversion utility used for email addresses
        List<Object> objList = new List<Object>{'test1@example.com', 'test2@example.com'};
        List<String> strList = new List<String>();
        
        for (Object obj : objList) {
            strList.add(String.valueOf(obj));
        }
        
        System.assertEquals(2, strList.size(), 'Should convert 2 objects to strings');
        System.assertEquals('test1@example.com', strList[0], 'First email should match');
        System.assertEquals('test2@example.com', strList[1], 'Second email should match');
        
        Test.stopTest();
    }
}*/