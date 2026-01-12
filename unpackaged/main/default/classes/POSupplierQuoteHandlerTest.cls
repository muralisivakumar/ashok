@isTest
public class POSupplierQuoteHandlerTest {

    @testSetup
    public static void createTestData(){
        
     Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        Insert acc;
        
        contact con = new contact(LastName='Test',email='test@test.com',accountId=acc.Id);
        Insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Supplier_Quote_File__c = 'TestSO.pdf;',
            Pricebook2Id = integrationPricebook.Id
        );
        insert quote;
        
         Account distAcc = new Account(
            Name = 'Test Distributor',
            Type = 'Supplier'
        );
        Insert distAcc;
        
     varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
         	Quote__c = quote.Id,
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id,
            Billing_Email__c = 'testbill@test.com',
            Shipping_Email__c = 'testship@test.com'
        );
        insert salesOrderUSD;
        
         
        
         ContentVersion testContentVersion = new ContentVersion(
            Title = 'TestSO.pdf',
            PathOnClient = 'TestSO.pdf',
            VersionData = Blob.valueOf('This is the content of the test SO document.')
        );        
        insert testContentVersion;
        
        Test.startTest();
        Test.stopTest();
        ContentVersion cv = [SELECT Id,contentDocumentId FROM ContentVersion WHERE Id=:testContentVersion.Id];
        
        
        
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = salesOrderUSD.Id,
            ShareType = 'V', // 'V' stands for Viewer permission
            Visibility = 'AllUsers'
        );
        insert contentLink;
     
        
    }
    @isTest
    public Static void PoFileCreationTest(){
        Account objAcc = [SELECT ID FROM Account WHERE NAME ='Test Account'];
        Account distAcc =[SELECT ID,Name From Account WHERE Name = 'Test Distributor'];
        Contact objCon =[SELECT ID FROM CONTACT];
        varcpq__sales_order__c objSalesOrder = [SELECT ID FROM varcpq__Sales_Order__c];
        
        varcpq__purchase_order__c po = new varcpq__purchase_order__c(
            varcpq__Distributor_Terms__c = 'NET30',
            varcpq__PO_Status__c = 'Pending PO Generation',
            varcpq__Shipping_Method__c = 'Best Price',
            varcpq__Distributor_Contact__c = objCon.Id,
            varcpq__Distributor_Name__c = distAcc.Id,
            varcpq__PO_Date__c = System.Today(),
            varcpq__Ship_To_Account__c = objAcc.Id,
            varcpq__sales_order__c = objSalesOrder.Id
        );
        Insert po;
        
        /*List<varcpq__purchase_order__c>POList =[SELECT Id,varcpq__sales_order__c FROM varcpq__purchase_order__c];
        
        Test.StartTest();
        POSupplierQuoteHandler.fileHandler(POList);
        Test.StopTest();*/
    }
}