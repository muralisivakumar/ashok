@isTest
private class fileUploadManualCreditMemo_Test{
	 @isTest
    static void contentVerTest() {
        Account acc = new Account(Name = 'Test Account',Type = 'Customer');
        insert acc;
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test content')
        );     
        insert cv;
        Test.startTest();
        Test.stopTest();
        ContentVersion cvNew = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cvNew.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );
        insert cdl;
        List<Id> docIds = new List<Id>{cvNew.ContentDocumentId};
        
        fileUploadManualCreditMemo.getFileCategoryOptions();
        List<ContentDocument> docs = fileUploadManualCreditMemo.getContentDocs(docIds);
        List<fileUploadManualCreditMemo.fileWrapper> fileWraps = fileUploadManualCreditMemo.getFileWrapper(docIds);
        fileUploadManualCreditMemo.updateFileCategory(JSON.serialize(fileWraps));
        
    }

}