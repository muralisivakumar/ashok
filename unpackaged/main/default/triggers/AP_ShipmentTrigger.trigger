trigger AP_ShipmentTrigger on varcpq__Accounts_Payable_Invoice__c (after update) {
    //Trigger to update the shipping and asset tracking with invoice id
    if(Trigger.isAfter && Trigger.isUpdate){
        Set<Id> apiIds = new Set<Id>();
        for(varcpq__Accounts_payable_invoice__c api:trigger.new){
            if(Trigger.oldMap.get(api.Id).Invoice__c != api.Invoice__c){
                apiIds.add(api.Id);
            }
        }
        System.debug('apiIds '+apiIds);
        Map<Id,Shipping_and_Asset_Tracking__c> sats = new Map<Id,Shipping_and_Asset_Tracking__c>([SELECT Id,Accounts_Payable_Invoice__c,Invoice_ID__c 
                                                     FROM Shipping_and_Asset_Tracking__c 
                                                     WHERE Accounts_Payable_Invoice__c=:apiIds]);
        for(Shipping_and_Asset_Tracking__c sat:sats.values()){
            sat.Invoice_ID__c = trigger.newMap.get(sat.Accounts_Payable_Invoice__c).Invoice__c;
        }
        if(!sats.values().isEmpty()){
            update sats.values();
        }
       
    }
}