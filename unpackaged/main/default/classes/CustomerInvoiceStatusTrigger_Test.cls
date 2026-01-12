@isTest
public class CustomerInvoiceStatusTrigger_Test {

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

        //insert new Custom_Note__c(Note_Type__c='Customer Facing - Billing', Compose_Text__c='Billing Note', Sales_Order__c=so.Id);
        //insert new Custom_Note__c(Note_Type__c='Customer Facing - Shipping', Compose_Text__c='Shipping Note', Sales_Order__c=so.Id);

        varcpq__Invoice__c inv = new varcpq__Invoice__c(
            varcpq__Status__c = 'Issued',
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
            Invoice_Group__c = ig.Id,
            varcpq__Unit_Price__c = 50,
            varcpq__Quantity__c = 2
            //varcpq__Ext_Total__c = 100
        );
        insert ili;
    }
    @isTest
    static void triggerTestPaid(){
        varcpq__Invoice__c inv = [SELECT Id,Grand_Total__c, Total_Payments__c from varcpq__invoice__c];
        System.debug('invv '+inv);
        Customer_Invoice_Payment__c payment = new Customer_Invoice_Payment__c(
        	Customer_Invoice__c = inv.Id,
            Amount_Applied__c = 100
        );
        insert payment;
    }
    @isTest
    static void triggerTestRefund(){
        varcpq__Invoice__c inv = [SELECT Id,Grand_Total__c, Total_Payments__c,varcpq__status__c from varcpq__invoice__c];
        System.debug('invv '+inv);
        inv.varcpq__Status__c = 'Paid';
        inv.varcpq__Date_Paid__c = date.today();
        update inv;
        Customer_Invoice_Payment__c payment = new Customer_Invoice_Payment__c(
        	Customer_Invoice__c = inv.Id,
            Amount_Applied__c = 50
        );
        insert payment;
    }
}