@isTest
public class autoStatusWindowTest {
    
    @testSetup
    static void setup() {
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;
        
        PricebookEntry integrationPbe = new PricebookEntry(
            Pricebook2Id = integrationPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbe;
        
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account', RecordtypeId = USAccRecType);
        insert acc;
        
        Contact con = new Contact(LastName = 'Test', Email = 'test@test.com', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Approved',
            Quote_PDF_Count__c = 1,
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;
        
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c();
        salesOrder.Name = 'Test Sales Order USD'; 
        salesOrder.varcpq__Stage__c = 'Send Sales Order to Customer';
        salesOrder.SalesOrder_Email_Sent__c = false;
        salesOrder.Sales_Order_PDF_Count__c = 1;
        salesOrder.varcpq__Opportunity__c = opp.Id;
        salesOrder.varcpq__Client__c = acc.Id;
        //salesOrder.varcpq__Billing_Contact__c = con.Id;
        insert salesOrder;
    }
    
    @isTest
    static void testGetQuoteRecordStatus() {
        // Retrieve test data
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        // Test getRecordStatus for Quote
        Test.startTest();
        Map<String, Object> resultQuote = autoStatusWindow.getRecordStatus(quote.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultQuote.get('showPopup'));
        System.assertEquals('Quote', resultQuote.get('objectType'));
    }
    @isTest
    static void testGetSalesorderRecordStatus(){
        varcpq__Sales_Order__c salesOrder = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        // Test getRecordStatus for Sales Order
        Test.startTest();
        Map<String, Object> resultSalesOrder = autoStatusWindow.getRecordStatus(salesOrder.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultSalesOrder.get('showPopup'));
        System.assertEquals('SalesOrder', resultSalesOrder.get('objectType'));
    
}
    @isTest
    static void testUpdateStatus() {
        // Retrieve test data
        Quote quote = [SELECT Id, Status FROM Quote LIMIT 1];
       

        Test.startTest();
        autoStatusWindow.updateStatus(quote.Id);
        Test.stopTest();
        
        quote = [SELECT Status FROM Quote WHERE Id = :quote.Id];
        System.assertEquals('Presented', quote.Status);
    }
        @isTest
        static void testUpdateSalesOrder(){
             varcpq__Sales_Order__c salesOrder = [SELECT Id, varcpq__Stage__c, SalesOrder_Email_Sent__c FROM varcpq__Sales_Order__c LIMIT 1];
        System.debug(salesOrder +'salesOrder');
        // Test updateStatus for Sales Order
        Test.startTest();
        autoStatusWindow.updateStatus(salesOrder.Id);
        Test.stopTest();
        
        salesOrder = [SELECT varcpq__Stage__c, SalesOrder_Email_Sent__c FROM varcpq__Sales_Order__c WHERE Id = :salesOrder.Id];
        System.assertEquals('Pending PO Creation', salesOrder.varcpq__Stage__c);
        System.assertEquals(true, salesOrder.SalesOrder_Email_Sent__c);
    }
}