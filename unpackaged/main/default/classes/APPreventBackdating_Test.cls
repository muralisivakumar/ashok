@isTest
public class APPreventBackdating_Test {
    
    @testSetup
    Public Static void createData(){
        
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Accounting_configuration__c accConfig = new Accounting_configuration__c();
        accConfig.Name = 'Clutch Accounting Config';
        accConfig.Days_AR_Issue_Date_Remain_Open__c = 10;
        accConfig.AP_Closed_Books_Date__c = Date.newInstance(2025,09,31);
        accConfig.Is_Active__c = true;
        Insert accConfig;
        
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        Insert acc;
        
        contact con = new contact(LastName='Test',email='test@test.com',accountId=acc.Id);
        Insert con;
        
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
        
        // Create standard pricebook
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        // Create custom pricebook
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;
        
        // Create Product2
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product');
        insert product;
        
        // Create Standard Pricebook Entry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert standardPricebookEntry;
        
        // Create Custom Pricebook Entry for 'Integration Price Book'
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert customPricebookEntry;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'CAD'
        );
        insert opp;
        
        // Create Quote related to the Opportunity
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Status = 'Approved',
            CurrencyIsoCode = 'CAD'
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        
        insert qli;
        
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id,
            Billing_Email__c = 'testbill@test.com',
            Shipping_Email__c = 'testship@test.com',
            varcpq__Billing_Address__c = add.Id,
            varcpq__Shipping_Contact__c = con.Id,
            varcpq__Shipping_Address__c = add.Id
        );
        insert salesOrderUSD;
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c
            (varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 10,varcpq__Unit_Cost__c = 100,
             varcpq__Product__c = product.Id);
        insert SOLI1;
        
        varcpq__purchase_order__c po = new varcpq__purchase_order__c(
            varcpq__Distributor_Terms__c = 'NET30',
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Distributor_Contact__c = con.Id,
            varcpq__Distributor_Name__c = acc.Id,
            varcpq__PO_Date__c = System.Today(),
            varcpq__Ship_To_Account__c = acc.Id,
            varcpq__sales_order__c = salesOrderUSD.Id
        );
        Insert po;
        
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(
            varcpq__Status__c = 'Available',
            varcpq__purchase_order__c = po.Id,
            varcpq__sales_order_line_item__c = SOLI1.Id,
            varcpq__DH_Line__c = 1,
            varcpq__Estimated_Ship_Date__c = System.today().adddays(5),
            varcpq__Quantity__c = 10,
            varcpq__Shipping_Account__c = acc.Id,
            varcpq__Shipping_Address__c = add.Id,
            varcpq__Shipping_Contact__c = con.Id,
            varcpq__AP_Line_Total_Quantity__c = 0,
            varcpq__Unit_Cost__c = 100);
        insert poli;
        
        varcpq__Accounts_Payable_Invoice__c API1 = new varcpq__Accounts_Payable_Invoice__c(
            varcpq__Purchase_Order__c = po.Id , 
            varcpq__Invoice_Date__c = Date.newInstance(2025,10,8)
        );
        insert API1;
        
    }
    
    @isTest
    static void test_updateAP(){
        varcpq__Accounts_Payable_Invoice__c ap= [SELECT Id, varcpq__Invoice_Date__c FROM varcpq__Accounts_Payable_Invoice__c LIMIT 1];
        ap.varcpq__Invoice_Date__c = date.newInstance(2025,10,20);
        update ap;
    }
    
    
    
    
}