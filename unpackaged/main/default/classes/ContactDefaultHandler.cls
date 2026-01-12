public class ContactDefaultHandler {
    public void handleDefaultContacts(List<Contact> newContacts, Map<Id, Contact> oldContactMap) {
        // Collect Account IDs and contacts that need default status changes
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        
        // Track which accounts have new default contacts
        Map<Id, Contact> accountsNewBillingContact = new Map<Id, Contact>();
        Map<Id, Contact> accountsNewShippingContact = new Map<Id, Contact>();
        
        for(Contact cont : newContacts) {
            Contact oldCont = oldContactMap != null ? oldContactMap.get(cont.Id) : null;
            
            if(cont.Default_Billing_Contact__c || cont.Default_Shipping_Contact__c) {
                accountIds.add(cont.AccountId);
                
                // Check if this is a new default billing contact
                if(cont.Default_Billing_Contact__c && (oldCont == null || !oldCont.Default_Billing_Contact__c)) {
                    accountsNewBillingContact.put(cont.AccountId, cont);
                }
                
                // Check if this is a new default shipping contact
                if(cont.Default_Shipping_Contact__c && (oldCont == null || !oldCont.Default_Shipping_Contact__c)) {
                    accountsNewShippingContact.put(cont.AccountId, cont);
                }
            }
        }
        
        if(accountIds.isEmpty()) return;
        
        // Query existing contacts that have default flags set (excluding the ones being processed)
        Set<Id> newContactIds = new Map<Id, Contact>(newContacts).keySet();
        
        List<Contact> existingContacts = [
            SELECT Id, AccountId, Default_Billing_Contact__c, Default_Shipping_Contact__c
            FROM Contact 
            WHERE AccountId IN :accountIds 
            AND Id NOT IN :newContactIds
            AND (Default_Billing_Contact__c = true OR Default_Shipping_Contact__c = true)
        ];
        
        // Process each account's contacts
        for(Contact newCont : newContacts) {
            for(Contact existingCont : existingContacts) {
                if(existingCont.AccountId == newCont.AccountId) {
                    boolean needsUpdate = false;
                    
                    // If new contact is default billing, uncheck existing default billing
                    if(newCont.Default_Billing_Contact__c && existingCont.Default_Billing_Contact__c) {
                        existingCont.Default_Billing_Contact__c = false;
                        needsUpdate = true;
                    }
                    
                    // If new contact is default shipping, uncheck existing default shipping
                    if(newCont.Default_Shipping_Contact__c && existingCont.Default_Shipping_Contact__c) {
                        existingCont.Default_Shipping_Contact__c = false;
                        needsUpdate = true;
                    }
                    
                    if(needsUpdate) {
                        contactsToUpdate.put(existingCont.Id, existingCont);
                    }
                }
            }
        }
        
        // Update the previous default contacts if any
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
    }
}