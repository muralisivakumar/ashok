trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, after delete) {
    Map<String, Set<Id>> recordIdsByObjectType = new Map<String, Set<Id>>();
    List<ContentDocumentLink> links = Trigger.isInsert ? Trigger.new : Trigger.old;
    
    for (ContentDocumentLink link : links) {
        if (link.LinkedEntityId != null) {
            String objType = link.LinkedEntityId.getSObjectType().getDescribe().getName();
            if (!recordIdsByObjectType.containsKey(objType)) {
                recordIdsByObjectType.put(objType, new Set<Id>());
            }
            recordIdsByObjectType.get(objType).add(link.LinkedEntityId);
        }
    }
    
    for (String objType : recordIdsByObjectType.keySet()) {
        Set<Id> recordIds = recordIdsByObjectType.get(objType);
        if (Trigger.isInsert) {
            PDFCounterService.updatePDFCount(recordIds,'insert');
        } else {
            PDFCounterService.updatePDFCountAfterDelete(recordIds);
        }
    }
}