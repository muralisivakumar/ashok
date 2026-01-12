@isTest
public class InvoiceTaxCalculatorTest {
	 @testSetup
    static void setupData(){
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
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        insert acc;
        
        contact con = new contact(FirstName = 'Test',LastName='Contact',email = 'test@test.com',accountid = acc.Id);
        insert con;
        varcpq__Customer_Address__c ca = new varcpq__Customer_Address__c(varcpq__Active__c= True,
                                                                         varcpq__Street__c= '121 Spear Street',
                                                                         varcpq__City__c = 'San Francisco',
                                                                         varcpq__State__c = 'CA',
                                                                         Country__c = 'US',
                                                                         varcpq__Zipcode__c = '94105',
                                                                         varcpq__Customer__c = acc.Id);
        insert ca;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            //avaQuotely__Tax_Rate__c = 0.07,
            Status = 'Approved',
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
        
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
            Name = 'Test K opp Sales Order',
            CurrencyIsoCode = 'USD',
            varcpq__Allowed_Partial_Invoices__c = true,
            varcpq__Amount__c = 38175.34,
            varcpq__Billing_Address__c = ca.Id,
            varcpq__Billing_Contact__c = con.id,
            varcpq__Client__c = acc.Id,
            varcpq__Customer_PO__c = 'IM-123',
            varcpq__Open_Closed__c = 'Open',
            varcpq__Opportunity__c = opp.Id,
            varcpq__Shipping_Address__c = ca.id,
            varcpq__Shipping_Contact__c = con.Id,
            varcpq__Stage__c = 'POs Created',
            Taxes__c = 3226.78);
        insert salesOrder;
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = salesOrder.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000);
        insert SOLI1;
        
        
        
        Asset[] Asset_List = new Asset[]{};
            for(integer i =0; i< 2; i++) {
                Asset newAsset = new Asset(Name='Test Asset',AccountId = acc.Id,varcpq__Sales_Order__c = salesOrder.Id,Quantity  = 10);
                Asset_List.add(newAsset);
            }
        insert Asset_List; 
        varcpq__Invoice__c invoice = new varcpq__Invoice__c(
        	varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Sales_Order__c = salesOrder.Id
        );
        Insert invoice;
        
        varcpq__Invoice_Line_Item__c invItem = new varcpq__Invoice_Line_item__c(
        	varcpq__Invoice__c = invoice.Id,
            varcpq__Sales_Order_Line_Item__c = soli1.Id,
            varcpq__Asset__c = Asset_List[0].Id
        );
        insert invItem;
    }
    
    @isTest
    static void InvoiceTaxCalculatorTest(){
        varcpq__Invoice__c invoice = [Select id from varcpq__Invoice__c];
        PageReference pageRef = Page.InvoiceTaxCalculatorVFPage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(invoice.Id));
        
        ApexPages.StandardController inv = new  ApexPages.StandardController(invoice);
        InvoiceTaxCalculator invoiceTaxCalc = new InvoiceTaxCalculator();
        
        InvoiceTaxCalculator invoiceTaxCalcParam = new InvoiceTaxCalculator(inv);
        invoiceTaxCalc.calculateTaxButton();
        invoiceTaxCalcParam.calculateTaxButton();
    }
}