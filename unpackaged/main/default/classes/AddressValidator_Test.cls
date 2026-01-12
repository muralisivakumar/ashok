@IsTest
private class AddressValidator_Test {
    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }
    
    private static varcpq__Customer_Address__c createAddress(Id accountId, Boolean isDefaultBilling, Boolean isDefaultShipping) {
        varcpq__Customer_Address__c addr = new varcpq__Customer_Address__c(
            varcpq__Customer__c = accountId,
            Default_Billing_Address__c = isDefaultBilling,
            Default_Shipping_Address__c = isDefaultShipping
        );
        return addr;
    }
    
    @IsTest
    static void testChangeDefaultBilling() {
        // Test changing default billing from one address to another
        Account acc = createTestAccount();
        
        // Create first address as default billing
        varcpq__Customer_Address__c addr1 = createAddress(acc.Id, true, false);
        insert addr1;
        
        // Create second address as default billing
        varcpq__Customer_Address__c addr2 = createAddress(acc.Id, true, false);
        insert addr2;
        
        // Verify results
        List<varcpq__Customer_Address__c> addresses = [
            SELECT Default_Billing_Address__c 
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c = :acc.Id
            ORDER BY CreatedDate
        ];
        
        System.assertEquals(2, addresses.size(), 'Should have two addresses');
        System.assertEquals(false, addresses[0].Default_Billing_Address__c, 'First address should no longer be default billing');
        System.assertEquals(true, addresses[1].Default_Billing_Address__c, 'Second address should be default billing');
    }
    
    @IsTest
    static void testChangeDefaultShipping() {
        // Test changing default shipping from one address to another
        Account acc = createTestAccount();
        
        // Create first address as default shipping
        varcpq__Customer_Address__c addr1 = createAddress(acc.Id, false, true);
        insert addr1;
        
        // Create second address and make it default shipping
        varcpq__Customer_Address__c addr2 = createAddress(acc.Id, false, true);
        insert addr2;
        
        // Verify results
        List<varcpq__Customer_Address__c> addresses = [
            SELECT Default_Shipping_Address__c 
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c = :acc.Id
            ORDER BY CreatedDate
        ];
        
        System.assertEquals(2, addresses.size(), 'Should have two addresses');
        System.assertEquals(false, addresses[0].Default_Shipping_Address__c, 'First address should no longer be default shipping');
        System.assertEquals(true, addresses[1].Default_Shipping_Address__c, 'Second address should be default shipping');
    }
    
    @IsTest
    static void testSwitchBothDefaults() {
        // Test switching both defaults to a new address
        Account acc = createTestAccount();
        
        // Create first address with both defaults
        varcpq__Customer_Address__c addr1 = createAddress(acc.Id, true, true);
        insert addr1;
        
        // Create second address and make it both defaults
        varcpq__Customer_Address__c addr2 = createAddress(acc.Id, true, true);
        insert addr2;
        
        // Verify results
        List<varcpq__Customer_Address__c> addresses = [
            SELECT Default_Billing_Address__c, Default_Shipping_Address__c 
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c = :acc.Id
            ORDER BY CreatedDate
        ];
        
        System.assertEquals(2, addresses.size(), 'Should have two addresses');
        System.assertEquals(false, addresses[0].Default_Billing_Address__c, 'First address should no longer be default billing');
        System.assertEquals(false, addresses[0].Default_Shipping_Address__c, 'First address should no longer be default shipping');
        System.assertEquals(true, addresses[1].Default_Billing_Address__c, 'Second address should be default billing');
        System.assertEquals(true, addresses[1].Default_Shipping_Address__c, 'Second address should be default shipping');
    }
    
    @IsTest
    static void testMultipleAccountsIndependent() {
        // Test that changing defaults on one account doesn't affect another
        Account acc1 = createTestAccount();
        Account acc2 = createTestAccount();
        
        // Create default addresses for both accounts
        varcpq__Customer_Address__c addr1 = createAddress(acc1.Id, true, true);
        varcpq__Customer_Address__c addr2 = createAddress(acc2.Id, true, true);
        insert new List<varcpq__Customer_Address__c>{addr1, addr2};
        
        // Create new default for first account
        varcpq__Customer_Address__c addr3 = createAddress(acc1.Id, true, true);
        insert addr3;
        
        // Verify results
        List<varcpq__Customer_Address__c> account1Addresses = [
            SELECT Default_Billing_Address__c, Default_Shipping_Address__c 
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c = :acc1.Id
            ORDER BY CreatedDate
        ];
        
        List<varcpq__Customer_Address__c> account2Addresses = [
            SELECT Default_Billing_Address__c, Default_Shipping_Address__c 
            FROM varcpq__Customer_Address__c 
            WHERE varcpq__Customer__c = :acc2.Id
        ];
        
        // Check account 1 addresses
        System.assertEquals(2, account1Addresses.size(), 'Should have two addresses for account 1');
        System.assertEquals(false, account1Addresses[0].Default_Billing_Address__c, 'First address should no longer be default billing');
        System.assertEquals(false, account1Addresses[0].Default_Shipping_Address__c, 'First address should no longer be default shipping');
        System.assertEquals(true, account1Addresses[1].Default_Billing_Address__c, 'New address should be default billing');
        System.assertEquals(true, account1Addresses[1].Default_Shipping_Address__c, 'New address should be default shipping');
        
        // Check account 2 address
        System.assertEquals(1, account2Addresses.size(), 'Should have one address for account 2');
        System.assertEquals(true, account2Addresses[0].Default_Billing_Address__c, 'Account 2 address should still be default billing');
        System.assertEquals(true, account2Addresses[0].Default_Shipping_Address__c, 'Account 2 address should still be default shipping');
    }
}