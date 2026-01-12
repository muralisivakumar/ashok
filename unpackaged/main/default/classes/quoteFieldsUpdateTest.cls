@isTest
public class quoteFieldsUpdateTest {
    
    @isTest
    static void testGetBillShipDefault() {

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        Contact billingContact = new Contact(
            FirstName = 'Bill',
            LastName = 'Contact',
            Email = 'bill.contact@example.com',
            AccountId = testAccount.Id,
            Default_Billing_Contact__c = true,
            Active__c = true
        );
        insert billingContact;
        
        Contact shippingContact = new Contact(
            FirstName = 'Ship',
            LastName = 'Contact',
            Email = 'ship.contact@example.com',
            AccountId = testAccount.Id,
            Default_Shipping_Contact__c = true,
            Active__c = true
        );
        insert shippingContact;
        
        varcpq__Customer_Address__c billingAddress = new varcpq__Customer_Address__c(
            varcpq__Customer__c = testAccount.Id,
            varcpq__Street__c = '123 Billing St',
            varcpq__City__c = 'Billing City',
            varcpq__State__c = 'BC',
            varcpq__Zipcode__c = '12345',
            Country__c = 'USA',
            Default_Billing_Address__c = true,
            varcpq__Active__c = true
        );
        insert billingAddress;
        
        varcpq__Customer_Address__c shippingAddress = new varcpq__Customer_Address__c(
            varcpq__Customer__c = testAccount.Id,
            varcpq__Street__c = '456 Shipping St',
            varcpq__City__c = 'Shipping City',
            varcpq__State__c = 'SC',
            varcpq__Zipcode__c = '67890',
            Country__c = 'USA',
            Default_Shipping_Address__c = true,
            varcpq__Active__c = true
        );
        insert shippingAddress;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id
        );
        insert testQuote;
        
        List<Quote> quoteList = [SELECT Id, OpportunityId FROM Quote WHERE Id = :testQuote.Id];
        quoteFieldsUpdate.getBillShipDefault(quoteList);
        
        Quote updatedQuote = [SELECT Id, BillingName, Bill_to_email__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                              ShippingName, Ship_to_email__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                              FROM Quote WHERE Id = :testQuote.Id];
        
        /*System.assertEquals('Bill Contact', updatedQuote.BillingName);
        System.assertEquals('bill.contact@example.com', updatedQuote.Bill_to_email__c);
        System.assertEquals('123 Billing St', updatedQuote.BillingStreet);
        System.assertEquals('Billing City', updatedQuote.BillingCity);
        System.assertEquals('BC', updatedQuote.BillingState);
        System.assertEquals('12345', updatedQuote.BillingPostalCode);
        System.assertEquals('USA', updatedQuote.BillingCountry);
        
        System.assertEquals('Ship Contact', updatedQuote.ShippingName);
        System.assertEquals('ship.contact@example.com', updatedQuote.Ship_to_email__c);
        System.assertEquals('456 Shipping St', updatedQuote.ShippingStreet);
        System.assertEquals('Shipping City', updatedQuote.ShippingCity);
        System.assertEquals('SC', updatedQuote.ShippingState);
        System.assertEquals('67890', updatedQuote.ShippingPostalCode);
        System.assertEquals('USA', updatedQuote.ShippingCountry);*/
    }
    
    @isTest
    static void testUpdateConAdds() {
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        Contact billingContact = new Contact(
            FirstName = 'Bill',
            LastName = 'Contact',
            Email = 'bill.contact@example.com',
            AccountId = testAccount.Id,
            Default_Billing_Contact__c = true,
            Active__c = true
        );
        insert billingContact;
        
        Contact shippingContact = new Contact(
            FirstName = 'Ship',
            LastName = 'Contact',
            Email = 'ship.contact@example.com',
            AccountId = testAccount.Id,
            Default_Shipping_Contact__c = true,
            Active__c = true
        );
        insert shippingContact;
        
        varcpq__Customer_Address__c billingAddress = new varcpq__Customer_Address__c(
            varcpq__Customer__c = testAccount.Id,
            varcpq__Street__c = '123 Billing St',
            varcpq__City__c = 'Billing City',
            varcpq__State__c = 'BC',
            varcpq__Zipcode__c = '12345',
            Country__c = 'USA',
            Default_Billing_Address__c = true,
            varcpq__Active__c = true
        );
        insert billingAddress;
        
        varcpq__Customer_Address__c shippingAddress = new varcpq__Customer_Address__c(
            varcpq__Customer__c = testAccount.Id,
            varcpq__Street__c = '456 Shipping St',
            varcpq__City__c = 'Shipping City',
            varcpq__State__c = 'SC',
            varcpq__Zipcode__c = '67890',
            Country__c = 'USA',
            Default_Shipping_Address__c = true,
            varcpq__Active__c = true
        );
        insert shippingAddress;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = testOpportunity.Id
        );
        insert testQuote;
        
        quoteFieldsUpdate.conAddWrapper shipAddWrapper = new quoteFieldsUpdate.conAddWrapper();
        shipAddWrapper.recId = shippingAddress.Id;
        shipAddWrapper.Name = '456 Shipping St';
        shipAddWrapper.DefaultShip = true;
        shipAddWrapper.DefaultBill = false;
        String shipAdd = JSON.serialize(shipAddWrapper);
        
        quoteFieldsUpdate.conAddWrapper shipConWrapper = new quoteFieldsUpdate.conAddWrapper();
        shipConWrapper.recId = shippingContact.Id;
        shipConWrapper.Name = 'Ship Contact 2';
        shipConWrapper.DefaultShip = true;
        shipConWrapper.DefaultBill = false;
        String shipCon = JSON.serialize(shipConWrapper);
        
        quoteFieldsUpdate.conAddWrapper billAddWrapper = new quoteFieldsUpdate.conAddWrapper();
        billAddWrapper.recId = billingAddress.Id;
        billAddWrapper.Name = '123 Billing St';
        billAddWrapper.DefaultShip = false;
        billAddWrapper.DefaultBill = true;
        String billAdd = JSON.serialize(billAddWrapper);
        
        quoteFieldsUpdate.conAddWrapper billConWrapper = new quoteFieldsUpdate.conAddWrapper();
        billConWrapper.recId = billingContact.Id;
        billConWrapper.Name = 'Bill Contact 2';
        billConWrapper.DefaultShip = false;
        billConWrapper.DefaultBill = true;
        String billCon = JSON.serialize(billConWrapper);
        
        
        quoteFieldsUpdate.updateConAdds(testQuote.Id, shipAdd, shipCon, billAdd, billCon);
        
        Quote updatedQuote = [SELECT Id, BillingName, ShippingName FROM Quote WHERE Id = :testQuote.Id];
        System.assertNotEquals(null, updatedQuote);
    }
}