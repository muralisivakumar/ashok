@isTest
public class salesOrderPDFController_Test {

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
            CurrencyIsoCode = 'USD',
            Billing_Email__c = 'bill@example.com',
            Shipping_Email__c = 'ship@example.com',
            varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id
            //Tax_Rate__c = 10
        );
        insert so;

        varcpq__Sales_Order_Line_Item__c soli = new varcpq__Sales_Order_Line_Item__c(
            varcpq__Sales_Order__c = so.Id,
            varcpq__Line__c = 1,
            varcpq__Quantity__c = 2,
            varcpq__Unit_Cost__c = 50
            //varcpq__Total_Ext_Price__c = 100
        );
        insert soli;

        Sales_Order_Group__c sog = new Sales_Order_Group__c(
            Name = 'Group 1',
            Sales_Order__c = so.Id,
            Sequence__c = 1,
            Sub_Total__c = 100
        );
        insert sog;

        soli.Sales_Order_Group__c = sog.Id;
        update soli;

        Custom_Note__c note1 = new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note', Sales_Order__c=so.Id);
        Custom_Note__c note2 = new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note', Sales_Order__c=so.Id);
        insert new List<Custom_Note__c>{ note1, note2 };
    }

    @isTest
    static void testControllerConstructorAndLoadData() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', so.Id);

        Test.startTest();
        SalesOrderPDFController ctrl = new SalesOrderPDFController();
        Test.stopTest();

        System.assertNotEquals(null, ctrl.salesOrder);
        System.assertNotEquals(null, ctrl.account);
        System.assertNotEquals(null, ctrl.opportunity);
        System.assert(ctrl.lineItems.size() > 0);
        System.assert(ctrl.customerNotes.size() > 0);
    }

    @isTest
    static void testGenerateAndSavePDF() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        Test.startTest();
        ContentVersion version = SalesOrderPDFController.generateAndSavePDF(so.Id);
        Test.stopTest();
        System.assertNotEquals(null, version);
    }

    @isTest
    static void testGenerateAndEmailPDF() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        List<String> emails = new List<String>{'bill@example.com'};
        Test.startTest();
        SalesOrderPDFController.generateAndEmailPDF(so.Id, emails);
        Test.stopTest();
    }

    @isTest
    static void testGetDefaultEmailRecipients() {
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c LIMIT 1];
        Test.startTest();
        List<String> recipients = SalesOrderPDFController.getDefaultEmailRecipients(so.Id);
        Test.stopTest();
        System.assert(recipients.contains('bill@example.com'));
        System.assert(recipients.contains('ship@example.com'));
    }
     @isTest
    static void testSplitDescriptionAndGetLongerDescription() {
        
        String exampleString = 'This is a significantly longer description for testing purposes';
        Test.startTest();
        SalesOrderPDFController.breakLongWord(exampleString,10);
        SalesOrderPDFController.preserveFormatting(exampleString);
        Test.stopTest();
    }
}