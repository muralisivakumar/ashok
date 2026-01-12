/***************************************************************************************************************************************************************************************
* @description       : Trigger on ContentDocumentLink to publish the Platform Event
* @author            : Aress Software - AS
* @Created date      : 25/08/2025
* @related class     : -
* @test Class        : - ContentVersionHelper_Test
* @last modified on  : - 25/08/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

trigger fileUploadLinkTrigger on ContentDocumentLink (before insert) {
    List<File_Upload_Capture__e> events = new List<File_Upload_Capture__e>();

    // Fetch ContentDocument + Version details
    
    Set<Id> contentDocIds = new Set<Id>();
    for(ContentDocumentLink docLink : Trigger.new){
        contentDocIds.add(docLink.ContentDocumentId);
    }
    
    Map<Id, ContentDocument> docs = new Map<Id, ContentDocument>(
        [SELECT Id, Title, LatestPublishedVersionId
         FROM ContentDocument
         WHERE Id IN : contentDocIds]
    );

    for (ContentDocumentLink cdl : Trigger.new) {
        ContentDocument doc = docs.get(cdl.ContentDocumentId);

        events.add(new File_Upload_Capture__e(
            ContentDocumentId__c = cdl.ContentDocumentId,
            LinkedEntityId__c    = cdl.LinkedEntityId,
            ContentVersionId__c  = doc.LatestPublishedVersionId,
            FileName__c          = doc.Title
        ));
    }

    if (!events.isEmpty()) {
        Database.SaveResult[] results = EventBus.publish(events);
        System.debug('Published ' + results.size() + ' File_Upload_Capture__e events.');
    }
}