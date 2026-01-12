@isTest
public class emailQuoteCustom_Test {
    @isTest
    static void setupTestData() {
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;
        
        PricebookEntry integrationPbe = new PricebookEntry(
            Pricebook2Id = integrationPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbe;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test',LastName = 'Contact', Email='test@contest.com', accountId=acc.Id);
        Insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Approved',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        
        
        String pdfContent = 'JVBERi0xLjQKJcTl8uX7FDR57uT1FqLlC9BL7UgkGvkyjZGmLm'+
            'zk02yxM2hZVA5qHD88g5UEFA7jz5n4PzQ2elPTeVVAsH6k2Sc'+
            'l7drgP9znrHK6Za2YZH4qrjYrZd7w3kFMJ5/ZsqV9yFFb5vmm'+
            '8CRwfaHfQ3+u3IFf5fZjB60HfJlJjVhIby1vLfGbv5nwvQ7XZ'+
            'jl0TOzGLgjt8nUv9XIfjzL2tmPR02C69rtf7lB+EKAAJubXXh'+
            'AP6jl62kCg7nm7REU+02dmWc7imNofgF+CuBg';
        
        // Convert the base64 string to blob
        Blob pdfBlob = EncodingUtil.base64Decode(pdfContent);
        
        ContentVersion cv = new ContentVersion(
            Title = 'ClutchQuote.pdf',
            PathOnClient = 'ClutchQuote.pdf',
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert cv;
        System.debug('cv '+cv);
        System.debug('cv condt '+cv.ContentDocumentId); 
        
        if (cv.ContentDocumentId == null) {
            // Use Test.startTest() and Test.stopTest() to allow async processing
            Test.startTest();
            Test.stopTest();
            
            // Query again after async operations
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            System.debug('cv ContentDocumentId after Test.stopTest(): ' + cv.ContentDocumentId);
        }
        ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];
        System.debug('content doc '+contentDoc);
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = quote.Id, // Linking the PDF to the Quote
            ShareType = 'V'  // 'V' for Viewer, 'C' for Collaborator
        );
        
        insert cdl;
        
        System.debug('content title '+cdl.ContentDocument.Title);
        system.debug('cdl '+cdl);
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='clutch@clutchsolutions.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='clutchuser@testorg.com');
        insert u;
        emailQuoteCustom.emailWrapper wrap = emailQuoteCustom.getEmailContent(quote.Id, u.Id);
        emailQuoteCustom.emailSendWrapper esWrap = new emailQuoteCustom.emailSendWrapper();
        esWrap.attachmentId = contentDoc.Id;
        esWrap.fromEmail = u.Email;
        esWrap.subject =  wrap.emailSubject;
        esWrap.htmlBody = wrap.emailBody;
        esWrap.quoteId = quote.Id;
        esWrap.isPresented = true;
        List<String> toEmails = new List<String>();
        toEmails.add('test@test.com');
        esWrap.toEmail = toEmails;
        
        
        emailQuoteCustom.sendEmail(JSON.serialize(esWrap));
        
    }
    
    /*@isTest
static void testEmail(){

User user = [SELECT Id,name, Email FROM User limit 1];
Quote qt = [SELECT Id, QuoteNumber,createdBy.Name FROM Quote Limit 1];
System.debug('Qt' +qt);
emailQuoteCustom.emailWrapper wrap = emailQuoteCustom.getEmailContent(qt.Id, user.Id);
System.debug('wrap '+wrap);
emailQuoteCustom.sendEmail(JSON.serialize(wrap));

}*/
}