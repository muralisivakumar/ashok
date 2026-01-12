/***************************************************************************************************************************************************************************************
* @description       : Controller Class for customVirtualterminal LWC to create Payment Method on Account,Authorize Amount and send AuthLink to customer on Quote and Capture Amount on Invoice.
* @author            : Aress Software - AS
* @Created date      : 06/5/2025
* @related class     : -
* @test Class        : customVTControllerTest
* @last modified on  : - 03/05/2025
* @last modified by  : - 
****************************************************************************************************************************************************************************************/



public class customVTController {
    
    @AuraEnabled
    public static string createPaymentMethod(
        Id currentRecordId,
        String nameOnCard,
        String cardNumber,
        String expMonth,
        String expYear,
        String cvc,
        String billingEmail,
        String postalCode,
        Boolean isDefault
    ) 
    {    
        
        system.debug('currentRecordId--19-->'+currentRecordId);
        String ErrorMessage ='';
        Map<string,string> objNameAndAccId = customVTController.getObjectApiName(currentRecordId);
        String nameOfObject = objNameAndAccId.get('objApiName');
        system.debug('nameOfObject---->'+nameOfObject);        
        // You need to select a Payment Gateway - it's important to set the paymentGatewayId property on all object instances 
        List<bt_stripe__Payment_Gateway__c> pgList = [SELECT Id FROM bt_stripe__Payment_Gateway__c
                                                      WHERE bt_stripe__Default__c = true LIMIT 1];
        System.debug('pgList--->'+pgList);
        List<varcpq__Customer_Address__c> custAdd = new  List<varcpq__Customer_Address__c>();
        List<Quote> custAddQuote = new List<Quote>();
        List<bt_stripe__Stripe_Customer__c> BtCustomerList = new List<bt_stripe__Stripe_Customer__c>();
        Id accId;  // This is pass customer.accountId while creating customer in Authorize.net
        
        if(nameOfObject == 'Account'){
            // This custAdd related To AccountId So that we can Pass it to Payment Method while creation
            custAdd = [SELECT Id,varcpq__Customer__c,Country__c,varcpq__State__c,Default_Billing_Address__c,varcpq__Street__c,varcpq__City__c,varcpq__Zipcode__c
                       FROM varcpq__Customer_Address__c WHERE varcpq__Customer__c =: currentRecordId AND Default_Billing_Address__c = true Limit 1];
            BtCustomerList  = [SELECT Id,bt_stripe__Account__c FROM bt_stripe__Stripe_Customer__c WHERE 
                               bt_stripe__Account__c =:currentRecordId LIMIT 1];
            accId = currentRecordId;
        }
        if(nameOfObject == 'Quote'){
            List<Quote>quote = [SELECT ID,OpportunityId From Quote WHERE ID =:currentRecordId];
            Id oppId = quote[0].OpportunityId;
            List<Opportunity> oppRec= [SELECT Id ,AccountId FROM Opportunity Where ID =:oppId];
            Id AccountId = oppRec[0].AccountId;
            //get address details on Quote
            custAddQuote = [SELECT Id,BillingCountry,BillingState,BillingStreet,BillingCity,BillingPostalCode FROM Quote Where Id =:currentRecordId LIMIT 1];            
            BtCustomerList  = [SELECT Id,bt_stripe__Account__c FROM bt_stripe__Stripe_Customer__c WHERE 
                               bt_stripe__Account__c =:AccountId LIMIT 1];
            accId = AccountId;  
        }
        
        /*This is if bt_stripe__Stripe_Customer__c related to AccountId already exists then pass that Id So that Payment Method 
will have that as payment gateway customer but if bt_stripe__Stripe_Customer__c related to that AccountId does not exists
then pass   customerId = null; so in Authorize.net and in salesforce bt_stripe__Stripe_Customer__c record related to that
customer can be created.*/
        Id customerId;
        if(!BtCustomerList.isEmpty()){
            customerId = BtCustomerList[0].Id;
        }
        else{
            customerId = null;
        }        
        bt_stripe.P360_API_v1.Customer customer;
        bt_stripe.P360_API_v1.PM pm;
        try {
            customer = bt_stripe.P360_API_v1.customerFactory(customerId);           
            if(customer.record == null || customer.record.Id == null) {
                customer.paymentGatewayId = pgList[0].Id;
                customer.name = nameOnCard;
                customer.email = billingEmail;
                customer.accountId = accId;
                system.debug('customer--->' +customer );
                if (!Test.isRunningTest()) {
                    customer.registerCustomer();
                }    
            }
            pm = bt_stripe.P360_API_v1.paymentMethodFactory();
            pm.paymentGatewayId = pgList[0].Id;
            pm.customer = customer;
            pm.cardHolderName = nameOnCard; 
            pm.cardNumber = cardNumber; // valid test card - will result in a successful PM and Transaction
            pm.cardExpYear = expYear;
            pm.cardExpMonth = expMonth;
            pm.cvv = cvc;            
            pm.email = billingEmail;
            pm.postalCode = postalCode;
            pm.defaultpm = isDefault;
            /*if(nameOfObject == 'Account' && !custAdd.isEmpty()){
                pm.street = custAdd[0].varcpq__Street__c;
                pm.city = custAdd[0].varcpq__City__c;
                pm.state = custAdd[0].varcpq__State__c;           
                pm.country = custAdd[0].Country__c;
            }
            if(nameOfObject == 'Quote' && !custAddQuote.isEmpty()){
                pm.street = custAddQuote[0].BillingStreet;
                pm.city = custAddQuote[0].BillingCity;
                pm.state = custAddQuote[0].BillingState;           
                pm.country = custAddQuote[0].BillingCountry;
            }*/
            
            
            // this method creates a Payment Method in the Payment Gateway but does not yet create a Payment Method in SF
            if (!Test.isRunningTest()) {
                pm.registerPM();
            }
            
            
            /*if (String.isNotBlank(pm.record.bt_stripe__Error_Message__c)) {
// commit work here will create a Payment Gateway Customer and Payment Method (w Status = Invalid) record
System.debug('Inside Error Block');
//bt_stripe.P360_API_v1.commitWork();
System.debug('pm.record.bt_stripe__Payment_Method_Status__c = ' + pm.record.bt_stripe__Payment_Method_Status__c);
System.debug('pm.record.bt_stripe__Error_Message__c = ' + pm.record.bt_stripe__Error_Message__c);
System.debug('customer.record.Id = ' + customer.record.Id);
//return ; // return the Payment Gateway Customer Id and error message to the Component/Page

}*/
            system.debug('Inside Try');
        }
        
        catch (bt_stripe.P360_API_v1.P360_Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
            System.debug('ERROR---->'+e.getMessage());
            String fullMessage = e.getMessage();
            if (fullMessage.contains('(TESTMODE)')) {
                ErrorMessage = fullMessage.substringAfter('(TESTMODE)').trim();
            } else {
                ErrorMessage = fullMessage;
            }           
            System.debug('ERRORMSG---->'+ErrorMessage);        
            RETURN ErrorMessage;                 
        }
        if (!Test.isRunningTest()) {
            bt_stripe.P360_API_v1.commitWork(); // commit work so SF records are created  
        }
       
        // get the Payment Gateway Customer record so the Id can be used if you want to ask for another Payment Method from the customer
        bt_stripe__Stripe_Customer__c paymentGatewayCustomer = customer.record;
        System.debug('paymentGatewayCustomer = ' + paymentGatewayCustomer);
        System.debug('paymentGatewayCustomer.Id = ' + paymentGatewayCustomer.Id);        
        // this Payment Method will have Payment Method Status = Invalid and a Error Message = Your card has insufficient funds.
        bt_stripe__Payment_Method__c paymentMethod = pm.record;
        System.debug('paymentMethod = ' + paymentMethod);
        System.debug('paymentMethod.Id = ' + paymentMethod.Id);
        System.debug('paymentMethod.bt_stripe__Default_Payment_Method__c => '+paymentMethod.bt_stripe__Default_Payment_Method__c);
        Return null;         
    }
    
    
    /*This Method Return AccountId and objectApiName So that we can Pass that From LWC to Apex 
To preventDuplicateAPayMethod ,Tag Account while creating Transaction for capturing and sending AuthLink */    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getObjectApiName(Id IdOfRecord) {
        Map<String, String> result = new Map<String, String>();
        String objectApiName = IdOfRecord.getSObjectType().getDescribe().getName();
        System.debug('objectApiName------->' + objectApiName);      
        result.put('objApiName', objectApiName);
        
        try {
            if (objectApiName == 'Account') {
                result.put('accountId', IdOfRecord);
            } else if (objectApiName == 'Quote') {
                Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE Id = :IdOfRecord LIMIT 1];
                if (quote.OpportunityId != null) {
                    Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :quote.OpportunityId LIMIT 1];
                    if (opp.AccountId != null) {
                        result.put('accountId', opp.AccountId);
                    }
                }
            }
            else if(objectApiName == 'varcpq__Invoice__c'){
                List<varcpq__Invoice__c>InvRec = [SELECT ID,varcpq__Client__c From varcpq__Invoice__c WHERE ID =:IdOfRecord LIMIT 1];
                Id AccountId = InvRec[0].varcpq__Client__c;
                System.debug('InvRec[0].varcpq__Client__c--->'+InvRec[0].varcpq__Client__c);
                result.put('accountId', InvRec[0].varcpq__Client__c);
                System.debug('result Map whenobjectApiName == varcpq__Invoice__c--->'+result);
            }
        } catch (Exception e) {
            System.debug('Error while fetching related account ID: ' + e.getMessage());           
        } 
        return result;
    }
    //<-----------------METHODS RELATED TO AUTHORIZE AMOUNT STARTS FROM HERE--------------->
    
    @AuraEnabled
    public static String preventPMDuplication(Id AccountId,String cardName,String cardNumber,String expMonth,String expYear){
        
        List<bt_stripe__Payment_Method__c> extPMList = [SELECT ID,bt_stripe__Account__c,bt_stripe__Card_Holder_Name__c,bt_stripe__Payment_Method_Status__c,bt_stripe__Card_Expiration_Month__c,bt_stripe__Card_Expiration_Year__c
                                                        ,bt_stripe__Card_Last_4_Digit__c  FROM bt_stripe__Payment_Method__c WHERE bt_stripe__Account__c =: AccountId AND bt_stripe__Payment_Method_Status__c = 'Valid'];
        system.debug('extPMList in prevemtPMDuplication--->'+extPMList);
        system.debug('extPMList in prevemtPMDuplication--->'+extPMList.size());
        String paddedMonth = expMonth != null && expMonth.length() == 1 ? '0' + expMonth : expMonth;
        
        if(!extPMList.isEmpty()){
            for(bt_stripe__Payment_Method__c PM : extPMList){
                String last4 = cardNumber.substring(cardNumber.length() - 4);
                system.debug('last4--->'+last4);
                if(PM.bt_stripe__Card_Last_4_Digit__c ==  last4 
                   
                   && PM.bt_stripe__Card_Expiration_Month__c == paddedMonth 
                   && PM.bt_stripe__Card_Expiration_Year__c == expYear
                  ){
                      System.debug('Inside DPM check');
                      Return 'Duplicate payment method detected. Please use a different one'; 
                  }                      
            }
        }
        Return 'You can create Payment Method';             
    }
    
    @AuraEnabled(cacheable=true)
    public static List<bt_stripe__Payment_Method__c> paymentMethods(Id quoteId){        
        List<Quote>quote = [SELECT ID,OpportunityId From Quote WHERE ID =:quoteId];
        Id oppId = quote[0].OpportunityId;
        List<Opportunity> oppRec= [SELECT Id ,AccountId FROM Opportunity Where ID =:oppId];
        Id AccountId = oppRec[0].AccountId;
        
        LIST<bt_stripe__Payment_Method__c> paymentMethodList =[SELECT ID,Name,bt_stripe__Account__c,bt_stripe__Card_Holder_Name__c,bt_stripe__Payment_Method_Status__c ,bt_stripe__Default_Payment_Method__c,bt_stripe__Card_Expiration_Month__c,bt_stripe__Card_Expiration_Year__c,bt_stripe__Card_Last_4_Digit__c 
                                                               FROM bt_stripe__Payment_Method__c  WHERE bt_stripe__Account__c =: AccountId  AND bt_stripe__Payment_Method_Status__c = 'Valid'];
        
        if(!paymentMethodList.isEmpty()){
            RETURN paymentMethodList;   
        }else{
            RETURN NULL;
        }        
    }
    @AuraEnabled(cacheable=true)
    public static List<bt_stripe__Payment_Method__c> paymentMethodsInv(Id InvId){ 
        List<varcpq__Invoice__c>InvRec = [SELECT ID,varcpq__Client__c,varcpq__Sales_Order__c From varcpq__Invoice__c WHERE ID =:InvId];
        Id AccountId = InvRec[0].varcpq__Client__c;
        Id salesOrderId = InvRec[0].varcpq__Sales_Order__c;
         SET<Id>PmIds = new SET<Id>();
        List<bt_stripe__Transaction__c> authorizedTransactions = [SELECT ID,Sales_Order__c,bt_stripe__Payment_Status__c,bt_stripe__Payment_Method__c FROM bt_stripe__Transaction__c
                                                                  WHERE bt_stripe__Payment_Status__c = 'Authorized' AND Sales_Order__c =:salesOrderId];
       
        if(!authorizedTransactions.isEmpty()){
            for(bt_stripe__Transaction__c tran : authorizedTransactions ){
               PmIds.add(tran.bt_stripe__Payment_Method__c); 
            }
        }
        System.debug('PmIds in paymentMethodsInv---->'+PmIds);
        LIST<bt_stripe__Payment_Method__c> paymentMethodList = new LIST<bt_stripe__Payment_Method__c>();
        
        if(PmIds != null){
         paymentMethodList =[SELECT ID,Name,bt_stripe__Account__c,bt_stripe__Card_Holder_Name__c,bt_stripe__Payment_Method_Status__c,bt_stripe__Default_Payment_Method__c
                                                               FROM bt_stripe__Payment_Method__c  WHERE bt_stripe__Payment_Method_Status__c = 'Valid' AND ID IN :PmIds];
    }
        
        if(!paymentMethodList.isEmpty()){
            RETURN paymentMethodList;   
        }else{
            RETURN NULL;          
        }    
    }  
    
    //This Method is to tag QuoteDetails While Authorizing and sending AuthLink to Customer on Quote
    @AuraEnabled(cacheable=true)
    public static List<Quote> quoteDetails(Id quoteId){
        List<Quote> quoteList = [SELECT ID,Name,AccountId,Account.Name,GrandTotal,CurrencyIsoCode,Bill_to_email__c,BillingName
                                 FROM Quote Where Id =: quoteId]; 
        if(!quoteList.isEmpty()){
            RETURN quoteList;  
        }
        else{
            RETURN NULL;
        }
    }
    
    
    //This Method is to tag InvoiceDetails While Capturing Amount on Invoice
    @AuraEnabled(cacheable=true)
    public static List<varcpq__Invoice__c> invoiceDetails(Id InvId){
        List<varcpq__Invoice__c> InvList = [SELECT ID,Name,varcpq__Client__c,Grand_Total__c,CurrencyIsoCode,Bill_to_Company_Name__c
                                            FROM varcpq__Invoice__c Where Id =: InvId]; 
        if(!InvList.isEmpty()){
            RETURN InvList;  
        }
        else{
            RETURN NULL;
        }
    }
    
    //<-------------------This Method Create Transaction To Authorize Amount on Quote------------------------------>
    @AuraEnabled
    public static string createTransactionToAuthorize(string PMId,Decimal AmountOnQuote,Id QuoteId,Id accId,Id SOID){
                
        List<Quote>quoteList = [SELECT ID,GrandTotal FROM Quote WHERE ID =:QuoteId LIMIT 1];
        if(!quoteList.isEmpty()){
            if(AmountOnQuote > quoteList[0].GrandTotal){
                RETURN 'Entered amount is greater than quote amount';
            } 
        }
       
         /* List<bt_stripe__Transaction__c> tranExtList = [SELECT ID,bt_stripe__Related_Account__c,Quote__c,bt_stripe__Payment_Status__c,Sales_Order__c,bt_stripe__Payment_Method__c,bt_stripe__Amount__c FROM bt_stripe__Transaction__c
                                                       Where bt_stripe__Related_Account__c =: accId AND bt_stripe__Payment_Status__c = 'Authorized' AND Quote__c =: QuoteId];
        
        if(!tranExtList.isEmpty()){
            for(bt_stripe__Transaction__c tranObj : tranExtList){
                if(tranObj.Sales_Order__c != null){
                if(tranObj.bt_stripe__Payment_Status__c == 'Authorized' 
                  && tranObj.bt_stripe__Related_Account__c == accId && tranObj.Quote__c == QuoteId
                  && tranObj.bt_stripe__Payment_Method__c == PMId && tranObj.bt_stripe__Amount__c == AmountOnQuote
                  && tranObj.Sales_Order__c == SOID)
                {
                   RETURN 'Amount for this credit card has already been authorized.';       
               }               
            }                
           }
        }*/
        List<bt_stripe__Payment_Gateway__c> pgList = [SELECT Id FROM bt_stripe__Payment_Gateway__c
                                                      WHERE bt_stripe__Default__c = true LIMIT 1];
        System.debug('PMID----->'+pgList[0].Id);
        System.debug('pgList----->'+PMId);
        bt_stripe.P360_API_v1.PM pm;
        bt_stripe.P360_API_v1.Tra tran;
        String ErrorMessage ='';
        try{
            pm = bt_stripe.P360_API_v1.paymentMethodFactory(PMId);
            tran = bt_stripe.P360_API_v1.transactionFactory();
            tran.paymentGatewayId = pgList[0].Id;
            tran.pm = pm;
            tran.amount = AmountOnQuote;
            //tran.register();
            if (!Test.isRunningTest()) {
                tran.authorize();
            }
            
        }
        catch(bt_stripe.P360_API_v1.P360_Exception e){
            System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
            System.debug('ERROR---->'+e.getMessage());      
        }
        // commit work so SF records are created
        if (!Test.isRunningTest()) {
            bt_stripe.P360_API_v1.commitWork();
          
            
            bt_stripe__Transaction__c transactionRecord = tran.record;
            System.debug('transactionRecord = ' + transactionRecord);
            System.debug('transactionRecord.Id = ' + transactionRecord.Id);
            bt_stripe__Transaction__c tranRecord = [SELECT Id ,bt_stripe__Error_Message__c ,bt_stripe__Transaction_Status__c,bt_stripe__Payment_Status__c,bt_stripe__Related_Account__c
                                                    FROM bt_stripe__Transaction__c WHERE Id =: transactionRecord.Id];
            system.debug('Transaction Record Now--->'+tranRecord); 
            
            tranRecord.Quote__c = QuoteId ;
            if(SOID != null){
            tranRecord.Sales_Order__c = SOID;  
            }
            Update tranRecord;
            System.debug('tranRecord Quote-->'+tranRecord.Quote__c);
            
            System.debug('Status and Error Msg Of transaction---->'+tranRecord.bt_stripe__Transaction_Status__c +'and'+tranRecord.bt_stripe__Payment_Status__c + 'and'+tranRecord.bt_stripe__Error_Message__c);
            if(String.isNotBlank(tranRecord.bt_stripe__Error_Message__c) ){
                system.debug('Transaction '+tranRecord.bt_stripe__Transaction_Status__c +'\n'+tranRecord.bt_stripe__Error_Message__c);
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c +'\n'+tranRecord.bt_stripe__Error_Message__c; 
                
            }else if(tranRecord.bt_stripe__Payment_Status__c != 'Authorized'){
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c+'.'+'\n'+'Error Authorizing Amount';                    
            }
            else if(tranRecord.bt_stripe__Payment_Status__c == 'Authorized'){
                tranRecord.Status_Of_Transaction__c = 'Preauthorized';
                Update tranRecord;
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c +'.'+'\n'+'Amount Authorized Successfully';        
            }else{
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c ; 
            }
        }else{
            Return 'Test Response';
        } 
        
        
    }
    
    //Show mail on request card details screen
    @AuraEnabled
    Public static String returnMail(Id contactId){
         String CustEmail;
        List<Contact> conList = new List<Contact>();
        If(contactId != null){
         conList = [Select Id,Name,Email FROM Contact Where ID =:contactId LIMIT 1];
          }
        if(!conList.isEmpty()){
          CustEmail = conList[0].Email;
         System.debug('conList[0].Email-----------------------+++++++++++=====>'+conList[0].Email);
          Return CustEmail; 
        }
        Return Null;
    }


   //<--------------------------------- Method To Send AuthLink to Customer--------------------------------> 
   
    @AuraEnabled 
    Public Static String sendAuthLinkToCustomer(Decimal AmountOnQuote,String currencyCode,String billingEmail,String BillingName,Id AccId,Id QuoteId,Id SOID,Id billCon){
        
        List<bt_stripe__Payment_Gateway__c> pgList = [SELECT Id FROM bt_stripe__Payment_Gateway__c
                                                      WHERE bt_stripe__Default__c = true LIMIT 1];
        List<varcpq__Sales_Order__c> soList = new List<varcpq__Sales_Order__c>();
         List<varcpq__Sales_Order__c> soListTest = new List<varcpq__Sales_Order__c>();
        System.debug('PMID----->'+pgList[0].Id);
        bt_stripe.P360_API_v1.Tra tran;
        String resultOfSendEmail ='';
        try{
            
            tran = bt_stripe.P360_API_v1.transactionFactory();
            tran.paymentGatewayId = pgList[0].Id;
            tran.currencyCode = currencyCode;
            tran.amount = AmountOnQuote;
            if (!Test.isRunningTest()) {
                tran.register();
                // tran.authorize();
            }
        }
        catch(bt_stripe.P360_API_v1.P360_Exception e){
            System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
            System.debug('ERROR---->'+e.getMessage());      
        }
        
        bt_stripe__Transaction__c tranRecord = new bt_stripe__Transaction__c();
        
        Id salesOrderId ;
        Id ContactId;
        String CustEmail;
        List<Contact> conList = new List<Contact>();
        If(billCon != null){
         conList = [Select Id,Name,Email FROM Contact Where ID =:billCon LIMIT 1];
          }
        if(!conList.isEmpty()){
          ContactId = conList[0].Id;
          CustEmail =conList[0].Email;
           System.debug('ContactId In SendEmailToCustomer--->'+ContactId+' AND CustEmail'+CustEmail);
        }
        
        if (!Test.isRunningTest()) {
            bt_stripe.P360_API_v1.commitWork();
            bt_stripe__Transaction__c transactionRecord = tran.record;
            System.debug('transactionRecord = ' + transactionRecord);
            System.debug('transactionRecord.Id = ' + transactionRecord.Id);
            tranRecord = [SELECT Id ,bt_stripe__Error_Message__c,bt_stripe__Related_Account__c,Quote__c,bt_paylink__AuthLink__c,bt_stripe__Transaction_Status__c,bt_stripe__Payment_Status__c
						FROM bt_stripe__Transaction__c WHERE Id =: transactionRecord.Id];
            system.debug('Transaction Record While sending AuthLink--->'+tranRecord);
            soList = [SELECT ID,Pending_Credit_Card_Preauthorization__c,varcpq__SO_Number__c ,Authorization_Url__c FROM varcpq__Sales_Order__c WHERE ID =: SOID LIMIT 1];
            system.debug('QuoteId----->'+QuoteId);
            tranRecord.bt_stripe__Related_Account__c = AccId ;
            tranRecord.Quote__c = QuoteId ;
           
            if(SOID != null){
            salesOrderId = SOID;
            tranRecord.Sales_Order__c = SOID;
                if(!soList.isEmpty()){
                  soList[0].Authorization_Url__c = tranRecord.bt_paylink__AuthLink__c;  
                  soList[0].Pending_Credit_Card_Preauthorization__c = true;  
                }   
            }
            Update tranRecord;            
            UPDATE soList;
            tranRecord = [SELECT Id ,bt_stripe__Error_Message__c,bt_stripe__Related_Account__c,Quote__c,Sales_Order__c, Sales_Order__r.Name,Sales_Order__r.varcpq__SO_Number__c,bt_paylink__AuthLink__c,bt_stripe__Transaction_Status__c,bt_stripe__Payment_Status__c
                          FROM bt_stripe__Transaction__c WHERE Id =: transactionRecord.Id];
            system.debug('soList After Update---->'+soList);
            System.debug('AuthLink in soList AfterUpdate---->'+soList[0].Authorization_Url__c);
        }else{
            System.debug('Inside else part foe test class sendAuthLinkToCustomer---------->');
            salesOrderId = SOID;
            Id recTypeId = [SELECT Id, Name, SobjectType, IsActive FROM RecordType where SobjectType = 'bt_stripe__Transaction__c' AND Name = 'Charge' LIMIT 1].Id;
            bt_stripe__Transaction__c newTrans = new bt_stripe__Transaction__c();
            newTrans.CurrencyIsoCode = 'USD';
            newTrans.RecordTypeId = recTypeId;
            newTrans.bt_stripe__Amount__c = 100.00;
            newTrans.bt_stripe__Related_Account__c = AccId ;
            newTrans.Quote__c = QuoteId ;
            newTrans.Sales_Order__c = SOID;
            
            Insert newTrans;            
            soList = [SELECT ID,Pending_Credit_Card_Preauthorization__c,varcpq__SO_Number__c ,Authorization_Url__c FROM varcpq__Sales_Order__c WHERE ID =: SOID LIMIT 1];
            
            tranRecord = [SELECT Id ,bt_stripe__Error_Message__c,bt_stripe__Related_Account__c,Quote__c,Sales_Order__c, Sales_Order__r.Name,Sales_Order__r.varcpq__SO_Number__c,bt_paylink__AuthLink__c,bt_stripe__Transaction_Status__c,bt_stripe__Payment_Status__c
                          FROM bt_stripe__Transaction__c WHERE Id =: newTrans.Id];          
            if(!soList.isEmpty()){
                  soList[0].Authorization_Url__c = tranRecord.bt_paylink__AuthLink__c;  
                  soList[0].Pending_Credit_Card_Preauthorization__c = true;  
                }
             UPDATE soList;          
        }    
        //<--------------Send Email to Customer Using Email Template---------------->
         
         EmailTemplate template = [SELECT Id, DeveloperName, Name, Subject,Body,HtmlValue FROM EmailTemplate 
                                         WHERE DeveloperName = 'AuthLink_Email_Template' LIMIT 1];
        
        System.debug('template AuthLink in customVTController---------->'+template);
         System.debug('salesOrderId Outside------>'+salesOrderId);
         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        if(ContactId != null && salesOrderId != null){
            System.debug('salesOrderId Inside------>'+salesOrderId);
            System.debug('CustEmail---->'+CustEmail);
        if(CustEmail!= null && tranRecord.Sales_Order__c!= null ){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //mail.setSenderDisplayName('Salesforce');
            mail.setUseSignature(false);
            mail.setBccSender(false);
            mail.setSaveAsActivity(true);
            //Assigning the receiver Mail Address
            //mail.setToAddresses(new String[]{CustEmail});
            System.debug('mail.toAddresses---->'+mail.toAddresses);
            //mail.setSubject('Payment Authorization Request.');
            mail.setTemplateId(template.Id);
            mail.setTargetObjectId(ContactId);
            mail.setWhatId(salesOrderId);
            mail.setReplyTo('dnyanesh.gawali@clutchsolutions.com');
            //mail.setTreatTargetObjectAsRecipient(true);
            //mail.setSubject(template.Subject);
            //mail.setHTMLBody(template.HtmlValue);
            //mail.setPlainTextBody(template.Body);
            mails.add(mail);    
        }
    }
        
    
        if(mails.size()>0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            if (results[0].success)
            {
                System.debug('The email was sent successfully.');
                resultOfSendEmail = 'AuthLink sent successfully';
            } else {
                System.debug('The email failed to send: '+ results[0].errors[0].message);
                resultOfSendEmail = 'Error Sending Authorization Link.';
            }
        }
        
        RETURN resultOfSendEmail; 
    }
    
    //<-----------------------METHODS TO CAPTURE AMOUNT ON QUOTE STARTS FROM HERE--------------------------->
    
    @AuraEnabled 
    public static string captureTransaction(string PMId,Decimal AmountOnInvoice,Id InvAccId,Id InvId){
        Decimal remainingAmount;
        List<varcpq__Invoice__c> invList =[SELECT ID,Grand_Total__c,Captured_Charges__c FROM varcpq__Invoice__c WHERE ID =: InvId];
        if(!invList.isEmpty()){
            System.debug('invList[0].Grand_Total__c------->'+invList[0].Grand_Total__c+'invList[0].Captured_Charges__c---->'+invList[0].Captured_Charges__c);
            if(invList[0].Grand_Total__c == invList[0].Captured_Charges__c){
                RETURN 'Total invoice amount has already been captured';
        }
            if(AmountOnInvoice > invList[0].Grand_Total__c ){
               Return 'Entered Amount is greater than invoice amount'; 
            }
            
            remainingAmount = invList[0].Grand_Total__c - invList[0].Captured_Charges__c;
            if(AmountOnInvoice > remainingAmount){
               Return 'Remaining amount to capture is '+remainingAmount+' You cannot capture more than this amount'; 
            }           
       }
       
        
        //This is prevent the user to capture amount from payment method which was authorized with less amount.
        List<varcpq__Invoice__c>InvRec = [SELECT ID,varcpq__Client__c,varcpq__Sales_Order__c From varcpq__Invoice__c WHERE ID =:InvId];
        Id salesOrderId = InvRec[0].varcpq__Sales_Order__c;
        List<bt_stripe__Transaction__c> authorizedTransactions = [SELECT ID,Sales_Order__c,bt_stripe__Payment_Status__c,bt_stripe__Payment_Method__c,bt_stripe__Amount__c FROM bt_stripe__Transaction__c
                                                                  WHERE bt_stripe__Payment_Status__c = 'Authorized' AND Sales_Order__c =:salesOrderId];
        MAP<Id,Decimal> PmIdVSTranAmount = new MAP<Id,Decimal>();
        if(!authorizedTransactions.isEmpty()){
            for(bt_stripe__Transaction__c tran : authorizedTransactions){
                if(!PmIdVSTranAmount.containsKey(tran.bt_stripe__Payment_Method__c)){
                    PmIdVSTranAmount.put(tran.bt_stripe__Payment_Method__c,tran.bt_stripe__Amount__c);
                }else{
                    PmIdVSTranAmount.put(tran.bt_stripe__Payment_Method__c,PmIdVSTranAmount.get(tran.bt_stripe__Payment_Method__c)+tran.bt_stripe__Amount__c);    
                }
            }
            system.debug('PmIdVSTranAmount-------------->'+PmIdVSTranAmount);
            if(!PmIdVSTranAmount.isEmpty()){
                if(PmIdVSTranAmount.containsKey(PMId) && PmIdVSTranAmount.get(PMId) < AmountOnInvoice){
                   RETURN 'You can not capture more than '+PmIdVSTranAmount.get(PMId)+' from selected card';
                }               
         }
      }
        
        //This Logic is to identify remaining amount available to capture against the authorized amount on particular card.
         List<bt_stripe__Transaction__c> capturedTransactions = [SELECT ID,Sales_Order__c,bt_stripe__Payment_Status__c,bt_stripe__Payment_Method__c,bt_stripe__Amount__c, Invoice__r.varcpq__Status__c FROM bt_stripe__Transaction__c
                                                                  WHERE bt_stripe__Payment_Status__c = 'Captured' AND Sales_Order__c =:salesOrderId];
        
         MAP<Id,Decimal> PmIdVSCapturedTranAmount = new MAP<Id,Decimal>();
         Decimal AuthorizedAmount = 0;
         Decimal CapturedAmount = 0;
        Decimal availableAmountToCapture = 0;
        if(!PmIdVSTranAmount.isEmpty() && !capturedTransactions.isEmpty()){
            for(bt_stripe__Transaction__c trn : capturedTransactions){
                if(!PmIdVSCapturedTranAmount.containsKey(trn.bt_stripe__Payment_Method__c)){
                    PmIdVSCapturedTranAmount.put(trn.bt_stripe__Payment_Method__c,trn.bt_stripe__Amount__c);
                }else{
                    PmIdVSCapturedTranAmount.put(trn.bt_stripe__Payment_Method__c,PmIdVSCapturedTranAmount.get(trn.bt_stripe__Payment_Method__c)+trn.bt_stripe__Amount__c);
                }
            }
            
            if(!PmIdVSCapturedTranAmount.isEmpty()){
                if(PmIdVSTranAmount.containsKey(PMId) && PmIdVSCapturedTranAmount.containsKey(PMId)){
                   AuthorizedAmount = PmIdVSTranAmount.get(PMId);
                   CapturedAmount   = PmIdVSCapturedTranAmount.get(PMId);
                   availableAmountToCapture = AuthorizedAmount - CapturedAmount;
                     System.debug('AuthorizedAmount----------------------------->'+AuthorizedAmount);
                     System.debug('CapturedAmount----------------------------->'+CapturedAmount);
                    System.debug('availableAmountToCapture----------------------------->'+availableAmountToCapture);
                    if(availableAmountToCapture < AmountOnInvoice){
                        RETURN 'Available Amount to capture from selected card is '+availableAmountToCapture+' You can not capture more than available amount from selected card';
                    }
                }
            }
            
        }
        
        
        
        
        
        List<bt_stripe__Payment_Gateway__c> pgList = [SELECT Id FROM bt_stripe__Payment_Gateway__c
                                                      WHERE bt_stripe__Default__c = true LIMIT 1];
        bt_stripe.P360_API_v1.PM pm;
        bt_stripe.P360_API_v1.Tra tran;
        system.debug('AmountOnInvoice--------->'+AmountOnInvoice);
        try{
            pm = bt_stripe.P360_API_v1.paymentMethodFactory(PMId);
            tran = bt_stripe.P360_API_v1.transactionFactory();
            tran.paymentGatewayId = pgList[0].Id;
            tran.pm = pm;
            tran.amount = AmountOnInvoice;
            if (!Test.isRunningTest()) {
                tran.capture();
            }
        }
        catch(bt_stripe.P360_API_v1.P360_Exception e){
            System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
            System.debug('ERROR---->'+e.getMessage());      
        }
        if (!Test.isRunningTest()) {
            bt_stripe.P360_API_v1.commitWork();
            
            bt_stripe__Transaction__c transactionRecord = tran.record;
            System.debug('transactionRecord = ' + transactionRecord);
            System.debug('transactionRecord.Id = ' + transactionRecord.Id);
            
            bt_stripe__Transaction__c tranRecord = [SELECT Id ,bt_stripe__Error_Message__c ,bt_stripe__Amount__c,bt_stripe__Transaction_Status__c,bt_stripe__Payment_Status__c
                                                    FROM bt_stripe__Transaction__c WHERE Id =: transactionRecord.Id];
            varcpq__Invoice__c Invoice = [SELECT ID,varcpq__Sales_Order__c FROM varcpq__Invoice__c WHERE ID =:InvId LIMIT 1];
            
            system.debug('Transaction Record In Capture Transaction--->'+tranRecord);
            //update Transaction with accountId and invoiceId
            tranRecord.bt_stripe__Related_Account__c = InvAccId;
            tranRecord.Invoice__c = InvId;
            tranRecord.Sales_Order__c = Invoice.varcpq__Sales_Order__c;
            Update tranRecord;
           
            Map<Id,Decimal>soIdVsTranAmount = new Map<Id,Decimal>();
            List<varcpq__Sales_Order__c> soListToUpdate = new List<varcpq__Sales_Order__c>();
            if(tranRecord.bt_stripe__Payment_Status__c == 'Captured'){                
             Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c +'.'+'\n'+'Amount Captured Successfully';
                 
            }else if(String.isNotBlank(tranRecord.bt_stripe__Error_Message__c)){
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c +'\n'+tranRecord.bt_stripe__Error_Message__c;
            }
            else{
                Return 'Transaction '+tranRecord.bt_stripe__Transaction_Status__c;
            }
        }else{
            return 'Test Response';
        }
        
    }
    
    
}