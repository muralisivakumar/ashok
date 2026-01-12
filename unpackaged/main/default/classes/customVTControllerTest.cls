@isTest
public class customVTControllerTest {
    
 Public static String customerResponse1 =  '{"customerProfileId":"527262","customerPaymentProfileId":"87","validationDirectResponse":"1,1,1,This transaction has been approved.,AF94HU,Y,10586,none,Test transaction for ValidateCustomerPaymentProfile.,0.00,CC,auth_only,none,John,Doe,,123 Main St.,Bellevue,WA,98004,US,000-000-0000,,email@example.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,76247385B849148C0C6E0C205A6BEFFA,P,2,,,,,,,,,,,XXXX1111,Visa,,,,,,,0TN1VE648DFCJSHQ81GZH9F,,,,,,,,,,","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}';
   
    @testSetup
    public static void createTestData(){
      bt_stripe__Stripe_Settings__c settings = bt_stripe__Stripe_Settings__c.getOrgDefaults();
      settings.bt_stripe__Disable_All_Triggers__c = true;
      upsert settings;
    
        //Product custom Settings
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
    
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        //Std PriceBookId
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        //CustomPriceBook
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'USD', IsActive = true);
        insert customPricebook;
        
        // Distrubuter Account
        account distiAcc = new Account(Name = 'Distributor',Type = 'Supplier',varcpq__Available_for_PO__c= true);
        insert distiAcc;
        
         // Create Product2
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product');
        product.varcpq__Distributor_Account__c = distiAcc.Id;
        insert product;
        
        // standard PriceBookEntry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPricebookEntry;
        
        //Custom PriceBookEntry
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert customPricebookEntry;
        
        //Payment Gateway
        bt_stripe__Payment_Gateway__c pg = new bt_stripe__Payment_Gateway__c();
        pg.Name = 'Test PaymentGateway';
        pg.bt_stripe__Provider__c = 'Authorize.net';
        pg.bt_stripe__Default__c = true;
        pg.bt_stripe__Test_Mode__c = true;
        
        insert pg;  
        System.debug('pg in test class-->'+pg);
        
        // Accounts
       Account newAccount = new Account(Name='Test Account');
       insert newAccount;
         System.debug('Account of test Class--->'+newAccount);
        
       Account newAccount1 = new Account(Name='Test Account1');
       insert newAccount1;
       System.debug('Account of test Class--->'+newAccount1);
        
        //Contact
        Contact newContact = new Contact(LastName = 'Aniket', AccountId = newAccount.Id,Email = 'pooja.pawar@aressindia.net');
        insert newContact;
        System.debug('Contact of test Class--->'+newContact);
        
        Contact newContact1 = new Contact(LastName = 'Kunal', AccountId = newAccount.Id,Email = 'test@test.com');
        insert newContact1;
        System.debug('Contact of test Class--->'+newContact1);
        
        //Customer Addresses
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
          System.debug('CustAdd of test Class--->'+add);
        
        //Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        insert opp;
        System.debug('Opp of test Class--->'+opp);
        
        
        //Quotes
        Quote quote = new Quote(
           
            OpportunityId = opp.Id,            
            Name = 'First Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Bill_to_email__c = 'ashwini.pande@aressindia.net',
            BillingName = 'TestConQuote',
            Quote_Net_Terms__c = 'NET30'
           
        );
        insert quote;
         System.debug('Quote of test Class--->'+quote);
        
        
        Quote qt = new Quote(          
            OpportunityId = opp.Id, 
            Name = 'Second Quote', 
            CurrencyIsoCode = 'USD',           
            Bill_to_email__c = 'ashwini.pande@aressindia.net',
            BillingName = 'TestConQuote',
            Quote_Net_Terms__c = 'NET30',
             Status = 'Approved'
         );
        insert qt;
         System.debug('Quote of test Class--->'+qt);
        
        //QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
           );

        insert qli;
        
        //Sales Orders
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'First Sales Order', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id,
            SO_Net_Terms__c = 'NET30'
            
        );
        insert salesOrderUSD;
        System.debug('SalesOrder of test Class--->'+salesOrderUSD);
        
        
            varcpq__Sales_Order__c salesOrderUSD1 = new varcpq__Sales_Order__c(
            Name = 'Second Sales Order', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id,
            SO_Net_Terms__c = 'NET40'
            
        );
        insert salesOrderUSD1;
        System.debug('SalesOrder of test Class--->'+salesOrderUSD);
        
        varcpq__Sales_Order__c newSO = new varcpq__Sales_Order__c(
            Name = 'Third Sales Order', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id,
            SO_Net_Terms__c = 'NET60'
            
        );
        insert newSO;
        System.debug('SalesOrder of test Class--->'+newSO);
        
        //Sales Order Line Items
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c
             (varcpq__Sales_Order__c = salesOrderUSD1.Id, 
              varcpq__Line__c = 1,
              varcpq__Quantity__c = 4,
              varcpq__Unit_Cost__c = 10,
              varcpq__Unit_Price__c = 100,
             varcpq__Product__c = product.Id,
              varcpq__Distributor__c = product.varcpq__Distributor__c);
        insert SOLI1;
        
        //Invoices
        
        varcpq__Invoice__c Inv = new varcpq__Invoice__c();
        Inv.varcpq__Sales_Order__c = salesOrderUSD.Id;
        Inv.varcpq__Client__c = salesOrderUSD.varcpq__Client__c;
        Inv.varcpq__Terms__c = salesOrderUSD.SO_Net_Terms__c;
        Inv.CurrencyIsoCode = salesOrderUSD.CurrencyIsoCode;
            
        INSERT Inv;  
        
        
        varcpq__Invoice__c Inv1 = new varcpq__Invoice__c();
        Inv1.varcpq__Sales_Order__c = salesOrderUSD1.Id;
        Inv1.varcpq__Client__c = salesOrderUSD1.varcpq__Client__c;
        Inv1.varcpq__Terms__c = salesOrderUSD1.SO_Net_Terms__c;
        Inv1.CurrencyIsoCode = salesOrderUSD1.CurrencyIsoCode;
            
        INSERT Inv1;  
        System.debug('Inv1------------------------------->'+Inv1);
        
        //InvoiceLine Item
         varcpq__Invoice_Line_Item__c invoLi = new varcpq__Invoice_Line_Item__c();
                invoLi.varcpq__Sales_Order_Line_Item__c = SOLI1.Id;
                invoLi.varcpq__Invoice__c = Inv1.Id;
                invoLi.varcpq__Unit_Price__c= 100;
                invoLi.varcpq__Quantity__c= 4;
                invoLi.varcpq__Total_Cost__c = 4 * 50; 
                invoLi.varcpq__DH_Line__c = SOLI1.varcpq__Line__c;
                invoLi.CurrencyIsoCode = 'USD';
                invoLi.Product__c = SOLI1.varcpq__Product__c;
                invoLi.Distributor__c = SOLI1.varcpq__Distributor__c;
        		invoLi.varcpq__Status__c = 'Available';
       	
        Insert invoLi;
        System.debug('involii '+invoLi.varcpq__Unit_Price__c + ' '+invoLi.varcpq__Quantity__c + ' '+invoLi.Id);
        System.debug('involi------------------------------->'+invoLi.varcpq__Ext_Total__c + ' Status '+invoLi.varcpq__Status__c); 
        System.debug('Inv1---------------------------------->'+Inv1.varcpq__LIT__c);
        
        
        //Payment Method
        RecordType rt =[SELECT Id, Name, DeveloperName FROM RecordType WHERE Name = 'Card' AND SObjectType = 'bt_stripe__Payment_Method__c' LIMIT 1];
        bt_stripe__Payment_Method__c pm = new bt_stripe__Payment_Method__c();
        pm.RecordTypeId = rt.Id;
        pm.bt_stripe__Account__c = newAccount.Id;
        pm.bt_stripe__Card_Holder_Name__c = 'Test Card';
        pm.bt_stripe__Card_Expiration_Month__c ='11';
        pm.bt_stripe__Card_Expiration_Year__c ='2030';
        pm.bt_stripe__Card_Number__c ='4111111111111111';
        pm.bt_stripe__Billing_Postal_Code__c = '10001';
        pm.bt_stripe__CVV__c ='111';
        pm.bt_stripe__Payment_Gateway__c =pg.Id;
        pm.bt_stripe__Payment_Method_Status__c ='Valid';
        pm.bt_stripe__Card_Last_4_Digit__c = '1111'; 
        insert pm;
        System.debug('pm of test Class--->'+pm);
        System.debug('pmId of test Class--->'+pm.Id);     
        
        //Transactions
        
        Id recTypeId = [SELECT Id, Name, SobjectType, IsActive FROM RecordType where SobjectType = 'bt_stripe__Transaction__c' AND Name = 'Charge' LIMIT 1].Id;
        
        
        //Transaction1
        bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();
        tran.CurrencyIsoCode = 'USD';
        tran.RecordTypeId = recTypeId;
        tran.bt_stripe__Amount__c = 300.00;
        tran.bt_stripe__Related_Account__c = newAccount.Id; 
        //tran.Quote__c = quote.Id;
        tran.Sales_Order__c = salesOrderUSD1.Id;
        tran.Invoice__c = Inv1.Id;
        tran.bt_stripe__Payment_Method__c = pm.Id;
        tran.bt_stripe__Payment_Status__c = 'Authorized';
        
        
        Insert tran;
        
        //Transaction2
       
        bt_stripe__Transaction__c tra = new bt_stripe__Transaction__c();
        tra.CurrencyIsoCode = 'USD';
        tra.RecordTypeId = recTypeId;
        tra.bt_stripe__Amount__c = 100.00;
        tra.bt_stripe__Related_Account__c = newAccount.Id; 
        //tra.Quote__c = quote.Id;
        tra.Sales_Order__c = salesOrderUSD1.Id;
        tra.Invoice__c = Inv1.Id;
        tra.bt_stripe__Payment_Status__c = 'Captured';
        
        Insert tra;
        
        //Transaction3
        
         /* bt_stripe__Transaction__c tra1 = new bt_stripe__Transaction__c();
        tra1.CurrencyIsoCode = 'USD';
        tra1.RecordTypeId = recTypeId;
        tra1.bt_stripe__Amount__c = 100.00;
        tra1.bt_stripe__Related_Account__c = newAccount.Id; 
        //tra1.Quote__c = quote.Id;
        tra1.Sales_Order__c = salesOrderUSD1.Id;
        tra1.Invoice__c = Inv1.Id;
        tra1.bt_stripe__Payment_Method__c = pm.Id;
        tra1.bt_stripe__Payment_Status__c = 'Authorized';
        
        Insert tra1;
        
        //Transaction4
        
       bt_stripe__Transaction__c tranSact = new bt_stripe__Transaction__c();
        tranSact.CurrencyIsoCode = 'USD';
        tranSact.RecordTypeId = recTypeId;
        tranSact.bt_stripe__Amount__c = 100.00;
        tranSact.bt_stripe__Related_Account__c = newAccount.Id; 
        //tranSact.Quote__c = quote.Id;
        tranSact.Sales_Order__c = salesOrderUSD1.Id;
        tranSact.Invoice__c = Inv1.Id;
        tranSact.bt_stripe__Payment_Method__c = pm.Id;
        tranSact.bt_stripe__Payment_Status__c = 'Captured';
        
        Insert tranSact;
        
        //Transaction5
         bt_stripe__Transaction__c trx = new bt_stripe__Transaction__c();
        trx.CurrencyIsoCode = 'USD';
        trx.RecordTypeId = recTypeId;
        trx.bt_stripe__Amount__c = 10.00;
        trx.bt_stripe__Related_Account__c = newAccount.Id; 
        trx.Quote__c = qt.Id;
        trx.Sales_Order__c = salesOrderUSD.Id;
        trx.Invoice__c = Inv.Id;
        trx.bt_stripe__Payment_Method__c = pm.Id;
        trx.bt_stripe__Payment_Status__c = 'Authorized';
        trx.Sales_Order__c = salesOrderUSD.Id;
        Insert trx;
        
        //Transaction6
        
        bt_stripe__Transaction__c trxn = new bt_stripe__Transaction__c();
        trxn.CurrencyIsoCode = 'USD';
        trxn.RecordTypeId = recTypeId;
        trxn.bt_stripe__Amount__c = 10.00;
        trxn.bt_stripe__Related_Account__c = newAccount.Id; 
        trxn.Quote__c = qt.Id;
        trxn.Sales_Order__c = salesOrderUSD.Id;
        trxn.Invoice__c = Inv.Id;
        trxn.bt_stripe__Payment_Method__c = pm.Id;
        trxn.bt_stripe__Payment_Status__c = 'Authorized';
        trxn.Sales_Order__c = salesOrderUSD.Id;
        Insert trxn;
        
        //Transaction7
        
        bt_stripe__Transaction__c tranSactn = new bt_stripe__Transaction__c();
        tranSactn.CurrencyIsoCode = 'USD';
        tranSactn.RecordTypeId = recTypeId;
        tranSactn.bt_stripe__Amount__c = 100.00;
        tranSactn.bt_stripe__Related_Account__c = newAccount.Id; 
        tranSactn.Quote__c = quote.Id;
        tranSactn.Sales_Order__c = salesOrderUSD.Id;
        tranSactn.Invoice__c = Inv.Id;
        tranSactn.bt_stripe__Payment_Method__c = pm.Id;
        tranSactn.bt_stripe__Payment_Status__c = 'Captured';
        
        Insert tranSactn; */
        
        
         EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'AuthLink_Email_Template' LIMIT 1];
        
        //StripeMock mock = new StripeMock();
        //mock.setBody(customerResponse1);
        //Test.setMock(HttpCalloutMock.class, mock);
       
        /*Test.startTest();   
        
        customVTController.getObjectApiName(quote.Id);
        customVTController.getObjectApiName(Inv.Id);
        customVTController.preventPMDuplication(newAccount.Id,'test Card','4111111111111111','11','2030');
        customVTController.paymentMethods(quote.Id);
        customVTController.paymentMethodsInv(Inv.Id);
        customVTController.quoteDetails(quote.Id);
        customVTController.invoiceDetails(Inv.Id);
        
        customVTController.createPaymentMethod(newAccount.Id,'TestCard','4111111111111111','11','2011','111','testuser@clutchsolutions.com','10001',true);
        customVTController.createPaymentMethod(quote.Id,'TestCard','4111111111111111','11','2011','111','testuser@clutchsolutions.com','10001',true);
        customVTController.createTransactionToAuthorize(pm.Id,100,quote.Id,newAccount.Id,salesOrderUSD.Id);
        customVTController.sendAuthLinkToCustomer(100,'USD','testuser@clutchsolutions.com','BillName',newAccount.Id,quote.Id,salesOrderUSD.Id,newContact.Id);
        customVTController.captureTransaction(pm.Id,400,newAccount.Id,Inv1.Id);
        customVTController.captureTransaction(pm.Id,500,newAccount.Id,Inv1.Id);
        inv1.Captured_Charges__c = 400;
        update inv1;
        customVTController.captureTransaction(pm.Id,400,newAccount.Id,Inv1.Id);
        customVTController.createTransactionToAuthorize(pm.Id,10,qt.Id,newAccount.Id,newSO.Id);
       
         
        Test.stopTest();*/
         
        
        
    }
    
  @isTest
  Public static void  testPaymentFuctions(){ 
      Test.startTest();
    List<bt_stripe__Payment_Gateway__c> pgList = [SELECT Id,bt_stripe__Default__c FROM bt_stripe__Payment_Gateway__c
                                                      WHERE bt_stripe__Default__c = true LIMIT 1];
        
 Account newAccount = [SELECT ID,Name from Account WHERE Name='Test Account'];
 /* Contact newContact = [SELECT ID,Name,LastName,Email FROM Contact WHERE LastName = 'lastName'];
 Contact newContact1 =[SELECT ID,Name,LastName FROM Contact  WHERE LastName = 'lastName'];*/
 List<Contact>conList = [SELECT ID,Name,LastName FROM Contact ORDER BY LastName ASC];
 /*Quote quote = [Select Id,Name From Quote  WHERE Name = 'Test Quote'];
 Quote qt = [Select Id,Name,GrandTotal From Quote  WHERE Name = 'Testing Quote'];*/
 List<Quote>quoteList = [Select Id,Name,GrandTotal From Quote ORDER BY Name ASC ];
 /*varcpq__Sales_Order__c salesOrderUSD = [SELECT ID,SO_Net_Terms__c FROM varcpq__Sales_Order__c WHERE  SO_Net_Terms__c = 'NET30' LIMIT 1];
 varcpq__Sales_Order__c salesOrderUSD1 = [SELECT ID,SO_Net_Terms__c,Quote__c,Quote__r.Name FROM varcpq__Sales_Order__c WHERE  SO_Net_Terms__c = 'NET40' LIMIT 1];
 varcpq__Sales_Order__c newSO = [SELECT ID,SO_Net_Terms__c FROM varcpq__Sales_Order__c WHERE  SO_Net_Terms__c = 'NET60' LIMIT 1];*/
 List<varcpq__Sales_Order__c>soList = [SELECT ID,Name,SO_Net_Terms__c FROM varcpq__Sales_Order__c ORDER BY NAME ASC ];     
  System.debug('soList in testpaymentfuctions-------------------------------->'+soList[0].Name +''+soList[1].Name);
 
 /*varcpq__Invoice__c Inv  = [SELECT ID,varcpq__Terms__c FROM varcpq__Invoice__c WHERE varcpq__Terms__c = 'NET30'];
 varcpq__Invoice__c Inv1  = [SELECT ID,varcpq__Terms__c,Grand_Total__c,Captured_Charges__c FROM varcpq__Invoice__c WHERE varcpq__Terms__c = 'NET40'];
 System.debug('Inv1 GrandTotal in customVTControllerTest-------------------------------->'+Inv1.Grand_Total__c);*/
 List<varcpq__Invoice__c>InvList = [SELECT ID,varcpq__Terms__c,Grand_Total__c,Captured_Charges__c,varcpq__Sales_Order__c,varcpq__Sales_Order__r.Name FROM varcpq__Invoice__c ORDER BY varcpq__Sales_Order__r.Name ASC];
 bt_stripe__Payment_Method__c pm = [SELECT ID,bt_stripe__Card_Holder_Name__c FROM bt_stripe__Payment_Method__c WHERE bt_stripe__Card_Holder_Name__c = 'Test Card'];     
        
      
      
        customVTController.getObjectApiName(quoteList[0].Id);
        customVTController.getObjectApiName(InvList[0].Id);
        customVTController.preventPMDuplication(newAccount.Id,'test Card','4111111111111111','11','2030');
        customVTController.preventPMDuplication(newAccount.Id,'test Card','4111111111111111','11','2031');
        customVTController.paymentMethods(quoteList[0].Id);
        customVTController.paymentMethodsInv(InvList[0].Id);
        customVTController.paymentMethodsInv(InvList[1].Id);
        customVTController.quoteDetails(quoteList[0].Id);
        customVTController.invoiceDetails(InvList[0].Id);
        customVTController.returnMail(conList[0].Id);
        customVTController.returnMail(conList[1].Id);
        
        customVTController.createPaymentMethod(newAccount.Id,'TestCard','4111111111111111','11','2011','111','testuser@clutchsolutions.com','10001',true);
        customVTController.createPaymentMethod(quoteList[0].Id,'TestCard','4111111111111111','11','2011','111','testuser@clutchsolutions.com','10001',true);
       customVTController.createTransactionToAuthorize(pm.Id,100,quoteList[0].Id,newAccount.Id,soList[0].Id);
       customVTController.createTransactionToAuthorize(pm.Id,10,quoteList[1].Id,newAccount.Id,soList[2].Id);
        customVTController.sendAuthLinkToCustomer(100,'USD','testuser@clutchsolutions.com','BillName',newAccount.Id,quoteList[0].Id,soList[0].Id,conList[0].Id);
        customVTController.captureTransaction(pm.Id,400,newAccount.Id,InvList[0].Id);
        customVTController.captureTransaction(pm.Id,500,newAccount.Id,InvList[1].Id);
        customVTController.captureTransaction(pm.Id,200,newAccount.Id,InvList[1].Id);
        //customVTController.captureTransaction(pm.Id,100,newAccount.Id,Inv1.Id);
       
       
      
        
      
      
      
      Test.stopTest();
      
      
      
        
    }
   
}