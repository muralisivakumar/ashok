trigger SOReferenceUpdateTrigger on varcpq__Sales_Order__c (before update) {
    if(Trigger.isBefore && Trigger.isUpdate){
        Map<Id,Map<String,Id>> referenceMap = new Map<Id,Map<String,Id>>();
        
        for(varcpq__Sales_Order__c so:Trigger.new){
            Map<String,Id> soRefMap = new Map<String,Id>();
            if(Trigger.oldMap.containsKey(so.Id)){
                varcpq__Sales_Order__c oldSO = Trigger.oldMap.get(so.Id);
                if(so.varcpq__Shipping_Address__c != oldSO.varcpq__Shipping_Address__c){
                    soRefMap.put('varcpq__Shipping_Address__c',so.varcpq__Shipping_Address__c);
                }
                if(so.varcpq__Billing_Address__c != oldSO.varcpq__Billing_Address__c){
                    soRefMap.put('varcpq__Billing_Address__c',so.varcpq__Billing_Address__c);
                }
                if(so.varcpq__Shipping_Contact__c != oldSO.varcpq__Shipping_Contact__c){
                    soRefMap.put('varcpq__Shipping_Contact__c',so.varcpq__Shipping_Contact__c);
                }
                if(so.varcpq__Billing_Contact__c != oldSO.varcpq__Billing_Contact__c){
                    soRefMap.put('varcpq__Billing_Contact__c',so.varcpq__Billing_Contact__c);
                }
            }
            referenceMap.put(so.Id,soRefMap);
        }
        SalesOrderRefUpdate.updateReference(referenceMap,Trigger.new);
    }
}