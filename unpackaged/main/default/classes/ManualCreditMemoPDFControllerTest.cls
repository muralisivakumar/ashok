@isTest
public class ManualCreditMemoPDFControllerTest {
    
     @testSetup
     public static void setupData(){
         
         varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
       /* Id PricebookId = Test.getStandardPricebookId();
        
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
            varcpq__ITEMDESC__c = 'Test Product',
            CurrencyIsoCode = 'USD' 
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
            IsActive = true,
            CurrencyIsoCode = 'USD' 
        );
        insert integrationPbe;*/
         Id standardPricebookId = Test.getStandardPricebookId();

Pricebook2 standardPricebook = new Pricebook2(
    Id = standardPricebookId,
    IsActive = true,
    Name = 'Standard Price Book'
);
upsert standardPricebook;

// create a product
Product2 prod = new Product2(
    Name = 'Test Product', 
    varcpq__LISTPRICE__c = 100.0, 
    IsActive = true,
    varcpq__PARTNUMBER__c = 'Test Product',
    varcpq__ITEMDESC__c = 'Test Product',
    CurrencyIsoCode = 'USD'
);
insert prod;

// ✅ first create standard price entry
PricebookEntry standardPbe = new PricebookEntry(
    Pricebook2Id = standardPricebook.Id, 
    Product2Id = prod.Id, 
    UnitPrice = 100.0, 
    IsActive = true,
    CurrencyIsoCode = 'USD'
);
insert standardPbe;

// now your custom integration pricebook
Pricebook2 integrationPricebook = new Pricebook2(
    Name = 'Integration Price Book', 
    IsActive = true,
    CurrencyIsoCode = 'USD'
);
insert integrationPricebook;

// ✅ then custom pricebook entry (depends on the standard one)
PricebookEntry integrationPbe = new PricebookEntry(
    Pricebook2Id = integrationPricebook.Id, 
    Product2Id = prod.Id, 
    UnitPrice = 100.0, 
    IsActive = true,
    CurrencyIsoCode = 'USD'
);
insert integrationPbe;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        insert acc;
         
        Account distAcc = new Account(Name = 'Test Account Distributor',RecordtypeId=USAccRecType,Type = 'Supplier');
        insert distAcc;
        contact con = new contact(LastName='Test',email='test@test.com',accountId=acc.Id);
        insert con;
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
        
        varcpq__Customer_Address__c addship = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Shipping_Address__c = true,
            Country__c = 'US');
        insert addShip;
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
            Status = 'Presented',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3,
            varcpq__Unit_Cost__c = 50,
            varcpq__DH_Line__c = 1
        );
        insert qli;
         
         varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Shipping_and_Handling__c = 200
        );
        insert salesOrderUSD;
         
         varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c
             (varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000,
             varcpq__Product__c = prod.Id);
        insert SOLI1;
        
        insert new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note', Sales_Order__c=salesOrderUSD.Id);
        insert new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note', Sales_Order__c=salesOrderUSD.Id);
         
        varcpq__Invoice__c inv = new varcpq__invoice__c();
        Inv.varcpq__Sales_Order__c = salesOrderUSD.Id;
        Inv.varcpq__Client__c = salesOrderUSD.varcpq__Client__c;
		Inv.varcpq__Shipping_and_Handling__c = 100;
        Insert inv;
         
         varcpq__Invoice_Line_Item__c invLine = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c = inv.Id,
            varcpq__Sales_Order_Line_Item__c = SOLI1.Id
            //Invoice_Group__c = ig.Id
            //varcpq__Ext_Total__c = 100
        );
        insert invLine;
         
    Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c();
    rma.Account__c = acc.Id;
    rma.Related_Invoice__c = inv.Id;
    rma.Status__c = 'Approved';
    rma.Shipping_Refund__c = 10.00;
    rma.Restocking_Fee__c = 10.00;
    rma.Reason_Code__c = 'Test';
    rma.Related_Sales_Order__c = salesOrderUSD.Id;
       
    Insert rma;
       
    Return_Merchandise_Authorization_Line_It__c rl = new Return_Merchandise_Authorization_Line_It__c();
                    rl.Return_Merchandise_Authorization__c = rma.Id;
                    rl.Invoice_Line_Reference__c = invLine.Id;
                    rl.Quantity__c = 2;
                    rl.Product__c = invLine.Product__c;
                    rl.Unit_Price__c = invLine.varcpq__Unit_Price__c;
                    rl.Total_Ext_Price__c = 10.00;
                    rl.Remaining_Quantity__c = 2;
                    rl.Return_Type__c = 'Return';
                    rl.Reason__c = 'Test Reason';
                    rl.Notes__c = 'Test Note';
                    rl.Related_Sales_Order_Line_Item__c = invLine.varcpq__Sales_Order_Line_Item__c; 
                    rl.Distributor__c = distAcc.Id;
         
         Insert rl;
         
         
         
         Shipping_and_Asset_Tracking__c sat = new Shipping_and_Asset_Tracking__c(
            Invoice_ID__c = inv.Id,
            Part_Number__c = '123',
            Tracking_Number__c = 'TRACK123'
        );
        insert sat;
         
         
         Manual_Credit_Memo__c CreditMemo = new Manual_Credit_Memo__c();
         CreditMemo.Status__c = '';
         CreditMemo.Credit_Amount__c = 10;
         CreditMemo.Description__c = '';
         CreditMemo.Customer_PO__c = '';
         CreditMemo.Account__c = acc.Id;
         CreditMemo.Return_Merchandise_Authorization__c = rma.Id;
         CreditMemo.Invoice_Reference__c = inv.Id;
         CreditMemo.Reason_Code__c = 'Test Reason Code';
         Insert CreditMemo;
      
     }
    
    @isTest
    Public static void testCreditMemoPdf(){
       varcpq__Sales_Order__c salesOrderUSD  = [Select Id from varcpq__Sales_Order__c LIMIT 1];
        Manual_Credit_Memo__c mcm = [SELECT Id FROM Manual_Credit_Memo__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', mcm.Id);
        
        Test.startTest();
        ManualCreditMemoPDFController ctrl = new ManualCreditMemoPDFController();
        Test.stopTest();
        
         System.assertNotEquals(null, ctrl.invoice);
        //System.assert(ctrl.customerNotes.size() > 0);
        //System.assert(ctrl.lineItems.size() > 0);
        //System.assert(ctrl.salesOrder != null);
        //System.assert(ctrl.account != null);
        //System.assert(ctrl.opportunity != null);
        //System.assert(ctrl.invoiceGroups.size() > 0);
        //System.assert(ctrl.shippingAndAssetTracking.size() > 0);
        System.assertNotEquals(null, ctrl.pageOrientation);
        System.assertNotEquals(null, ctrl.companyInfo);
        
    }
    
    @isTest
    static void testGenerateAndSavePDF() {
        Manual_Credit_Memo__c mcm = [SELECT Id FROM Manual_Credit_Memo__c LIMIT 1];
        Test.startTest();
        ContentVersion version = ManualCreditMemoPDFController.generateAndSavePDF(mcm.Id);
        Test.stopTest();
        System.assertNotEquals(null, version);
    }
    
    @isTest
    static void testGenerateAndEmailPDF() {
        Manual_Credit_Memo__c mcm = [SELECT Id FROM Manual_Credit_Memo__c LIMIT 1];
        List<String> emails = new List<String>{'test@example.com'};
        Test.startTest();
        ManualCreditMemoPDFController.generateAndEmailPDF(mcm.Id, emails);
        Test.stopTest();
    }
    
    @isTest
    static void testNoteWrapperLogic() {
        Custom_Note__c note1 = new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note');
        Custom_Note__c note2 = new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note');
        Custom_Note__c note3 = new Custom_Note__c(Note_Type__c='Internal - Other', Compose_Text__c='Other Note');
        insert new List<Custom_Note__c>{note1, note2, note3};

        ManualCreditMemoPDFController.NoteWrapper wrap1 = new ManualCreditMemoPDFController.NoteWrapper(note1);
        ManualCreditMemoPDFController.NoteWrapper wrap2 = new ManualCreditMemoPDFController.NoteWrapper(note2);
        ManualCreditMemoPDFController.NoteWrapper wrap3 = new ManualCreditMemoPDFController.NoteWrapper(note3);

        System.assertEquals('Billing Note', wrap1.text);
        System.assertEquals('Billing Note', wrap1.label);
        System.assertEquals('Shipping Note', wrap2.label);
        //System.assertEquals('Other', wrap3.label);
    }
    @isTest
    static void testSplitDescriptionAndGetLongerDescription() {
        
        String exampleString = 'This is a significantly longer description for testing purposes';
        Test.startTest();
        ManualCreditMemoPDFController.breakLongWord(exampleString,10);
        ManualCreditMemoPDFController.preserveFormatting(exampleString);
        Test.stopTest();
    }

}