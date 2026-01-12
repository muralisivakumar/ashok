@isTest
public class InvoiceService_Test {
	@testSetup
    static void setupTestData() {
        
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
        
        Pricebook2 integrationPricebookCad = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert integrationPricebookCad;
        
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
        PricebookEntry integrationPbeCad = new PricebookEntry(
            Pricebook2Id = integrationPricebookCad.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbeCad;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        List<account> accounts = new List<account>();
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
        
        varcpq__Customer_Address__c addship = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.Id,
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
            AccountId = acc.Id
        );
        insert opp;
        
        
        
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
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000);
        insert SOLI1;
        
        
        
        Asset[] Asset_List = new Asset[]{};
            for(integer i =0; i< 2; i++) {
                Asset newAsset = new Asset(Name='Test Asset',AccountId = acc.Id,varcpq__Sales_Order__c = salesOrderUSD.Id,Quantity  = 10);
                Asset_List.add(newAsset);
            }
        insert Asset_List; 
        account distacc = new account(name='distributor',type='Supplier');
        insert distacc;
        varcpq__purchase_order__c po = new varcpq__purchase_order__c(
            varcpq__Distributor_Terms__c = 'NET30',
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Shipping_Method__c = 'Best Price',
            varcpq__Distributor_Contact__c = con.Id,
            varcpq__Distributor_Name__c = distAcc.Id,
            varcpq__PO_Date__c = System.Today(),
            varcpq__Ship_To_Account__c = acc.Id,
            varcpq__sales_order__c = salesOrderUSD.Id
        );
        Insert po;
        
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(
            varcpq__Ship_Via__c = 'Best Price',
            varcpq__Status__c = 'Available',
            varcpq__purchase_order__c = po.Id,
            varcpq__sales_order_line_item__c = SOLI1.Id,
            varcpq__DH_Line__c = 1,
            varcpq__Estimated_Ship_Date__c = System.today().adddays(5),
            varcpq__Quantity__c = 5,
            varcpq__Shipping_Account__c = acc.Id,
            varcpq__Shipping_Address__c = addship.Id,
            varcpq__Shipping_Contact__c = con.Id,
            varcpq__Unit_Cost__c = 186.59);
        insert poli;
		
		varcpq__accounts_payable_invoice__c api = new varcpq__accounts_payable_invoice__c();
        api.varcpq__Purchase_Order__c = po.Id;
        api.Sales_Order__c = salesOrderUSD.Id;
        insert api;
        varcpq__account_payable_invoice_line_item__c apili = new varcpq__account_payable_invoice_line_item__c();
        apili.varcpq__Purchase_Order_Line_Item__c = poli.Id;
        apili.varcpq__Quantity_Invoiced__c = 5;
        apili.varcpq__Unit_Cost__c = 186.59;
        apili.varcpq__Accounts_Payable_Invoice__c = api.Id;
        apili.varcpq__Unit_Price__c = 186.59;
        insert apili;
		        
         varcpq__Invoice__c invoice = new varcpq__Invoice__c(
        	varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Sales_Order__c = salesOrderUSD.Id
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
    static void testmethod1(){
        
    }
}