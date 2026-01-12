trigger ClutchQuoteFileOnDeleteTrigger on ContentDocument (before delete) {
    Set<Id> affectedQuoteIds = new Set<Id>();
    System.debug('Trigger.old '+Trigger.old);
    
    Set<Id> docIds = new Set<Id>();
    for(ContentDocument doc : Trigger.old){
        docIds.add(doc.Id);
    }
    

    List<ContentDocumentLink> links = [
        SELECT LinkedEntityId
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :docIds
    ];
    System.debug('links '+links);
    for (ContentDocumentLink link : links) {
        if (link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == Quote.sObjectType) {
            affectedQuoteIds.add(link.LinkedEntityId);
        }
    }
    System.debug('affectedQuoteIds '+affectedQuoteIds);
 
    
    // Update the PDF count for affected Quotes
    if (!affectedQuoteIds.isEmpty()) {
        ClutchQuoteFileHelper.updateQuotePdfCountAfterDelete(affectedQuoteIds);
    }
}