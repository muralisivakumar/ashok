@isTest
public class TaxDetailsHandlerRLI_Test {
    
     @TestSetup
    static void createTaxData() {
        // Create a test Quote and Quote Line Item
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
        
        Account distAcc = new Account(Name = 'Test Account Distributor',RecordtypeId=USAccRecType,Type = 'Supplier');
        insert distAcc;
        
        contact con = new contact(LastName='Test',email='test@test.com',accountId=acc.Id);
        insert con;
        
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
            Pricebook2Id = integrationPricebook.Id,
            Tax_Rate_GST__c = 0,
            Tax_Rate_PST__c = 0,
            Tax_Rate_HST__c = 0,
            Tax_Rate_QST__c = 0
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
             (varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 1,varcpq__Unit_Cost__c = 100.0,
             varcpq__Product__c = prod.Id);
        insert SOLI1;
        
        varcpq__Invoice__c inv = new varcpq__invoice__c();
        Inv.varcpq__Sales_Order__c = salesOrderUSD.Id;
        Inv.varcpq__Client__c = salesOrderUSD.varcpq__Client__c;
		//Inv.varcpq__Shipping_and_Handling__c = 100;
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
    //rma.Shipping_Refund__c = 10.00;
    //rma.Restocking_Fee__c = 10.00;
    rma.Reason_Code__c = 'Test';
    rma.Related_Sales_Order__c = salesOrderUSD.Id;
      
    Insert rma;
        
        Return_Merchandise_Authorization_Line_It__c rl = new Return_Merchandise_Authorization_Line_It__c();
                    rl.Return_Merchandise_Authorization__c = rma.Id;
                    rl.Invoice_Line_Reference__c = invLine.Id;
                    rl.Quantity__c = 1;
                    rl.Product__c = invLine.Product__c;
                    rl.Unit_Price__c = invLine.varcpq__Unit_Price__c;
                    rl.Total_Ext_Price__c = 100.00;
                    rl.Remaining_Quantity__c = 0;
                    rl.Return_Type__c = 'Return';
                    rl.Reason__c = 'Test Reason';
                    rl.Notes__c = 'Test Note';
                    rl.Related_Sales_Order_Line_Item__c = invLine.varcpq__Sales_Order_Line_Item__c; 
                    rl.Distributor__c = distAcc.Id;
         
         Insert rl;
        
        
    }
    
    
    
    
    @IsTest
    static void testBulkProcessing() {
      Return_Merchandise_Authorization__c rma = [SELECT Id FROM Return_Merchandise_Authorization__c LIMIT 1];  
      List<Return_Merchandise_Authorization_Line_It__c> rli = new List<Return_Merchandise_Authorization_Line_It__c>(); 
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        for (Integer i = 0; i < 200; i++) {
          
            rli.add(
                new Return_Merchandise_Authorization_Line_It__c(
                    Return_Merchandise_Authorization__c = rma.Id,
                    Product__c = prod.Id,
                    Quantity__c = 1,
                    Unit_Price__c = 100.0,
                    RMA_Tax_Details__c = 'Tax Amount: 143.160 Rate : 5.000000% Tax Name : CANADA GST/TPS Juris Name CANADA'
                )
            );
        }
        
        Test.startTest();
        insert rli;
        Test.stopTest();
        
    }

}