public class SalesOrderDefaultFilesHandler {
    public static void triggerHandler(List<QuoteLineItem> newQuoteLineItems){
        System.debug('New Quote Line Items: ' + newQuoteLineItems);
        
        // Map of Quote ID to QuoteLineItems
        Map<Id, List<QuoteLineItem>> quoteToLineItemsMap = new Map<Id, List<QuoteLineItem>>();
        Set<Id> productIds = new Set<Id>();
        
        // Populate the map and collect Product2 IDs
        for (QuoteLineItem quoteLineItem : newQuoteLineItems) {
            productIds.add(quoteLineItem.Product2Id);
            if (!quoteToLineItemsMap.containsKey(quoteLineItem.QuoteId)) {
                quoteToLineItemsMap.put(quoteLineItem.QuoteId, new List<QuoteLineItem>());
            }
            quoteToLineItemsMap.get(quoteLineItem.QuoteId).add(quoteLineItem);
        }
        System.debug('Product IDs: ' + productIds);
        System.debug('Quote to Line Items Map: ' + quoteToLineItemsMap);
        
        if (!productIds.isEmpty()) {
            // Fetch associated Products
            Map<Id, Product2> productMap = new Map<Id, Product2>(
                [SELECT Id, Name, varcpq__DH_Supporting_Quote_Line_Item__c
                 FROM Product2
                 WHERE Id IN :productIds]
            );
            System.debug('Product Map: ' + productMap);
            
            // Collect Supporting Quote Part IDs
            Set<Id> supportingQuotePartIds = new Set<Id>();
            for (Product2 product : productMap.values()) {
                if (product.varcpq__DH_Supporting_Quote_Line_Item__c != null) {
                    supportingQuotePartIds.add(product.varcpq__DH_Supporting_Quote_Line_Item__c);
                }
            }
            System.debug('Supporting Quote Part IDs: ' + supportingQuotePartIds);
            
            if (!supportingQuotePartIds.isEmpty()) {
                // Fetch related Supporting Quotes
                Map<Id, varcpq__DH_Supporting_Quote__c> supportingQuoteMap = new Map<Id, varcpq__DH_Supporting_Quote__c>(
                    [SELECT Id, RecordTypeId, varcpq__DH_Supporting_File_Quote__c
                     FROM varcpq__DH_Supporting_Quote__c
                     WHERE Id IN :supportingQuotePartIds]
                );
                System.debug('Supporting Quote Map: ' + supportingQuoteMap);
                
                // Collect Supporting File Quote IDs
                Set<Id> supportingQuoteFileIds = new Set<Id>();
                for (varcpq__DH_Supporting_Quote__c supportingQuote : supportingQuoteMap.values()) {
                    if (supportingQuote.varcpq__DH_Supporting_File_Quote__c != null) {
                        supportingQuoteFileIds.add(supportingQuote.varcpq__DH_Supporting_File_Quote__c);
                    }
                }
                System.debug('Supporting Quote File IDs: ' + supportingQuoteFileIds);
                
                if (!supportingQuoteFileIds.isEmpty()) {
                    // Fetch related Supporting Quote Files
                    List<varcpq__DH_Supporting_Quote__c> supportingQuoteFiles = [
                        SELECT Id, RecordTypeId, varcpq__DH_File_Name__c,
                        varcpq__DH_Supporting_File_Quote__r.varcpq__DH_ContentDocumentId__c
                        FROM varcpq__DH_Supporting_Quote__c
                        WHERE Id IN :supportingQuoteFileIds
                    ];
                    System.debug('Supporting Quote Files: ' + supportingQuoteFiles);
                    
                    // Collect Content Document IDs
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (varcpq__DH_Supporting_Quote__c supportingQuoteFile : supportingQuoteFiles) {
                        if (supportingQuoteFile.varcpq__DH_Supporting_File_Quote__r != null &&
                            supportingQuoteFile.varcpq__DH_Supporting_File_Quote__r.varcpq__DH_ContentDocumentId__c != null) {
                                contentDocumentIds.add(supportingQuoteFile.varcpq__DH_Supporting_File_Quote__r.varcpq__DH_ContentDocumentId__c);
                            }
                    }
                    
                    // Fetch Content Documents
                    Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(
                        [SELECT Id, Title
                         FROM ContentDocument
                         WHERE Id IN :contentDocumentIds]
                    );
                    System.debug('Content Document Map: ' + contentDocumentMap);
                    
                    // Fetch Content Document Links related to the Quotes
                    Set<Id> quoteIds = new Set<Id>(quoteToLineItemsMap.keySet());
                    
                    List<ContentDocumentLink> contentDocumentLinks = [
                        SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title, Visibility
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId IN :quoteIds
                    ];
                    System.debug('Content Document Links: ' + contentDocumentLinks);
                    
                    // Map Quotes to Matching File Names
                    Map<Id, String> quoteToFileNamesMap = new Map<Id, String>();
                    for (ContentDocumentLink documentLink : contentDocumentLinks) {
                        Id quoteId = documentLink.LinkedEntityId;
                        ContentDocument document = contentDocumentMap.get(documentLink.ContentDocumentId);
                        
                        if (document != null) {
                            String currentFileNames = quoteToFileNamesMap.get(quoteId);
                            if (currentFileNames == null) currentFileNames = '';
                            quoteToFileNamesMap.put(quoteId, currentFileNames + document.Title + ';');
                        }
                    }
                    
                    System.debug('Quote to File Names Map: ' + quoteToFileNamesMap);
    				List<Quote> quoteList = new List<Quote>();
                    if(!quoteToFileNamesMap.isEmpty()){
                        for(Id quoteId : quoteToFileNamesMap.keySet()){
                            if(quoteToFileNamesMap.get(quoteId) != null){
                                Quote qt = new Quote();
                                qt.Id = quoteId;
                                if(String.isBlank(qt.Sales_Order_Default_Files__c)){
                                    qt.Sales_Order_Default_Files__c = quoteToFileNamesMap.get(quoteId);
                                    qt.Supplier_Quote_File__c = quoteToFileNamesMap.get(quoteId);
                                }else{
                                    qt.Sales_Order_Default_Files__c += quoteToFileNamesMap.get(quoteId);
                                    qt.Supplier_Quote_File__c += quoteToFileNamesMap.get(quoteId);
                                }
                                quoteList.add(qt);
                            }
                        }
                    }
                    System.debug('quoteList '+quoteList);
                    update quoteList;
                }
            }
        }  
    }
}