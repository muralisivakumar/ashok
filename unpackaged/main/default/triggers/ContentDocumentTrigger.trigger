trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if(Trigger.isbefore && Trigger.isDelete){
        // Get configured object types
        Set<String> configuredObjects = new Set<String>();
        for(PDF_Document_Configuration__mdt config : [SELECT Object_API_Name__c FROM PDF_Document_Configuration__mdt]) {
            configuredObjects.add(config.Object_API_Name__c);
        }
        Set<Id> cntDocIds = new Set<Id>();
        for(Id docId: Trigger.oldMap.keySet()){
            cntDocIds.add(docId);
        }
        
        // Get all PDF links before deletion, filtering for configured objects
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId =:cntDocIds
            
        ];
        
        Map<String, Set<Id>> recordsByType = new Map<String, Set<Id>>();
        
        for(ContentDocumentLink link : links) {
            String objType = link.LinkedEntityId.getSObjectType().getDescribe().getName();
            if(configuredObjects.contains(objType)) {
                if(!recordsByType.containsKey(objType)) {
                    recordsByType.put(objType, new Set<Id>());
                }
                recordsByType.get(objType).add(link.LinkedEntityId);
            }
        }
        
        for(String objType : recordsByType.keySet()) {
            PDFCounterService.updatePDFCountAfterDelete(recordsByType.get(objType));
        }
    }
}