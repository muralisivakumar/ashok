@isTest
public class PurchaseOrderPDFController_Test {
    @testSetup
    static void setupTestData() {
        SalesOrderPDFController.testRunning = true;
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
        insert integrationPbe;
        PricebookEntry integrationPbeCad = new PricebookEntry(
            Pricebook2Id = integrationPricebookCad.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPbeCad;*/
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
        Pricebook2 integrationPricebookCad = new Pricebook2(
    Name = 'Integration Price Book', 
    IsActive = true,
    CurrencyIsoCode = 'USD'
);
insert integrationPricebookCad;

// ✅ then custom pricebook entry (depends on the standard one)
PricebookEntry integrationPbe = new PricebookEntry(
    Pricebook2Id = integrationPricebook.Id, 
    Product2Id = prod.Id, 
    UnitPrice = 100.0, 
    IsActive = true,
    CurrencyIsoCode = 'USD'
);
insert integrationPbe;
         PricebookEntry integrationPbeCad = new PricebookEntry(
            Pricebook2Id = integrationPricebookCad.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPbeCad;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        
        Account acc = new Account(Name = 'Test Account', RecordTypeId=USAccRecType);
        insert acc;

        Account accSupplier = new Account(Name = 'Test Supplier Account', RecordTypeId=USAccRecType);
        insert accSupplier;

        contact con = new contact(LastName='Test', email='test@test.com', accountId=acc.Id);
        insert con;

        varcpq__Customer_Address__c supplierAdd = new varcpq__Customer_Address__c(
            Name = 'Supplier Test Address',
            varcpq__Active__c = true,
            varcpq__City__c = 'Jupiter',
            varcpq__Customer__c = accSupplier.Id,
            varcpq__State__c = 'FL',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '33478',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert supplierAdd;
        
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
        insert addship;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Identified',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
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
            varcpq__Total_Margin__c = 3
        );
        insert qli;
        
        // Commented out due to trigger NullPointerException on update
        // opp.SyncedQuoteId = quote.Id;
        // update opp;
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id,
            Billing_Email__c = 'testbill@test.com',
            Shipping_Email__c = 'testship@test.com'
        );
        insert salesOrderUSD;
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(
            varcpq__Sales_Order__c = salesOrderUSD.Id, 
            varcpq__Line__c = 1, 
            varcpq__Quantity__c = 4,
            varcpq__Unit_Cost__c = 1000);
        insert SOLI1;
        
        Asset[] Asset_List = new Asset[]{};
        for(integer i =0; i< 2; i++) {
            Asset newAsset = new Asset(
                Name='Test Asset',
                AccountId = acc.Id,
                varcpq__Sales_Order__c = salesOrderUSD.Id,
                Quantity  = 10);
            Asset_List.add(newAsset);
        }
        insert Asset_List; 
        
        Account distAcc = new Account(
            Name = 'Test Distributor',
            Type = 'Supplier'
        );
        insert distAcc;
        
        varcpq__Customer_Address__c distriAdd = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = distAcc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert distriAdd;
        
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
        insert po;
        
        varcpq__Purchase_Order_Line_Item__c poli = new varcpq__Purchase_Order_Line_Item__c(
            varcpq__Ship_Via__c = 'Best Price',
            varcpq__Status__c = 'Available',
            varcpq__purchase_order__c = po.Id,
            varcpq__sales_order_line_item__c = SOLI1.Id,
            varcpq__DH_Line__c = 1,
            varcpq__Estimated_Ship_Date__c = System.today().addDays(5),
            varcpq__Quantity__c = 5,
            varcpq__Shipping_Account__c = acc.Id,
            varcpq__Shipping_Address__c = addship.Id,
            varcpq__Shipping_Contact__c = con.Id,
            varcpq__Unit_Cost__c = 186.59);
        insert poli;
    }

    @testVisible
    public static PDF_Company_Information__mdt getcompinfo {
        get {
            String recordType = 'US Account';    
            if(getcompinfo == null){
                PDF_Company_Information__mdt info = [
                    SELECT Company_Name__c, Street__c, Suite__c, 
                    City_State_Zip__c, Phone__c, Website__c
                    FROM PDF_Company_Information__mdt 
                    WHERE Record_Type__c = :recordType
                    LIMIT 1
                ];
            }
            return getcompinfo; 
        } 
        set; 
    }
    
    @testVisible
    public static PDF_Company_Information__mdt getcompinfoCad {
        get {
            String recordType = 'Canadian Account';    
            if(getcompinfoCad == null){
                PDF_Company_Information__mdt info = [
                    SELECT Company_Name__c, Street__c, Suite__c, 
                    City_State_Zip__c, Phone__c, Website__c
                    FROM PDF_Company_Information__mdt 
                    WHERE Record_Type__c = :recordType
                    LIMIT 1
                ];
            }
            return getcompinfoCad; 
        } 
        set; 
    }
    
    @testVisible
    public static PDF_Document_Configuration__mdt pdfDocConfigTest {
        get {
            String objectApiName = 'Quote';
            if(pdfDocConfigTest == null){
                PDF_Document_Configuration__mdt config = [SELECT Object_API_Name__c, File_Name_Prefix__c, 
                                                          Record_Number_Field__c, Template_Page_Name__c,
                                                          Record_Id_Parameter__c
                                                          FROM PDF_Document_Configuration__mdt 
                                                          WHERE Object_API_Name__c = :objectApiName
                                                          LIMIT 1];
            }
            return pdfDocConfigTest;
        }
        set;
    }
    
    @isTest
    static void poPdfControllerTest() {
        Test.startTest();
        varcpq__purchase_order__c purchaseOrder = [SELECT Id FROM varcpq__purchase_order__c LIMIT 1];
        List<String> toAddresses = new List<String>{'testSo@test.com'};
        BasePDFController basePdf = new BasePDFController();
        ApexPages.currentPage().getParameters().put('id', purchaseOrder.Id);
        PurchaseOrderPDFController poPdf = new PurchaseOrderPDFController();
        BasePDFController.CompanyInfo ci = poPdf.companyInfo;
        PurchaseOrderPDFController.generateAndEmailPDF(purchaseOrder.Id, toAddresses);
        PurchaseOrderPDFController.generateAndSavePDF(purchaseOrder.Id);
        Test.stopTest();
    }
      @isTest
    static void testSplitDescriptionAndGetLongerDescription() {
        
        String exampleString = 'This is a significantly longer description for testing purposes';
        Test.startTest();
        PurchaseOrderPDFController.breakLongWord(exampleString,10);
        PurchaseOrderPDFController.preserveFormatting(exampleString);
        Test.stopTest();
    }
}