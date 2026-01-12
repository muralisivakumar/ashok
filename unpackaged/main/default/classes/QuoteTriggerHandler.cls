public class QuoteTriggerHandler {

    @TestVisible
    public static Boolean testForceApproval = false;
    private static Boolean hasRun = false;

    public static void beforeUpdate(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap) {
        System.debug('Total Quotes received: ' + newQuoteList.size());
        // Collect Quote IDs that transition from Draft to non-Draft
        Set<Id> quoteIdSet = new Set<Id>();
        
        for (Quote newQuote : newQuoteList) {
            Quote oldQuote = oldQuoteMap.get(newQuote.Id);
            System.debug('Quote Id: ' + newQuote.Id + ' | Old Status: ' + oldQuote.Status + ' | New Status: ' + newQuote.Status);
            
            // Only process when OLD status is Draft AND NEW status is NOT Draft
            if (oldQuote.Status == 'Draft' && newQuote.Status != 'Draft') {
                quoteIdSet.add(newQuote.Id);
            }
        }
        
        // Only proceed if there are qualifying quotes
        if (!quoteIdSet.isEmpty()) {
            updateIsAppleDealNotRegsitered(newQuoteList, oldQuoteMap, quoteIdSet);
        }
    }

    private static void updateIsAppleDealNotRegsitered(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap, Set<Id> quoteIdSet) {
         System.debug('Processing Quote IDs: ' + quoteIdSet);
        // Get Opportunity Registered Flag for each Quote
        Map<Id, Boolean> oppRegisteredMap = new Map<Id, Boolean>();
        
        for (Quote quote : [
            SELECT Id, Opportunity.varcpq__Registered__c
            FROM Quote
            WHERE Id IN :quoteIdSet
        ]) {
            oppRegisteredMap.put(quote.Id, quote.Opportunity.varcpq__Registered__c);
        }

        // Find which Quotes satisfy CRO Quantity/Product Rule
        Map<Id, Boolean> croRuleMatchMap = new Map<Id, Boolean>();
        
        for (AggregateResult ar : [
            SELECT QuoteId qId
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIdSet
            AND (
                (
                    (Product2.Name LIKE '%mac%' OR Product2.Description LIKE '%mac%')
                    AND Quantity >= 25
                )
                OR
                (
                    (Product2.Name LIKE '%ipad%' OR Product2.Description LIKE '%ipad%')
                    AND Quantity >= 50
                )
                OR
                (
                    (Product2.Name LIKE '%iphone%' OR Product2.Description LIKE '%iphone%')
                    AND Quantity >= 100
                )
            )
            GROUP BY QuoteId
        ]) {
            croRuleMatchMap.put((Id) ar.get('qId'), true);
        }

        // Determine final flag value for each Quote
        for (Quote newQuote : newQuoteList) {
            
            // Skip if not in our filtered set
            if (!quoteIdSet.contains(newQuote.Id)) {
                continue;
            }
            
            Boolean ruleMatch = croRuleMatchMap.containsKey(newQuote.Id);
            Boolean isRegistered = oppRegisteredMap.get(newQuote.Id);
             System.debug('ruleMatch ' + croRuleMatchMap.containsKey(newQuote.Id));
            System.debug('isRegistered ' + oppRegisteredMap.get(newQuote.Id));
            // Set flag when deal is not registered and matches CRO rule
            Boolean requires = (!isRegistered && ruleMatch) 
                            || (Test.isRunningTest() && testForceApproval);

            newQuote.isAppleDealNotRegistered__c = requires;
            System.debug('isApple+++ ' + newQuote.isAppleDealNotRegistered__c);
        }
    }

    public static void afterUpdate(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap) {
        
        if (hasRun) return;
        hasRun = true;

        // Collect Quote IDs where isAppleDealNotRegistered__c is true and status is not Draft
        Set<Id> quoteIdSet = new Set<Id>();
       
        
        for (Quote newQuote : newQuoteList) {
             System.debug('isAppleDeal+ ' + newQuoteList[0].isAppleDealNotRegistered__c);
             System.debug('isAppleRegistered ' + newQuote.isAppleDealNotRegistered__c);
            if (newQuote.isAppleDealNotRegistered__c && newQuote.Status != 'Draft') {
                quoteIdSet.add(newQuote.Id);
            }
        }
        
        // Only proceed if there are qualifying quotes
        if (!quoteIdSet.isEmpty()) {
            submitAppleDealForCROApproval(newQuoteList, quoteIdSet);
        }
    }

    private static void submitAppleDealForCROApproval(List<Quote> newQuoteList, Set<Id> quoteIdSet) {
    System.debug('Processing Quote IDs: ' + quoteIdSet);
    
    // Check which quotes are already in an approval process
    Set<Id> quotesAlreadyInApproval = new Set<Id>();
    for (ProcessInstance pi : [
        SELECT TargetObjectId 
        FROM ProcessInstance 
        WHERE TargetObjectId IN :quoteIdSet 
        AND Status = 'Pending'
    ]) {
        quotesAlreadyInApproval.add(pi.TargetObjectId);
    }
    
    // Bulk Approval Submission
    List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
    
    for (Quote quote : newQuoteList) {
        
        if (!quoteIdSet.contains(quote.Id)) {
            continue;
        }
        
        // Skip if already in approval process
        if (quotesAlreadyInApproval.contains(quote.Id)) {
            System.debug('Quote ' + quote.Id + ' already in approval - skipping');
            continue;
        }

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(quote.Id);
        request.setComments('Quote submitted for CRO Approval');
        approvalRequests.add(request);
    }

    if (!approvalRequests.isEmpty()) {
        Approval.process(approvalRequests);
    }
}
}