public class UpdateOLIsFromQuoteQueueable implements Queueable {
    private List<Id> oppIds;

    public UpdateOLIsFromQuoteQueueable(List<Id> oppIds) {
        this.oppIds = oppIds;
    }

    public void execute(QueueableContext context) {
        // 1. Get synced quotes
        Map<Id, Id> oppToQuoteMap = new Map<Id, Id>();
        for (Opportunity opp : [SELECT Id, SyncedQuoteId FROM Opportunity WHERE Id IN :oppIds]) {
            if (opp.SyncedQuoteId != null) {
                oppToQuoteMap.put(opp.Id, opp.SyncedQuoteId);
            }
        }

        if (oppToQuoteMap.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>(oppToQuoteMap.values());

        // 2. Get QLIs with updated DH_Line values
        Map<Id, QuoteLineItem> qliByOliId = new Map<Id, QuoteLineItem>();
        for (Quote qt : [SELECT Id, 
                         (SELECT Id, varcpq__DH_Line__c, varcpq__Unit_Cost__c, OpportunityLineItemId 
                          FROM QuoteLineItems) 
                         FROM Quote WHERE Id IN :quoteIds]) {
            for (QuoteLineItem qli : qt.QuoteLineItems) {
                if (qli.OpportunityLineItemId != null) {
                    qliByOliId.put(qli.OpportunityLineItemId, qli);
                }
            }
        }

        // 3. Build list of OLI updates
        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        for (Id oliId : qliByOliId.keySet()) {
            QuoteLineItem qli = qliByOliId.get(oliId);
            OpportunityLineItem oli = new OpportunityLineItem(
                Id = oliId,
                varcpq__DH_Line__c = Math.ceil(qli.varcpq__DH_Line__c),
                varcpq__Unit_Cost__c = qli.varcpq__Unit_Cost__c
            );
            toUpdate.add(oli);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}