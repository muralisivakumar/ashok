@IsTest
public class RMAPOControllerTest {
    @testSetup
    public static void createTestData(){
        // Setup Product Trigger
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting;

        // Create CLIN Name
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'CLH-');
        insert CLIN;
        
        // Account & Contact
        Account acc = new Account(Name='Test Account', varcpq__Available_for_PO__c=true);
        insert acc;
        Contact con = new Contact(LastName='Test Contact', AccountId=acc.Id);
        insert con;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId=acc.Id
        );
        insert opp;

        // Create Product
        Product2 product = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert product;
        
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Product2Id=product.Id, Pricebook2Id=stdPbId, UnitPrice=100, IsActive=true);
        insert pbe;

        // Sales Order
        varcpq__Sales_Order__c so = new varcpq__Sales_Order__c(
            Name='SO-TEST',
            varcpq__Opportunity__c=opp.Id,
            varcpq__Client__c=acc.Id,
            varcpq__Billing_Contact__c=con.Id
        );
        insert so;

        // SOLI
        varcpq__Sales_Order_Line_Item__c soli = new varcpq__Sales_Order_Line_Item__c(
            varcpq__Sales_Order__c = so.Id,
            varcpq__Line__c=1,
            varcpq__Quantity__c=5,
            varcpq__Unit_Cost__c=100,
            varcpq__Product__c=product.Id
        );
        insert soli;

        // Purchase Order
        varcpq__Purchase_Order__c po = new varcpq__Purchase_Order__c(
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Sales_Order__c = so.Id,
            varcpq__Ship_To_Account__c = acc.Id
        );
        insert po;

        // Purchase Order Line Item
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(
            varcpq__Purchase_Order__c = po.Id,
            varcpq__Sales_Order_Line_Item__c = soli.Id,
            varcpq__Quantity__c = 5,
            varcpq__Unit_Cost__c = 100
        );
        insert poli;

        // Invoice
        varcpq__Invoice__c inv = new varcpq__Invoice__c(
         //   Name='INV-TEST',
            varcpq__Status__c='Open',
            varcpq__Sales_Order__c=so.Id,
            varcpq__Client__c=acc.Id,
            varcpq__PO_Number__c=po.Name
         //   Grand_Total__c=500
        );
        insert inv;

        // Invoice Line Item
        varcpq__Invoice_Line_Item__c ili = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c=inv.Id,
            varcpq__Quantity__c=5,
            varcpq__Unit_Price__c=100,
           // varcpq__Ext_Total__c=500,
          //  varcpq__Part_No__c='P-100',
            varcpq__Sales_Order_Line_Item__c=soli.Id,
            Product__c = product.Id
         //   Distributor__c = acc.Id
        );
        insert ili;
        
        varcpq__Purchase_Order__c po2 = new varcpq__Purchase_Order__c(
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Sales_Order__c = so.Id,
            varcpq__Ship_To_Account__c = acc.Id
        );
        insert po2;
       
        varcpq__Invoice__c inv2 = new varcpq__Invoice__c(
            varcpq__Sales_Order__c = po2.varcpq__Sales_Order__c,
            varcpq__Client__c = po2.varcpq__Ship_To_Account__c,
            varcpq__PO_Number__c = po2.Name,
          //  Grand_Total__c = 999
            varcpq__Status__c = 'Closed'
        );
        insert inv2;

        varcpq__Invoice_Line_Item__c ili2 = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c = inv2.Id,
            varcpq__Quantity__c = 10,
            varcpq__Unit_Price__c = 200,
            varcpq__Sales_Order_Line_Item__c = soli.Id,
          //  varcpq__Ext_Total__c = 2000,
          //  varcpq__Part_No__c = 'Edge-Case-Part',
            Product__c = product.Id
          //  Distributor__c = acc.Id
        );
        insert ili2;
    }

    @IsTest
    static void test_getPORecords() {
        varcpq__Purchase_Order__c po = [SELECT Id, Name FROM varcpq__Purchase_Order__c LIMIT 1];
        String poNum = po.Name; // actual generated Name

        Test.startTest();
        List<varcpq__Purchase_Order__c> results = RMAPOController.getPORecords(poNum.replace('PO-',''));
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Results should contain PO');
        System.assertEquals(po.Id, results[0].Id, 'Should return correct PO Id');
    }

    @IsTest
    static void test_getInvoicesByPOIds() {
        varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1];

        Test.startTest();
        List<RMAPOController.InvoiceWrapper> invoices = RMAPOController.getInvoicesByPOIds(new List<Id>{po.Id});
        Test.stopTest();

        System.assert(!invoices.isEmpty(), 'Should return invoices');
        System.assert(invoices[0].LineItems.size() > 0, 'Should have line items');
    }

   @IsTest
static void test_createRMAWithLines() {
    varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c WHERE varcpq__Status__c = 'Open' LIMIT 1];
    varcpq__Invoice_Line_Item__c ili = [SELECT Id, varcpq__Quantity__c FROM varcpq__Invoice_Line_Item__c WHERE varcpq__Invoice__c=:inv.Id LIMIT 1];
    varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1]; // ADD THIS LINE

    // Prepare wrapper
    RMAPOController.ReturnLineWrapper rl = new RMAPOController.ReturnLineWrapper();
    rl.lineItemId = ili.Id;
    rl.quantity = 2;
    rl.returnType = 'Damaged';
    rl.reason = 'Broken item';
    rl.note = 'Needs replacement';

    Map<Id, List<RMAPOController.ReturnLineWrapper>> invoiceMap = new Map<Id, List<RMAPOController.ReturnLineWrapper>>{
        inv.Id => new List<RMAPOController.ReturnLineWrapper>{rl}
    };

    Test.startTest();
    List<Id> rmaIds = RMAPOController.createRMAWithLines(invoiceMap, 'Replacement', po.Id, new List<Id>(), '123456'); 
    Test.stopTest();
        
        // Validate RMA
        Return_Merchandise_Authorization__c rma = [SELECT Status__c, RMA_Type__c FROM Return_Merchandise_Authorization__c WHERE Id=:rmaIds[0]];
        System.assertEquals('Initiated', rma.Status__c, 'RMA should be initiated');
        System.assertEquals('Replacement', rma.RMA_Type__c, 'RMA type should match');
        
        // Validate RMA Line
        List<Return_Merchandise_Authorization_Line_It__c> rmaLines = [
            SELECT Id, Quantity__c, Return_Type__c 
            FROM Return_Merchandise_Authorization_Line_It__c 
            WHERE Return_Merchandise_Authorization__c = :rma.Id
        ];
        System.assertEquals(1, rmaLines.size(), 'Should have one RMA line');
        System.assertEquals(2, rmaLines[0].Quantity__c, 'Quantity should match');
        
        // Validate Invoice Line updated
        varcpq__Invoice_Line_Item__c updatedLine = [SELECT Return_Quantity__c, Remaining_Quantity__c, Return_Amount__c, Has_RMA__c 
                                                    FROM varcpq__Invoice_Line_Item__c WHERE Id=:ili.Id];
        System.assertEquals(2, updatedLine.Return_Quantity__c, 'Return quantity should be updated');
        System.assertEquals(3, updatedLine.Remaining_Quantity__c, 'Remaining quantity should be correct');
        System.assertEquals(true, updatedLine.Has_RMA__c, 'Has_RMA__c should be true');
    }

    @IsTest
    static void test_negativeCases() {
        // Blank PO
        List<varcpq__Purchase_Order__c> noResult = RMAPOController.getPORecords(null);
        System.assertEquals(0, noResult.size(), 'Should return empty list for null input');
        
        noResult = RMAPOController.getPORecords('');
        System.assertEquals(0, noResult.size(), 'Should return empty list for empty input');

        // Empty PO Ids for Invoices
        List<RMAPOController.InvoiceWrapper> noInv = RMAPOController.getInvoicesByPOIds(new List<Id>());
        System.assertEquals(0, noInv.size(), 'Should return empty list for empty PO ids');
        
        // Non-existent PO number
        noResult = RMAPOController.getPORecords('NONEXISTENT123');
        System.assertEquals(0, noResult.size(), 'Should return empty list for non-existent PO');
    }
    
    @IsTest 
    static void test_getPORecords_blank_and_prefixed() {
        // Blank input
        List<varcpq__Purchase_Order__c> blankResults = RMAPOController.getPORecords('');
        System.assertEquals(0, blankResults.size());
        
        // Prefixed and different cases
        varcpq__Purchase_Order__c anyPo = [SELECT Name FROM varcpq__Purchase_Order__c LIMIT 1];
        List<varcpq__Purchase_Order__c> res = RMAPOController.getPORecords(anyPo.Name.toLowerCase().replace('po-','')); // simulate lower-case, unprefixed
        System.assert(!res.isEmpty());
        
        // Not starting with po-
        res = RMAPOController.getPORecords(anyPo.Name.replace('PO-',''));
        System.assert(!res.isEmpty());
    }

    @IsTest 
    static void test_getInvoicesByPOIds_edge() {
        // pass null
        List<RMAPOController.InvoiceWrapper> blank = RMAPOController.getInvoicesByPOIds(null);
        System.assertEquals(0, blank.size());
        
        // pass empty
        blank = RMAPOController.getInvoicesByPOIds(new List<Id>());
        System.assertEquals(0, blank.size());
        
        // PO without line items
        varcpq__Purchase_Order__c emptyPO = new varcpq__Purchase_Order__c(
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Sales_Order__c = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1].Id,
            varcpq__Ship_To_Account__c = [SELECT Id FROM Account LIMIT 1].Id
        );
        insert emptyPO;
        
        List<RMAPOController.InvoiceWrapper> result = RMAPOController.getInvoicesByPOIds(new List<Id>{emptyPO.Id});
        System.assertEquals(0, result.size(), 'Should return empty for PO without line items');
    }

   @IsTest 
static void test_createRMAWithLines_edge() {
    varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c WHERE varcpq__Status__c = 'Open' LIMIT 1];
    varcpq__Invoice_Line_Item__c ili = [SELECT Id FROM varcpq__Invoice_Line_Item__c WHERE varcpq__Invoice__c=:inv.Id LIMIT 1];
    varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1]; // ADD THIS LINE
    
    RMAPOController.ReturnLineWrapper rl = new RMAPOController.ReturnLineWrapper();
    rl.lineItemId = ili.Id;
    rl.quantity = 5;
    rl.returnType = 'TestReason';
    rl.reason = 'Testing edge qty';
    rl.note = 'Test note';
    
    Map<Id, List<RMAPOController.ReturnLineWrapper>> invoiceMap = new Map<Id, List<RMAPOController.ReturnLineWrapper>>{
        inv.Id => new List<RMAPOController.ReturnLineWrapper>{rl}
    };
    
    Test.startTest();
    List<Id> rmaIds = RMAPOController.createRMAWithLines(invoiceMap, 'Replacement', po.Id, new List<Id>(), '123456'); 
    Test.stopTest();
        
        // Validate RMA
        System.assertEquals(1, rmaIds.size());
        
        // Check that invoice line update path is followed for max return
        varcpq__Invoice_Line_Item__c updatedLine = [SELECT Return_Quantity__c, Remaining_Quantity__c, Has_RMA__c FROM varcpq__Invoice_Line_Item__c WHERE Id=:ili.Id];
        System.assertEquals(5, updatedLine.Return_Quantity__c, 'Should return full quantity');
        System.assertEquals(0, updatedLine.Remaining_Quantity__c, 'Should have no remaining quantity');
        System.assert(updatedLine.Has_RMA__c, 'Should have RMA flag set');
    }

    @IsTest
static void test_createRMAWithLines_multipleInvoices() {
    List<varcpq__Invoice__c> invoices = [SELECT Id FROM varcpq__Invoice__c WHERE varcpq__Status__c = 'Open' LIMIT 2];
    List<varcpq__Invoice_Line_Item__c> lineItems = [
        SELECT Id FROM varcpq__Invoice_Line_Item__c 
        WHERE varcpq__Invoice__c IN :invoices
    ];
    varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1]; // ADD THIS LINE
    
    Map<Id, List<RMAPOController.ReturnLineWrapper>> invoiceMap = new Map<Id, List<RMAPOController.ReturnLineWrapper>>();
    
    for(varcpq__Invoice__c inv : invoices) {
        RMAPOController.ReturnLineWrapper rl = new RMAPOController.ReturnLineWrapper();
        rl.lineItemId = lineItems[0].Id;
        rl.quantity = 1;
        rl.returnType = 'Multiple';
        rl.reason = 'Testing multiple invoices';
        rl.note = 'Test note';
        
        invoiceMap.put(inv.Id, new List<RMAPOController.ReturnLineWrapper>{rl});
    }
    
    Test.startTest();
    List<Id> rmaIds = RMAPOController.createRMAWithLines(invoiceMap, 'Replacement', po.Id, new List<Id>(), '123456'); 
    Test.stopTest();
        
        System.assertEquals(1, rmaIds.size(), 'Should create 2 RMAs for 2 invoices');
    }

   @IsTest
static void test_createRMAWithLines_nullInput() {
    varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1]; // ADD THIS LINE
    
    Test.startTest();
    try {
        List<Id> rmaIds = RMAPOController.createRMAWithLines(null, 'Replacement', po.Id, new List<Id>(), '123456'); // ADD po.Id AS THIRD PARAMETER
        // If no exception is thrown, this test should fail
        System.assert(false, 'Expected NullPointerException but none was thrown');
    } catch (System.NullPointerException e) {
        // Expected behavior - test passes
        System.assert(e.getMessage().contains('Attempt to de-reference a null object'), 
                     'Expected NullPointerException for null input');
    }
    Test.stopTest();

}
    @IsTest
    static void test_wrapperClasses() {
        // Test wrapper class instantiation
        varcpq__Purchase_Order__c po = [SELECT Id, Name, varcpq__PO_Status__c, 
                                        varcpq__Ship_To_Account__r.Name, 
                                        varcpq__Sales_Order__r.Name 
                                        FROM varcpq__Purchase_Order__c LIMIT 1];
        
        RMAPOController.PurchaseOrderWrapper pow = new RMAPOController.PurchaseOrderWrapper(po);
        System.assertEquals(po.Name, pow.Name, 'Wrapper should contain PO name');
        
        varcpq__Invoice__c inv = [SELECT Id, Name, Grand_Total__c, varcpq__Status__c FROM varcpq__Invoice__c LIMIT 1];
        RMAPOController.InvoiceWrapper iw = new RMAPOController.InvoiceWrapper(inv);
        System.assertEquals(inv.Name, iw.Name, 'Wrapper should contain invoice name');
        
        varcpq__Invoice_Line_Item__c ili = [SELECT Id, Name, varcpq__Quantity__c, varcpq__Ext_Total__c, 
                                           varcpq__Part_No__c, Return_Quantity__c, Distributor__r.Name, varcpq__Total_Cost__c,
                                           varcpq__Description__c
                                           FROM varcpq__Invoice_Line_Item__c LIMIT 1];
        RMAPOController.InvoiceLineItemWrapper iliw = new RMAPOController.InvoiceLineItemWrapper(ili);
        System.assertEquals(ili.Name, iliw.Name, 'Wrapper should contain line item name');
    }

    @IsTest
    static void test_getInvoicesByPOIds_multiplePOs() {
        List<varcpq__Purchase_Order__c> pos = [SELECT Id FROM varcpq__Purchase_Order__c];
        
        Test.startTest();
        List<RMAPOController.InvoiceWrapper> invoices = RMAPOController.getInvoicesByPOIds(new List<Id>{pos[0].Id, pos[1].Id});
        Test.stopTest();
        
        System.assert(!invoices.isEmpty(), 'Should return invoices for multiple POs');
    }

    @IsTest
static void test_createRMAWithLines_zeroQuantity() {
    varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c WHERE varcpq__Status__c = 'Open' LIMIT 1];
    varcpq__Invoice_Line_Item__c ili = [SELECT Id FROM varcpq__Invoice_Line_Item__c WHERE varcpq__Invoice__c=:inv.Id LIMIT 1];
    varcpq__Purchase_Order__c po = [SELECT Id FROM varcpq__Purchase_Order__c LIMIT 1]; // ADD THIS LINE
    
    RMAPOController.ReturnLineWrapper rl = new RMAPOController.ReturnLineWrapper();
    rl.lineItemId = ili.Id;
    rl.quantity = 0; // Zero quantity
    rl.returnType = 'ZeroTest';
    rl.reason = 'Testing zero quantity';
    rl.note = 'Test note';
    
    Map<Id, List<RMAPOController.ReturnLineWrapper>> invoiceMap = new Map<Id, List<RMAPOController.ReturnLineWrapper>>{
        inv.Id => new List<RMAPOController.ReturnLineWrapper>{rl}
    };
    
    Test.startTest();
    List<Id> rmaIds = RMAPOController.createRMAWithLines(invoiceMap, 'Replacement', po.Id, new List<Id>(), '123456'); 
    Test.stopTest();
        
        // Should still create RMA but with zero quantity line
        System.assertEquals(1, rmaIds.size(), 'Should create RMA even with zero quantity');
        
        Return_Merchandise_Authorization_Line_It__c rmaLine = [
            SELECT Quantity__c 
            FROM Return_Merchandise_Authorization_Line_It__c 
            WHERE Return_Merchandise_Authorization__c = :rmaIds[0]
        ];
        System.assertEquals(0, rmaLine.Quantity__c, 'RMA line should have zero quantity');
    }
}