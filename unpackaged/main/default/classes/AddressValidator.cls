public class AddressValidator {
    public void handleDefaultAddresses(List<varcpq__Customer_Address__c> newAddresses, 
                                     Map<Id, varcpq__Customer_Address__c> oldAddressMap) {
        
        // Collect Account IDs and addresses that need default status changes
        Set<Id> accountIds = new Set<Id>();
        Map<Id, varcpq__Customer_Address__c> addressesToUpdate = new Map<Id, varcpq__Customer_Address__c>();
        
        // Track which accounts need address updates
        Map<Id, varcpq__Customer_Address__c> accountsNeedingBillingUpdate = new Map<Id, varcpq__Customer_Address__c>();
        Map<Id, varcpq__Customer_Address__c> accountsNeedingShippingUpdate = new Map<Id, varcpq__Customer_Address__c>();
        
        for(varcpq__Customer_Address__c addr : newAddresses) {
            varcpq__Customer_Address__c oldAddr = oldAddressMap != null ? oldAddressMap.get(addr.Id) : null;
            
            if(addr.Default_Billing_Address__c || addr.Default_Shipping_Address__c) {
                accountIds.add(addr.varcpq__Customer__c);
                
                // Check if this is a new default billing address
                if(addr.Default_Billing_Address__c && (oldAddr == null || !oldAddr.Default_Billing_Address__c)) {
                    accountsNeedingBillingUpdate.put(addr.varcpq__Customer__c, addr);
                }
                
                // Check if this is a new default shipping address
                if(addr.Default_Shipping_Address__c && (oldAddr == null || !oldAddr.Default_Shipping_Address__c)) {
                    accountsNeedingShippingUpdate.put(addr.varcpq__Customer__c, addr);
                }
            }
        }
        
        if(accountIds.isEmpty()) return;
        
        // Query ALL existing addresses for these accounts (except the ones just inserted/updated)
        Set<Id> newAddressIds = new Set<Id>();
        for(varcpq__Customer_Address__c addr : newAddresses) {
            newAddressIds.add(addr.Id);
        }
        
        List<varcpq__Customer_Address__c> existingAddresses = [
            SELECT Id, varcpq__Customer__c, Default_Billing_Address__c, Default_Shipping_Address__c,
                   varcpq__Street__c, varcpq__City__c, varcpq__State__c, varcpq__Zipcode__c, Country__c
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c IN :accountIds 
            AND Id NOT IN :newAddressIds
            AND (Default_Billing_Address__c = true OR Default_Shipping_Address__c = true)
        ];
        
        // Process each account's addresses
        for(varcpq__Customer_Address__c newAddr : newAddresses) {
            for(varcpq__Customer_Address__c existingAddr : existingAddresses) {
                if(existingAddr.varcpq__Customer__c == newAddr.varcpq__Customer__c) {
                    boolean needsUpdate = false;
                    
                    // If new address is default billing, uncheck existing default billing
                    if(newAddr.Default_Billing_Address__c && existingAddr.Default_Billing_Address__c) {
                        existingAddr.Default_Billing_Address__c = false;
                        needsUpdate = true;
                    }
                    
                    // If new address is default shipping, uncheck existing default shipping
                    if(newAddr.Default_Shipping_Address__c && existingAddr.Default_Shipping_Address__c) {
                        existingAddr.Default_Shipping_Address__c = false;
                        needsUpdate = true;
                    }
                    
                    if(needsUpdate) {
                        addressesToUpdate.put(existingAddr.Id, existingAddr);
                    }
                }
            }
        }
        
        // Update the previous default addresses if any
        if(!addressesToUpdate.isEmpty()) {
            update addressesToUpdate.values();
        }
        
        // Now update the Account addresses
        if(!accountsNeedingBillingUpdate.isEmpty() || !accountsNeedingShippingUpdate.isEmpty()) {
            // Query for all affected accounts
            List<Account> accountsToUpdate = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                                                   BillingCountry, ShippingStreet, ShippingCity, ShippingState, 
                                                   ShippingPostalCode, ShippingCountry
                                            FROM Account 
                                            WHERE Id IN :accountIds];
            
            for(Account acc : accountsToUpdate) {
                // Update billing address if needed
                if(accountsNeedingBillingUpdate.containsKey(acc.Id)) {
                    varcpq__Customer_Address__c billingAddr = accountsNeedingBillingUpdate.get(acc.Id);
                    acc.BillingStreet = billingAddr.varcpq__Street__c;
                    acc.BillingCity = billingAddr.varcpq__City__c;
                    acc.BillingState = billingAddr.varcpq__State__c;
                    acc.BillingPostalCode = billingAddr.varcpq__Zipcode__c;
                    acc.BillingCountry = billingAddr.Country__c;
                }
                
                // Update shipping address if needed
                if(accountsNeedingShippingUpdate.containsKey(acc.Id)) {
                    varcpq__Customer_Address__c shippingAddr = accountsNeedingShippingUpdate.get(acc.Id);
                    acc.ShippingStreet = shippingAddr.varcpq__Street__c;
                    acc.ShippingCity = shippingAddr.varcpq__City__c;
                    acc.ShippingState = shippingAddr.varcpq__State__c;
                    acc.ShippingPostalCode = shippingAddr.varcpq__Zipcode__c;
                    acc.ShippingCountry = shippingAddr.Country__c;
                }
            }
            
            // Update accounts with new addresses
            update accountsToUpdate;
        }
    }
}