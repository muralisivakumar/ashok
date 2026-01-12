public class PDFCounterService {
    private static Map<String, PDF_Document_Configuration__mdt> configByObjectName;
    
    static {
        configByObjectName = new Map<String, PDF_Document_Configuration__mdt>();
        for (PDF_Document_Configuration__mdt config : [
            SELECT Object_API_Name__c, File_Name_Prefix__c, PDF_Count_Field_API_Name__c 
            FROM PDF_Document_Configuration__mdt
            WHERE File_Name_Prefix__c != null 
            AND PDF_Count_Field_API_Name__c != null
        ]) {
            configByObjectName.put(config.Object_API_Name__c, config);
        }
    }
    
    public static void updatePDFCount(Set<Id> recordIds,String DMLType) {
        System.debug('UpdatePDFCount called with IDs: ' + recordIds);
        if (recordIds == null || recordIds.isEmpty()) return;
        
        String objectApiName = recordIds.iterator().next().getSObjectType().getDescribe().getName();
        PDF_Document_Configuration__mdt config = configByObjectName.get(objectApiName);
        
        if (config == null || String.isEmpty(config.PDF_Count_Field_API_Name__c)) {
            System.debug('No PDF configuration found for: ' + objectApiName);
            return;
        }
        
        List<AggregateResult> pdfCounts = [
            SELECT LinkedEntityId, COUNT(Id) pdfCount
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
            AND ContentDocument.FileType = 'PDF'
            AND ContentDocument.Title LIKE :(config.File_Name_Prefix__c + '%')
            GROUP BY LinkedEntityId
        ];
        
        
        System.debug('PDF Counts found: ' + pdfCounts);
        
        String updateQuery = 'SELECT Id, ' + config.PDF_Count_Field_API_Name__c +
            ' FROM ' + objectApiName +
            ' WHERE Id IN :recordIds';
        
        try {
            List<SObject> records = Database.query(updateQuery);
            Map<Id, Integer> countsByRecordId = new Map<Id, Integer>();
            
            for (AggregateResult ar : pdfCounts) {
                countsByRecordId.put(
                    (Id)ar.get('LinkedEntityId'),
                    (Integer)ar.get('pdfCount')
                );
            }
            List<SObject> recordsToUpdate = new List<SObject>();
            for (SObject record : records) {
                Integer count;
                if(DMLType == 'delete'){
                    count= countsByRecordId.containsKey(record.Id) ?countsByRecordId.get(record.Id) -1 : 0;
                }else if(DMLType == 'insert'){
                    count = countsByRecordId.containsKey(record.Id) ?countsByRecordId.get(record.Id): 0;
                }
                if(count != record.get(config.PDF_Count_Field_API_Name__c)){
                	record.put(config.PDF_Count_Field_API_Name__c, count);
                    recordsToUpdate.add(record);
                }
                System.debug('pdf count on record '+record.get(config.PDF_Count_Field_API_Name__c));
                System.debug('Setting count for ' + record.Id + ' to: ' + count);
            }
            if(!recordsToUpdate.isEmpty()){
                System.debug('recs to update '+recordsToUpdate);
            	update recordsToUpdate;
            }
            System.debug('Records updated successfully');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating PDF counts: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PDFCounterException('Error updating PDF counts: ' + e.getMessage());
        }
    }
    
    public static void updatePDFCountAfterDelete(Set<Id> recordIds) {
        System.debug('UpdatePDFCountAfterDelete called with IDs: ' + recordIds);
        updatePDFCount(recordIds,'delete');
    }
    
    public class PDFCounterException extends Exception {}
}