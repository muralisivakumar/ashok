@isTest
public class InvoiceWizardControllerTest {

    @testSetup
    public static void createTestData(){
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'CLH-');
        insert CLIN;
        Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c=true);
        insert newAccount;
        
        Contact newContact = new Contact(LastName = 'lastName', AccountId = newAccount.Id);
        insert newContact;
        
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = newAccount.id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        insert opp;
        
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
		        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;
        
        /*Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Pricebook2Id = standardPricebook.Id
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 4,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
           
        );
        insert qli;
        
        opp.SyncedQuoteId = quote.Id;
        update opp;*/
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id, 
            varcpq__Billing_Contact__c = newContact.Id,
            varcpq__Shipping_and_Handling__c = 200
        );
        insert salesOrderUSD;
        
         varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c
             (varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000,
             varcpq__Product__c = prod.Id);
        insert SOLI1;
        
        varcpq__Invoice__c inv = new varcpq__invoice__c();
        Inv.varcpq__Sales_Order__c = salesOrderUSD.Id;
        Inv.varcpq__Client__c = salesOrderUSD.varcpq__Client__c;
		Inv.varcpq__Shipping_and_Handling__c = 100;
        Insert inv;
    }
    
    @isTest
    public static void testInvoiceCreation(){
        
        varcpq__Sales_Order__c SO = [SELECT ID,Name FROM varcpq__Sales_Order__c WHERE NAME =:'Test Sales Order USD'];
        Test.startTest();
        List<InvoiceWizardController.soliWrapper> soliwrapList = InvoiceWizardController.returnSOItems(SO.Id);
        InvoiceWizardController.createInvoice(SO.Id,soliwrapList);
        Test.stopTest();
    }
}