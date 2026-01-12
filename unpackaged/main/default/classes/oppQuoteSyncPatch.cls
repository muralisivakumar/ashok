public class oppQuoteSyncPatch {
    public static void syncPatchup(List<OpportunityLineItem> oppLines){
        Set<Id> opliIds = new Set<Id>();
        for(OpportunityLineItem opli : oppLines){
            if(opli.varcpq__Unit_Cost__c == null || opli.varcpq__DH_Line__c == null){
                opliIds.add(opli.Id);
            }
        }
        if(!opliIds.isEmpty()){
            Map<Id,QuoteLineItem> syncedQLis = new Map<Id,QuoteLineItem>();
            for(QuoteLineItem qli: [select id,varcpq__Unit_Cost__c,varcpq__DH_Line__c,varcpq__PartNumber__c,OpportunityLineItemId from QuoteLineItem where Quote.IsSyncing = true and OpportunityLineItemId =: opliIds ]){
                if(!syncedQLIs.containsKey(qli.OpportunityLineItemId)){
                    syncedQlis.put(qli.OpportunityLineItemId, qli);
                }
				System.debug('syncedQlis '+syncedQlis);
            }
            List<opportunityLineItem> updatedOplis = new List<opportunityLineItem>();
            for(opportunityLineItem opli : oppLines){
                if(syncedQLIs.get(opli.Id).varcpq__Unit_Cost__c != null || syncedQLIs.get(opli.Id).varcpq__DH_Line__c != null){
                    opportunityLineItem updOpli = new opportunityLineItem();
                    updOpli.Id = opli.Id;
                    updOpli.varcpq__Unit_Cost__c = syncedQLIs.get(opli.Id).varcpq__Unit_Cost__c;
                    updOpli.varcpq__DH_Line__c = Math.ceil(syncedQLIs.get(opli.Id).varcpq__DH_Line__c);
                    updatedOplis.add(updOpli);
                    System.debug('updatedOplis '+updatedOplis);
                }
            }
            update updatedOplis;
        }
    }
    
    
}