@isTest
private class rmaLineItemTriggerHandlerTest {
    static testMethod void testHandleAfterInsert() {
        // Setup Product Trigger
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting;

        // Create CLIN Name
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'CLH-');
        insert CLIN;

        // Step 1: Create test data for Account, Sales Order, and Products
        Account clientAccount = new Account(Name = 'Test Client Account');
        insert clientAccount;

        // Create Product
        Product2 product = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert product;
        
        // Pricebook Setup (Standard Pricebook is always available)
        Id PricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = PricebookId, 
            Product2Id = product.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;

        // Create Sales Order
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
            Name = 'SO-001',
            varcpq__Client__c = clientAccount.Id
        );
        insert salesOrder;

        // Create Sales Order Line Item
        varcpq__Sales_Order_Line_Item__c salesOrderLineItem = new varcpq__Sales_Order_Line_Item__c(
            varcpq__Sales_Order__c = salesOrder.Id,
            varcpq__Product__c = product.Id,
            varcpq__Quantity__c = 10,
            varcpq__Unit_Price__c = 100
            //varcpq__Total_Ext_Price__c = 1000 
        );
        insert salesOrderLineItem;

        // Create Invoice
        varcpq__Invoice__c invoice = new varcpq__Invoice__c(
            varcpq__Client__c = clientAccount.Id,
            varcpq__Sales_Order__c = salesOrder.Id
            //Grand_Total__c = 1000 
        );
        insert invoice;

        // Create Invoice Line Item linked to Sales Order Line Item
        varcpq__Invoice_Line_Item__c invoiceLineItem = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c = invoice.Id,
            varcpq__Sales_Order_Line_Item__c = salesOrderLineItem.Id,
            varcpq__Quantity__c = 10
            //varcpq__Ext_Total__c = 1000, 
            //varcpq__Part_No__c = 'TestPart001'
        );
        insert invoiceLineItem;
        
        varcpq__Purchase_Order__c po = new varcpq__Purchase_Order__c(
        varcpq__PO_Status__c = 'Pending PO Generation',
        varcpq__Sales_Order__c = salesOrder.Id,
        varcpq__Ship_To_Account__c = clientAccount.Id
        );
        insert po;
        
        //Create Return Merchandise Authorization (RMA)
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            //Name = 'RMA-001',
            Account__c = clientAccount.Id,
            PO_Reference__c = po.Id,
            Related_Sales_Order__c = salesOrder.Id,
            Related_Invoice__c = invoice.Id
        );
        insert rma;

        // Step 2: Create Return Merchandise Authorization Line Item (RMA)
        Return_Merchandise_Authorization_Line_It__c rmaLine = new Return_Merchandise_Authorization_Line_It__c(
            Return_Type__c = 'Missing/Lost',
            Invoice_Line_Reference__c = invoiceLineItem.Id,
            Quantity__c = 5,  
            Return_Merchandise_Authorization__c = rma.Id,
            Unit_Price__c = 100
        );

        // Insert the RMA line item (this should trigger the handler)
        Test.startTest();
        insert rmaLine;
        Test.stopTest();

        // Step 3: Assertions
        // Check if new Sales Order Line Items were created for the "Missing/Lost" RMAs
        List<varcpq__Sales_Order_Line_Item__c> newSalesOrderLines = [
            SELECT Id, varcpq__Sales_Order__c, varcpq__Product__c, varcpq__Quantity__c, varcpq__Unit_Price__c
            FROM varcpq__Sales_Order_Line_Item__c
            WHERE varcpq__Sales_Order__c = :salesOrder.Id
        ];

        System.assertEquals(2, newSalesOrderLines.size(), 'Two Sales Order Line Items should have been created.');
        
        // Verify that the second Sales Order Line Item has the expected values
        varcpq__Sales_Order_Line_Item__c newSOItem = newSalesOrderLines[1];
        System.assertEquals(salesOrder.Id, newSOItem.varcpq__Sales_Order__c, 'The new SO Line Item should belong to the same Sales Order.');
        System.assertEquals(product.Id, newSOItem.varcpq__Product__c, 'The new SO Line Item should reference the same product.');
        System.assertEquals(5, newSOItem.varcpq__Quantity__c, 'The quantity should match the RMA Line Item quantity.');
        System.assertEquals(100, newSOItem.varcpq__Unit_Price__c, 'The unit price should match the RMA Line Item unit price.');
    }
}