trigger SetNetTermsOnQuote on Quote (before insert) {
    // Create a map to store Account records related to Quotes
    Map<Id, Account> accountMap = new Map<Id, Account>();

    // Collect Account IDs from Quotes
    for (Quote quote : Trigger.new) {
        if (quote.OpportunityId != null) {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :quote.OpportunityId LIMIT 1];
            if (opp.AccountId != null) {
                accountMap.put(opp.AccountId, null);
            }
        }
    }

    // Query the Accounts and populate the map
    if (!accountMap.isEmpty()) {
        accountMap.putAll([SELECT Id, varcpq__NET_TERMS__c FROM Account WHERE Id IN :accountMap.keySet()]);
    }

    // Set the NET TERMS field on Quotes based on Account's varcpq__NET_TERMS__c
    for (Quote quote : Trigger.new) {
        if (quote.OpportunityId != null) {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :quote.OpportunityId LIMIT 1];
            if (opp.AccountId != null && accountMap.containsKey(opp.AccountId)) {
                Account relatedAccount = accountMap.get(opp.AccountId);
                if (relatedAccount != null && String.isNotBlank(relatedAccount.varcpq__NET_TERMS__c)) {
                    quote.Quote_Net_Terms__c = relatedAccount.varcpq__NET_TERMS__c;
                }
            }
        }
    }
}