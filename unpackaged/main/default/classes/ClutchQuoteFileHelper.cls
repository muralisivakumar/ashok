public class ClutchQuoteFileHelper {
    /**
     * Updates the Quote_PDF_Count__c field on affected Quotes by counting
     * the number of files linked to the Quote where the file title starts
     * with 'ClutchQuote' and the file type is PDF.
     *
     * @param quoteIds Set of Quote IDs to update
     */
    public static void updateQuotePdfCount(Set<Id> quoteIds) {
        System.debug('ClutchQuoteFileHelper.updateQuotePdfCount called with quoteIds: ' + quoteIds);

        if (quoteIds == null || quoteIds.isEmpty()) {
            System.debug('No Quote IDs provided. Exiting method.');
            return;
        }

        // Query for relevant files
        List<AggregateResult> pdfCounts = [
            SELECT LinkedEntityId, COUNT(Id)
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :quoteIds
              AND ContentDocument.Title LIKE 'ClutchQuote%'
              AND ContentDocument.FileType = 'PDF'
            GROUP BY LinkedEntityId
        ];

        System.debug('PDF Counts from query: ' + pdfCounts);

        // Map for storing counts
        Map<Id, Integer> quotePdfCountMap = new Map<Id, Integer>();
        for (AggregateResult result : pdfCounts) {
            quotePdfCountMap.put((Id) result.get('LinkedEntityId'), (Integer) result.get('expr0'));
        }

        // Prepare updates for affected Quotes
        List<Quote> quotesToUpdate = new List<Quote>();
        for (Id quoteId : quoteIds) {
            Integer count = quotePdfCountMap.containsKey(quoteId) ? quotePdfCountMap.get(quoteId) : 0;
            System.debug('Updating Quote with ID: ' + quoteId + ' to count: ' + count);
            quotesToUpdate.add(new Quote(Id = quoteId, Quote_PDF_Count__c = count));
        }

        // Perform update
        if (!quotesToUpdate.isEmpty()) {
            try {
                update quotesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Quote_PDF_Count__c: ' + e.getMessage());
            }
        }
    }
    public static void updateQuotePdfCountAfterDelete(Set<Id> quoteIds) {
        System.debug('ClutchQuoteFileHelper.updateQuotePdfCountAfterDelete called with quoteIds: ' + quoteIds);

        if (quoteIds == null || quoteIds.isEmpty()) {
            System.debug('No Quote IDs provided. Exiting method.');
            return;
        }

        // Query for relevant files
        List<AggregateResult> pdfCounts = [
            SELECT LinkedEntityId, COUNT(Id)
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :quoteIds
              AND ContentDocument.Title LIKE 'ClutchQuote%'
              AND ContentDocument.FileType = 'PDF'
            GROUP BY LinkedEntityId
        ];

        System.debug('PDF Counts from query: ' + pdfCounts);

        // Map for storing counts
        Map<Id, Integer> quotePdfCountMap = new Map<Id, Integer>();
        for (AggregateResult result : pdfCounts) {
            quotePdfCountMap.put((Id) result.get('LinkedEntityId'), (Integer) result.get('expr0'));
        }

        // Prepare updates for affected Quotes
        List<Quote> quotesToUpdate = new List<Quote>();
        for (Id quoteId : quoteIds) {
            Integer count = quotePdfCountMap.containsKey(quoteId) ? quotePdfCountMap.get(quoteId) -1 : 0;
            System.debug('Updating Quote with ID: ' + quoteId + ' to count: ' + count);
            quotesToUpdate.add(new Quote(Id = quoteId, Quote_PDF_Count__c = count));
        }

        // Perform update
        if (!quotesToUpdate.isEmpty()) {
            try {
                update quotesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Quote_PDF_Count__c: ' + e.getMessage());
            }
        }
    }
}