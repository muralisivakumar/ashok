trigger oppCurrencyChangeTrigger on Opportunity (Before insert) {  
    // Apexify -- Surya -- Ticket #51 -- Added below if condition to Active/In-Active the trigger logic
    if (!TriggerControl.isActive('oppCurrencyChangeTrigger')) {
        return; // Skip main logic
    }
    
    Set<Id> accountIds = new Set<Id>();
    
    for (Opportunity opp : Trigger.new) {
        if (opp.AccountId != null) {
            accountIds.add(opp.AccountId);
        }
    }
    
    Map<Id, Account> accountMap = new Map<Id, Account>([
        SELECT Id, RecordType.Name,OwnerId // Apexify -- Surya -- Ticket #51 - Added OwnerId field in query
        FROM Account
        WHERE Id IN :accountIds
    ]);
    
    for (Opportunity opp : Trigger.new) {
        if (opp.AccountId != null && accountMap.containsKey(opp.AccountId)) {
            String accountRecordType = accountMap.get(opp.AccountId).RecordType.Name;
            Id accountOwnerId = accountMap.get(opp.AccountId).OwnerId; // Apexify -- Surya -- Ticket #51 -- created new variable
            if (accountRecordType == 'US Account') {
                opp.CurrencyIsoCode = 'USD';
            } else if (accountRecordType == 'Canadian Account') {
                opp.CurrencyIsoCode = 'CAD';
            }
            // Apexify -- Surya -- Ticket #51 -- Added below if condition to set the opp owner to account owner
            if(accountOwnerId != null && accountOwnerId != opp.OwnerId){
                opp.OwnerId = accountOwnerId;
            }
        }
    }
    // Apexify -- Surya -- Ticket #51 -- Added below if condition to call handler method to check if owner has multiple ISR's
    if(trigger.isInsert){
        OpportunityMultipleISRHandler.validateISR(trigger.new);
    }
}