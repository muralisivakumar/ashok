public class searchSupplierCreditQueueHandler {

    @AuraEnabled
    public static List<Supplier_Credit_Queue__c> creditQueues(
        String searchInput,
        String supplierCreditName,
        String supplier,
        String status,
        String linkedRMA,
        String currencyIso,
        String owner,
        datetime processDateTime,
        datetime receivedDateTime
        
    ) {
        // Base query
        
        String soql = 'SELECT Id, Name,Credit_Amount__c, CurrencyIsoCode, Linked_RMA__c,Linked_RMA__r.Name,Linked_RMA__r.Status__c, OwnerId, Owner.Name, Supplier__c,Supplier__r.Name, ' +
                      'Status__c, Timestamp_Processed__c, Timestamp_Received__c ' +
                      'FROM Supplier_Credit_Queue__c WHERE Id != NULL'; 

        // Add filters dynamically
        if (!String.isBlank(searchInput)) {
            //soql += ' AND Name = :searchInput' ;
            
            String searchLike = '%' + searchInput + '%';
            soql += ' AND (' +
                        'Name LIKE :searchLike ' +
                        'OR Status__c LIKE :searchLike ' +
                        'OR CurrencyIsoCode LIKE :searchLike ' +
                        'OR Supplier__r.Name LIKE :searchLike ' +
                        'OR Linked_RMA__r.Name LIKE :searchLike ' +
                        'OR Owner.Name LIKE :searchLike' +
                    ')';
        }
        if (!String.isBlank(supplierCreditName)) {
            soql += ' AND Name =:supplierCreditName';
        }
        if (!String.isBlank(supplier)) {
            soql += ' AND Supplier__c = :supplier';
        }
        if (!String.isBlank(status)) {
            soql += ' AND Status__c = :status';
        }
        if (!String.isBlank(linkedRMA)) {
            soql += ' AND Linked_RMA__c = :linkedRMA';
        }
        if (!String.isBlank(currencyIso)) {
            soql += ' AND CurrencyIsoCode = :currencyIso';
        }
        if (!String.isBlank(owner)) {
            soql += ' AND OwnerId = :owner';
        }
        if (processDateTime!= null) {
            date processedDate = Date.valueOf(processDateTime);
            soql += ' AND DAY_ONLY(Timestamp_Processed__c) = :processedDate';
        }
        if (receivedDateTime != null) {
            date receivedDate = Date.valueOf(receivedDateTime);
            soql += ' AND DAY_ONLY(Timestamp_Received__c) = :receivedDate';
        }

    soql += ' ORDER BY Id';
    System.debug('Final SOQL: ' + soql);
        
     List<Supplier_Credit_Queue__c> results = Database.query(soql);
     System.debug('results----->'+results.size());
        return results;
    }
    
    /*@AuraEnabled
    public static List<Supplier_Credit_Queue__c> loadMoreData(String lastId,String searchInput,
        String supplierCreditName,
        String supplier,
        String status,
        String linkedRMA,
        String currencyIso,
        String owner,
        datetime processDateTime,
        datetime receivedDateTime){
            
            system.debug('processDateTime------->'+processDateTime);
            system.debug('processDateTime------->'+receivedDateTime);
            String soql = 'SELECT Id, Name, CurrencyIsoCode, Linked_RMA__c,Linked_RMA__r.Name,Linked_RMA__r.Status__c, OwnerId, Owner.Name, Supplier__c,Supplier__r.Name, ' +
                      'Status__c, Timestamp_Processed__c, Timestamp_Received__c ' +
                      'FROM Supplier_Credit_Queue__c WHERE Id != NULL'; 

        // Add filters dynamically
        if (!String.isBlank(searchInput)) {
            //soql += ' AND Name = :searchInput' ;
            
            String searchLike = '%' + searchInput + '%';
            soql += ' AND (' +
                        'Name LIKE :searchLike ' +
                        'OR Status__c LIKE :searchLike ' +
                        'OR CurrencyIsoCode LIKE :searchLike ' +
                        'OR Supplier__r.Name LIKE :searchLike ' +
                        'OR Linked_RMA__r.Name LIKE :searchLike ' +
                        'OR Owner.Name LIKE :searchLike' +
                    ')';
        }
        if (!String.isBlank(supplierCreditName)) {
            soql += ' AND Name =:supplierCreditName';
        }
        if (!String.isBlank(supplier)) {
            soql += ' AND Supplier__c = :supplier';
        }
        if (!String.isBlank(status)) {
            soql += ' AND Status__c = :status';
        }
        if (!String.isBlank(linkedRMA)) {
            soql += ' AND Linked_RMA__c = :linkedRMA';
        }
        if (!String.isBlank(currencyIso)) {
            soql += ' AND CurrencyIsoCode = :currencyIso';
        }
        if (!String.isBlank(owner)) {
            soql += ' AND OwnerId = :owner';
        }
        if (processDateTime!= null) {
            date processedDate = Date.valueOf(processDateTime);
            //soql += ' AND DAY_ONLY(Timestamp_Processed__c) = :processedDate';
            soql += ' AND Timestamp_Processed__c >= :processDateTime';
        }
        if (receivedDateTime != null) {
            date receivedDate = Date.valueOf(receivedDateTime);
            //soql += ' AND DAY_ONLY(Timestamp_Received__c) = :receivedDate';
            soql += ' AND Timestamp_Received__c = :receivedDateTime';
        }

    soql += ' AND Id >:lastId ORDER BY Id ASC LIMIT 10';
    System.debug('Final SOQL in loadMoreData: ' + soql);
        
     List<Supplier_Credit_Queue__c> results = Database.query(soql);
     System.debug('results----->'+results.size());
        return results;
      
            
    }*/
    
    
    
     @AuraEnabled
    public static void updateStatus(List<Id> recordIds, String newStatus) {
        system.debug('recordIds----->'+recordIds+' and '+'newStatus------>'+newStatus);
        if (recordIds == null || recordIds.isEmpty() || String.isBlank(newStatus)) {
            return;
        }
        
        List<Supplier_Credit_Queue__c> toUpdate = new List<Supplier_Credit_Queue__c>();
        for (Id recId : recordIds) {
            toUpdate.add(new Supplier_Credit_Queue__c(
                Id = recId,
                Status__c = newStatus
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            system.debug('toUpdate--------------->'+toUpdate);
        }
    }

}