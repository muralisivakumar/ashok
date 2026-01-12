@isTest
public class PurchaseOrderStatusTriggerTest {
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
        Opportunity oppCad = new Opportunity(
            Name = 'Test Opportunity Cad',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = cadAccId
        );
        insert oppCad;
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
            varcpq__Total_Margin__c = 3
        );
        insert qli;
        
        opp.SyncedQuoteId = quote.Id;
        update opp;
        
        Quote quoteCad = new Quote(
            OpportunityId = oppCad.Id, 
            Name = 'Test Quote Cad', 
            Status = 'Presented',
            Pricebook2Id = integrationPricebookCad.Id
        );
        insert quoteCad;
        QuoteLineItem qliCad = new QuoteLineItem(
            QuoteId = quoteCad.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3,
            AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 10.00 Rate : 10.000000% Tax Name : CA GST Juris Name CANADA ,'
        );
        insert qliCad;
        
        oppCad.SyncedQuoteId = quoteCad.Id;
        update oppCad;
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            varcpq__Stage__c = 'POs Created',
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id,
            Billing_Email__c = 'testbill@test.com',
            Shipping_Email__c = 'testship@test.com'
        );
        insert salesOrderUSD;
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_price__c =500 ,varcpq__Unit_Cost__c = 100);
        insert SOLI1;
        
        
        
        Asset[] Asset_List = new Asset[]{};
            for(integer i =0; i< 2; i++) {
                Asset newAsset = new Asset(Name='Test Asset',AccountId = acc.Id,varcpq__Sales_Order__c = salesOrderUSD.Id,Quantity  = 10);
                Asset_List.add(newAsset);
            }
        insert Asset_List; 
        Account distAcc = new Account(
            Name = 'Test Distributor',
            Type = 'Supplier'
        );
        Insert distAcc;
        
        varcpq__purchase_order__c po = new varcpq__purchase_order__c(
            varcpq__Distributor_Terms__c = 'NET30',
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Shipping_Method__c = 'Best Way',
            varcpq__Distributor_Contact__c = contacts[0].Id,
            varcpq__Distributor_Name__c = distAcc.Id,
            varcpq__PO_Date__c = System.Today(),
            varcpq__Ship_To_Account__c = usAccId,
            varcpq__sales_order__c = salesOrderUSD.Id
        );
        Insert po;
        
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(
            varcpq__Ship_Via__c = 'Best Way',
            varcpq__Status__c = 'Available',
            varcpq__purchase_order__c = po.Id,
            varcpq__sales_order_line_item__c = SOLI1.Id,
            varcpq__DH_Line__c = 1,
            varcpq__Estimated_Ship_Date__c = System.today().adddays(5),
            varcpq__Quantity__c = 5,
            varcpq__Shipping_Account__c = usAccId,
            varcpq__Shipping_Address__c = addship.Id,
            varcpq__Shipping_Contact__c = contacts[0].Id,
            varcpq__Unit_Cost__c = 200);
        insert poli;
    }
    
    @isTest
    static void poStatusChange(){
        Test.startTest();
        
        
        varcpq__purchase_order__c po = [SELECT id, varcpq__PO_Status__c FROM varcpq__purchase_order__c LIMIT 1];
 
        po.varcpq__PO_Status__c = 'PO Confirmed';

        update po;
        
      
        Test.stopTest();
        
    }
    
    
    
}