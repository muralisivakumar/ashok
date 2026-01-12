@isTest
public class invoicePdfController_Test {

    @testSetup
    static void setupData() {
        Id usRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        Account acc = new Account(Name='Test Account', RecordTypeId=usRecTypeId);
        insert acc;

        Contact con = new Contact(FirstName='John', LastName='Doe', Email='john.doe@example.com', AccountId=acc.Id);
        insert con;

        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id, StageName='Prospecting', CloseDate=Date.today().addDays(10));
        insert opp;

        varcpq__Sales_Order__c so = new varcpq__Sales_Order__c(
            Name = 'Test SO',
            varcpq__Opportunity__c = opp.Id,
            varcpq__Client__c = acc.Id,
            CurrencyIsoCode = 'USD',
            Billing_Email__c = 'bill@example.com',
            Shipping_Email__c = 'ship@example.com'
        );
        insert so;
        

        insert new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note', Sales_Order__c=so.Id);
        insert new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note', Sales_Order__c=so.Id);

        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Sales_Order__c = so.Id
        );
        insert inv;

        Invoice_Group__c ig = new Invoice_Group__c(Name='Test Group', Invoice__c=inv.Id, Sequence__c=1, Sub_Total__c=100);
        insert ig;

        varcpq__Sales_Order_Line_Item__c soli = new varcpq__Sales_Order_Line_Item__c(
            varcpq__Sales_Order__c = so.Id,
            varcpq__Line__c = 1,
            varcpq__Quantity__c = 2,
            varcpq__Unit_Cost__c = 50
            //varcpq__Total_Ext_Price__c = 100
        );
        insert soli;

        varcpq__Invoice_Line_Item__c ili = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c = inv.Id,
            varcpq__Sales_Order_Line_Item__c = soli.Id,
            Invoice_Group__c = ig.Id
            //varcpq__Ext_Total__c = 100
        );
        insert ili;

        Shipping_and_Asset_Tracking__c sat = new Shipping_and_Asset_Tracking__c(
            Invoice_ID__c = inv.Id,
            Part_Number__c = '123',
            Tracking_Number__c = 'TRACK123'
        );
        insert sat;
        //Added as part of #84 ASN by Vishnu S on 6/Jan/26
        //start 
        varcpq__Purchase_Order__c po = new varcpq__Purchase_Order__c(
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Sales_Order__c = so.Id,
            varcpq__Ship_To_Account__c = acc.Id
        );
        insert po;
         Asset newAsset = new Asset(Name='Test Asset',AccountId = acc.Id,varcpq__Sales_Order__c = so.Id,Quantity  = 10);
        insert newAsset;
        
         Shipment_Tracking__c st = new Shipment_Tracking__c(
            Invoice_ID__c = inv.Id,
            Part_Number__c = '123',
            Tracking_Number__c = 'TRACK123',
            Purchase_Order__c = po.Id,
            Asset__c = newAsset.Id
        );
        insert st;
        //end
    }

    @isTest
    static void testConstructorAndLoadData() {
        varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        InvoicePDFController ctrl = new InvoicePDFController();
        Test.stopTest();

        System.assertNotEquals(null, ctrl.invoice);
        System.assert(ctrl.customerNotes.size() > 0);
        System.assert(ctrl.lineItems.size() > 0);
        System.assert(ctrl.salesOrder != null);
        System.assert(ctrl.account != null);
        System.assert(ctrl.opportunity != null);
        System.assert(ctrl.invoiceGroups.size() > 0);
        //Added as part of #84 ASN by Vishnu S on 6/Jan/26
        //System.assert(ctrl.shippingAndAssetTracking.size() > 0);
        System.assert(ctrl.shipmentTracking.size() > 0);
        //end
        System.assertNotEquals(null, ctrl.pageOrientation);
        System.assertNotEquals(null, ctrl.companyInfo);
    }

    @isTest
    static void testGenerateAndSavePDF() {
        varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c LIMIT 1];
        Test.startTest();
        ContentVersion version = InvoicePDFController.generateAndSavePDF(inv.Id);
        Test.stopTest();
        System.assertNotEquals(null, version);
    }

    @isTest
    static void testGenerateAndEmailPDF() {
        varcpq__Invoice__c inv = [SELECT Id FROM varcpq__Invoice__c LIMIT 1];
        List<String> emails = new List<String>{'test@example.com'};
        Test.startTest();
        InvoicePDFController.generateAndEmailPDF(inv.Id, emails);
        Test.stopTest();
    }

    @isTest
    static void testNoteWrapperLogic() {
        Custom_Note__c note1 = new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note');
        Custom_Note__c note2 = new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note');
        Custom_Note__c note3 = new Custom_Note__c(Note_Type__c='Internal - Other', Compose_Text__c='Other Note');
        insert new List<Custom_Note__c>{note1, note2, note3};

        InvoicePDFController.NoteWrapper wrap1 = new InvoicePDFController.NoteWrapper(note1);
        InvoicePDFController.NoteWrapper wrap2 = new InvoicePDFController.NoteWrapper(note2);
        InvoicePDFController.NoteWrapper wrap3 = new InvoicePDFController.NoteWrapper(note3);

        System.assertEquals('Billing Note', wrap1.text);
        System.assertEquals('Billing Note', wrap1.label);
        System.assertEquals('Shipping Note', wrap2.label);
        //System.assertEquals('Other', wrap3.label);
    }

    @isTest
    static void testCompareToLogic() {
        Invoice_Group__c group1 = new Invoice_Group__c(Name='Group1', Sequence__c=1);
        Invoice_Group__c group2 = new Invoice_Group__c(Name='Group2', Sequence__c=2);
        insert new List<Invoice_Group__c>{group1, group2};

        InvoicePDFController.InvoiceGroup ig1 = new InvoicePDFController.InvoiceGroup(group1);
        InvoicePDFController.InvoiceGroup ig2 = new InvoicePDFController.InvoiceGroup(group2);

        System.assertEquals(-1, ig1.compareTo(ig2));
        System.assertEquals(1, ig2.compareTo(ig1));
        System.assertEquals(0, ig1.compareTo(ig1));
    }

    @isTest
    static void testCalculateTotalsFallback() {
        Invoice_Group__c groups = new Invoice_Group__c(Name='Group No Subtotal', Sequence__c=1);
        insert groups;

        varcpq__Invoice_Line_Item__c ili = [SELECT Id, varcpq__Ext_Total__c FROM varcpq__Invoice_Line_Item__c LIMIT 1];

        InvoicePDFController.InvoiceGroup ig = new InvoicePDFController.InvoiceGroup(groups);
        ig.lineItems.add(ili);
        ig.calculateTotals();

        System.assertEquals(ili.varcpq__Ext_Total__c, ig.subtotal);
    }
      @isTest
    static void testSplitDescriptionAndGetLongerDescription() {
        
        String exampleString = 'This is a significantly longer description for testing purposes';
        Test.startTest();
        InvoicePDFController.breakLongWord(exampleString,10);
        InvoicePDFController.preserveFormatting(exampleString);
        Test.stopTest();
    }
}