@istest
public class invoiceContactTriggerTest {
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
        Id CADAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId();
        
        List<account> accounts = new List<account>();
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        Account accCad = new Account(Name = 'Test Cad Account', RecordTypeId = CADAccRecType);
        accounts.add(acc);
        accounts.add(accCad);
        Insert accounts;
        
        Id cadAccId;
        Id usAccId;
        for(account account:accounts){
            if(account.RecordTypeId == USAccRecType){
                usAccId = account.Id;
            }else{
                cadAccId = account.Id;
            }
            
        }
        
        List<Contact> contacts = new List<Contact>();
        contact con = new contact(LastName='Test',email='test@test.com',accountId=usAccId);
        contact conCad = new contact(LastName = 'Test canada', email = 'testcad@test.com',accountId= cadAccId);
        contacts.add(con);
        contacts.add(conCad);
        Insert contacts;
        
        
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = usAccId,
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
            varcpq__Customer__c = usAccId,
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
            AccountId = usAccId
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
        
        
        
    }
    
    @isTest
    static void testInvoiceTrigger(){
       
        Account acc = [SELECT Id from Account WHERE name='Test Account'];
        Contact con = [SELECT Id From Contact where accountId=:acc.Id];
        varcpq__Sales_Order__c so = [SELECT Id FROM varcpq__Sales_Order__c];
        varcpq__Sales_Order_Line_Item__c soli = [SELECT Id FROM varcpq__Sales_Order_Line_Item__c];
        Asset asset = [SELECT Id FROM Asset limiT 1];
        varcpq__Invoice__c invoice = new varcpq__Invoice__c(
        	varcpq__Client__c = acc.Id,
            varcpq__Billing_Contact__c = con.Id,
            varcpq__Sales_Order__c = so.Id
        );
        Insert invoice;
        
        varcpq__Invoice_Line_Item__c invItem = new varcpq__Invoice_Line_item__c(
        	varcpq__Invoice__c = invoice.Id,
            varcpq__Sales_Order_Line_Item__c = soli.Id,
            varcpq__Asset__c = asseT.Id
        );
        insert invItem;
        
        
    }
}