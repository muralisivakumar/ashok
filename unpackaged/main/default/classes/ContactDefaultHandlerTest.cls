@isTest
private class ContactDefaultHandlerTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create initial contacts
        Contact contact1 = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'John',
            LastName = 'Doe',
            Default_Billing_Contact__c = true,
            Default_Shipping_Contact__c = true
        );
        
        Contact contact2 = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Jane',
            LastName = 'Smith'
        );
        
        insert new List<Contact>{contact1, contact2};
    }
    
    @isTest
    static void testNewDefaultBillingContact() {
        // Get the existing contacts
        Contact existingDefaultContact = [
            SELECT Id, Default_Billing_Contact__c 
            FROM Contact 
            WHERE FirstName = 'John'
        ];
        
        Contact newDefaultContact = [
            SELECT Id, Default_Billing_Contact__c 
            FROM Contact 
            WHERE FirstName = 'Jane'
        ];
        
        // Set the second contact as default billing
        Test.startTest();
        newDefaultContact.Default_Billing_Contact__c = true;
        update newDefaultContact;
        Test.stopTest();
        
        // Verify the changes
        Contact updatedOldContact = [
            SELECT Id, Default_Billing_Contact__c 
            FROM Contact 
            WHERE Id = :existingDefaultContact.Id
        ];
        
        Contact updatedNewContact = [
            SELECT Id, Default_Billing_Contact__c 
            FROM Contact 
            WHERE Id = :newDefaultContact.Id
        ];
        
        // Assert the results
        System.assert(!updatedOldContact.Default_Billing_Contact__c, 
            'Old contact should no longer be default billing contact');
        System.assert(updatedNewContact.Default_Billing_Contact__c, 
            'New contact should be default billing contact');
    }
    
    @isTest
    static void testNewDefaultShippingContact() {
        // Get the existing contacts
        Contact existingDefaultContact = [
            SELECT Id, Default_Shipping_Contact__c 
            FROM Contact 
            WHERE FirstName = 'John'
        ];
        
        Contact newDefaultContact = [
            SELECT Id, Default_Shipping_Contact__c 
            FROM Contact 
            WHERE FirstName = 'Jane'
        ];
        
        // Set the second contact as default shipping
        Test.startTest();
        newDefaultContact.Default_Shipping_Contact__c = true;
        update newDefaultContact;
        Test.stopTest();
        
        // Verify the changes
        Contact updatedOldContact = [
            SELECT Id, Default_Shipping_Contact__c 
            FROM Contact 
            WHERE Id = :existingDefaultContact.Id
        ];
        
        Contact updatedNewContact = [
            SELECT Id, Default_Shipping_Contact__c 
            FROM Contact 
            WHERE Id = :newDefaultContact.Id
        ];
        
        // Assert the results
        System.assert(!updatedOldContact.Default_Shipping_Contact__c, 
            'Old contact should no longer be default shipping contact');
        System.assert(updatedNewContact.Default_Shipping_Contact__c, 
            'New contact should be default shipping contact');
    }
    
    @isTest
    static void testInsertNewDefaultContact() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create and insert a new contact with default flags
        Contact newContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Bob',
            LastName = 'Johnson',
            Default_Billing_Contact__c = true,
            Default_Shipping_Contact__c = true
        );
        
        Test.startTest();
        insert newContact;
        Test.stopTest();
        
        // Query all contacts for the account
        List<Contact> allContacts = [
            SELECT Id, FirstName, Default_Billing_Contact__c, Default_Shipping_Contact__c 
            FROM Contact 
            WHERE AccountId = :testAccount.Id
        ];
        
        // Verify only one contact has each default flag
        Integer billingDefaults = 0;
        Integer shippingDefaults = 0;
        
        for(Contact c : allContacts) {
            if(c.Default_Billing_Contact__c) billingDefaults++;
            if(c.Default_Shipping_Contact__c) shippingDefaults++;
        }
        
        System.assertEquals(1, billingDefaults, 'Should only be one default billing contact');
        System.assertEquals(1, shippingDefaults, 'Should only be one default shipping contact');
    }
}