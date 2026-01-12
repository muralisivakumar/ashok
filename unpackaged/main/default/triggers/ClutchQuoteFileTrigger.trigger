trigger ClutchQuoteFileTrigger on ContentDocumentLink (after insert) {
    // Collect affected Quote IDs
    Set<Id> affectedQuoteIds = new Set<Id>();

    for (ContentDocumentLink link : Trigger.new) {
        if (link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == Quote.sObjectType) {
            affectedQuoteIds.add(link.LinkedEntityId);
        }
    }

    // Update the PDF count for affected Quotes
    if (!affectedQuoteIds.isEmpty()) {
        ClutchQuoteFileHelper.updateQuotePdfCount(affectedQuoteIds);
    }
}