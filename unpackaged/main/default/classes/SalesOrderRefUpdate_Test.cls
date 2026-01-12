@isTest
public class SalesOrderRefUpdate_Test {
    @testSetup
    static void testSetup(){
        Account acc = new Account(
            Name='Test Account',
            Type='Customer'
        );
        Insert acc;
        
        Opportunity opp = new Opportunity(
        	name = 'test opp',
            StageName = 'Identified',
            CloseDate = System.today().addDays(10),
            ForecastCategoryName = 'Omitted',
            AccountId = acc.id
        );
        Insert opp;
        
        Contact conShip = new Contact(
            LastName='Test con Ship',
            Email='testconsoship@test.com',
            Phone='64546544',
            AccountId = acc.Id,
            Default_Shipping_Contact__c = true,
            Active__c = true
        );
        insert conShip;
        
        Contact conBill = new Contact(
            LastName='Test con Bill',
            Email='testconso@test.com',
            Phone='64546544',
            AccountId = acc.Id,
            Default_Billing_Contact__c = true,
            Active__c = true
        );
        insert conBill;
        
        varcpq__Customer_Address__c addShip = new varcpq__Customer_Address__c(
            Name = 'Shipping Address',
            varcpq__Active__c = true,
            varcpq__City__c = 'New York',
            varcpq__Customer__c = acc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '24th Street',
            varcpq__Zipcode__c = '10010',
            Country__c = 'USA',
            Default_Shipping_Address__c = true
        );
        insert addship;
        
        varcpq__Customer_Address__c addBill = new varcpq__Customer_Address__c(
            Name = 'Billing Address',
            varcpq__Active__c = true,
            varcpq__City__c = 'New York',
            varcpq__Customer__c = acc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '24th Street',
            varcpq__Zipcode__c = '10010',
            Country__c = 'USA',
            Default_Billing_Address__c = true
        );
        insert addBill;
        
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
            varcpq__Client__c = acc.Id,
            varcpq__Billing_Address__c = addBill.Id,
            varcpq__Billing_Contact__c = conBill.Id,
            varcpq__Shipping_Address__c = addShip.Id,
            varcpq__Shipping_Contact__c = conShip.Id
        );
        Insert salesOrder;
    }
    
    @isTest
    static void testSORefUpdate1(){
        varcpq__Sales_Order__c salesOrder = [SELECT Id,varcpq__Billing_Address__c,varcpq__Billing_Contact__c FROM varcpq__Sales_Order__c];
        varcpq__Customer_Address__c address = [SELECT Id FROM varcpq__Customer_Address__c WHERE Name ='Shipping Address'];
        salesOrder.varcpq__Billing_Address__c = address.Id;
        update salesOrder;
        
    }
    @isTest
    static void testSORefUpdate2(){
        varcpq__Sales_Order__c salesOrder = [SELECT Id,varcpq__Billing_Address__c,varcpq__Billing_Contact__c,varcpq__Shipping_Address__c FROM varcpq__Sales_Order__c];
        varcpq__Customer_Address__c address = [SELECT Id FROM varcpq__Customer_Address__c WHERE Name ='Billing Address'];
        salesOrder.varcpq__Shipping_Address__c = address.Id;
        update salesOrder;
        
    }
    @isTest
    static void testSORefUpdate3(){
        varcpq__Sales_Order__c salesOrder = [SELECT Id,varcpq__Billing_Address__c,varcpq__Billing_Contact__c FROM varcpq__Sales_Order__c];
        Contact contact = [SELECT Id FROM Contact WHERE Name ='Test con Ship'];
        salesOrder.varcpq__Billing_Contact__c = contact.Id;
        update salesOrder;
        
    }
    @isTest
    static void testSORefUpdate4(){
        varcpq__Sales_Order__c salesOrder = [SELECT Id,varcpq__Billing_Address__c,varcpq__Shipping_Contact__c FROM varcpq__Sales_Order__c];
        Contact contact = [SELECT Id FROM Contact WHERE Name ='Test con Bill'];
        salesOrder.varcpq__Shipping_Contact__c = contact.Id;
        update salesOrder;
        
    }
}