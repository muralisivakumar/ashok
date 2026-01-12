/***************************************************************************************************************************************************************************************
* @description       : Controller Class for customSalesOrder LWC and it's child components. Creating Sales Order from Quote.
* @author            : Aress Software - AS
* @Created date      : 09/12/2024
* @related class     : -
* @test Class        : - SalesOrderWizardCustom_Test
* @last modified on  : - 10/10/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class SalesOrderWizardCustom {
    
    @AuraEnabled
    public static Quote getQuoteMargin(Id quoteId) { 
        Quote quote = [
            SELECT Id,Name, GrandTotal, varcpq__Total_Margin_Dollor__c,CurrencyISOCode,Account.Is_On_Credit_Hold__c
            FROM Quote
            WHERE Id = :quoteId
        ];
        return quote;
    }

    @AuraEnabled
    public static string getAccCreditDetails(Id quoteId){
        Quote quote = [
            SELECT Id,GrandTotal, AccountId,Account_Record_Type__c, Account.Is_On_Credit_Hold__c,Account.Credit_Limit__c,Account.Total_SO_Paid_Amount_Non_CC__c, Account.Total_SO_Grand_Total_Non_CC__c 
            FROM Quote
            WHERE Id = :quoteId
        ];
        
        Double creditUsed = (quote.Account.Total_SO_Grand_Total_Non_CC__c - quote.Account.Total_SO_Paid_Amount_Non_CC__c) + quote.GrandTotal;
        String accountType = quote.Account_Record_Type__c;
        Boolean isOnCreditHold = quote.Account.Is_On_Credit_Hold__c;
        if (isOnCreditHold) {
        if (accountType == 'US Account') {
            return 'Account is on Credit Hold. Please reach out to Accounts Receivable before converting this Quote to a Sales Order. Email: invoices@clutchsolutions.com';
        } else if (accountType == 'Canadian Account') {
            return 'Account is on Credit Hold. Please reach out to Accounts Receivable before converting this Quote to a Sales Order.  Email: invoicescanada@clutchsolutions.com';
        } else {
            return 'Account is on Credit Hold. Please contact support.';
        }
       }
       
         
/*if (isOnCreditHold) {
    if (accountType == 'US Account') {
        return '<p><strong>Account is on Credit Hold.</strong></p>' +
               '<p>Please reach out to Accounts Receivable before converting this Quote to a Sales Order.</p>' +
               '<p>Email: <a href="mailto:invoices@clutchsolutions.com">invoices@clutchsolutions.com</a></p>';
    } else if (accountType == 'Canadian Account') {
        return '<p><strong>Account is on Credit Hold.</strong></p>' +
               '<p>Please reach out to Accounts Receivable before converting this Quote to a Sales Order.</p>' +
               '<p>Email: <a href="mailto:invoicescanada@clutchsolutions.com">invoicescanada@clutchsolutions.com</a></p>';
    } else {
        return '<p><strong>Account is on Credit Hold.</strong> Please contact support.</p>';
    }
}*/

        else if(quote.Account.Credit_Limit__c == null){
            return 'No credit limit set for this account';
        }else if(quote.Account.Credit_Limit__c != null && quote.Account.Credit_Limit__c <= creditUsed) {
            return 'Credit limit exceeded. Current credit used: $' + String.valueOf(creditUsed) + ' and Credit Limit: $' + String.valueOf(quote.Account.Credit_Limit__c);
        }
        else{
            return '';
        }        
    }
    @AuraEnabled(cacheable=true)
    public static String getQuoteSuppliers(Id quoteId){
        Map<String,String> suppliers = new Map<String,String>();
        List<QuoteLineItem> qlis = [SELECT id, Product2.varcpq__Distributor_Account__c, product2.varcpq__Distributor_Account__r.Name from QuoteLineItem WHERE QuoteId=: quoteId];
        for(QuoteLineItem qli:qlis){
            if(!suppliers.containskey(qli.Product2.varcpq__Distributor_Account__c)){
                suppliers.put(qli.Product2.varcpq__Distributor_Account__c,qli.Product2.varcpq__Distributor_Account__r.Name);
            }
        }
        System.debug(suppliers);
        if(!suppliers.isEmpty()){
        	String suppliersJson = JSON.serialize(suppliers);
        	return suppliersJson;
        }
        return null;
    }

    @AuraEnabled
    public static Quote getQuoteCustomerPO(Id quoteId) { 
    Quote quote = [
        SELECT Id, Customer_PO__c
        FROM Quote
        WHERE Id = :quoteId
    ];
    return quote;
}

    @AuraEnabled
    public static List<conAddWrapper> getContact(Id quoteId, String key) {
        List<conAddWrapper> conWrapList = new List<conAddWrapper>();
        Quote quote = [
            SELECT Id, AccountId, BillingName, ShippingName
            FROM Quote
            WHERE Id = :quoteId
        ];
        
        key = '%' + key + '%';
        List<Contact> conList = new List<Contact>();
        if (key != '') {
            conlist = [
                SELECT
                Id,
                Name,
                Phone,
                Email,
                Default_Billing_Contact__c,
                Default_Shipping_Contact__c,
                Active__c
                FROM Contact
                WHERE
                AccountId = :quote.AccountId
                AND Active__c = TRUE
                AND (Name LIKE :Key OR Email LIKE :Key OR Phone LIKE :Key)
                ORDER BY Is_Default__c DESC
               
            ];
            for (Contact con : conlist) {
                conAddWrapper conWrap = new conAddWrapper();
                conWrap.recId = con.Id;
                conWrap.Name = con.Name;
                conWrap.email = con.email;
                conWrap.phone = con.Phone;
                if (String.isBlank(quote.BillingName)) {
                    conWrap.DefaultBill = con.Default_Billing_Contact__c;
                    conWrap.DefaultShip = con.Default_Shipping_Contact__c;
                } else if (String.isBlank(quote.ShippingName)) {
                    conWrap.DefaultBill = con.Default_Billing_Contact__c;
                    conWrap.DefaultShip = con.Default_Shipping_Contact__c;
                } else if (quote.BillingName == quote.ShippingName && con.Name == quote.BillingName) {
                    conWrap.DefaultBill = true;
                    conWrap.DefaultShip = true;
                } else if (quote.BillingName == con.Name) {
                    conWrap.DefaultBill = true;
                    conWrap.DefaultShip = false;
                } else if (quote.ShippingName == con.Name) {
                    conWrap.DefaultShip = true;
                    conWrap.DefaultBill = false;
                } else {
                    conWrap.DefaultBill = false;
                    conWrap.DefaultShip = false;
                }
                
                conWrapList.add(conWrap);
            }
            System.debug('in if');
        } else {
            conlist = [
                SELECT
                Id,
                Name,
                Phone,
                Email,
                Default_Billing_Contact__c,
                Default_Shipping_Contact__c,
                Active__c
                FROM Contact
                WHERE AccountId = :quote.AccountId AND Active__c = TRUE
                ORDER BY Is_Default__c DESC
                
            ];
            for (Contact con : conlist) {
                conAddWrapper conWrap = new conAddWrapper();
                conWrap.recId = con.Id;
                conWrap.Name = con.Name;
                conWrap.email = con.email;
                conWrap.phone = con.Phone;
                conWrap.DefaultBill = con.Default_Billing_Contact__c;
                conWrap.DefaultShip = con.Default_Shipping_Contact__c;
                conWrapList.add(conWrap);
            }
            system.debug('in else ');
        }
        if (!conWrapList.isEmpty()) {
            return conWrapList;
        }
        return null;
    }
    @AuraEnabled
    public static list<conAddWrapper> getCustomerAddress(Id quoteId, String key) {
        List<conAddWrapper> addWrapList = new List<conAddWrapper>();
        Quote quote = [
            SELECT
            Id,
            AccountId,
            Ship_Customer_Address_Id__c,
            Bill_Customer_Address_Id__c
            FROM Quote
            WHERE Id = :quoteId
        ];
        list<varcpq__customer_address__c> customerAddList = new List<varcpq__customer_address__c>();
        
        key = '%' + key + '%';
        if (key != '') {
            customerAddList = [
                SELECT
                Id,
                name,
                Default_Billing_Address__c,
                Default_Shipping_Address__c,
                varcpq__Full_Address__c,varcpq__City__c, varcpq__Additional_Street__c, varcpq__State__c, varcpq__Street__c, varcpq__Zipcode__c, Country__c
                FROM varcpq__customer_address__c
                WHERE
                varcpq__Customer__c = :quote.AccountId
                AND varcpq__Active__c = TRUE
                AND (Name LIKE :key OR varcpq__City__c LIKE :key OR varcpq__State__c LIKE :key OR
                   varcpq__Street__c LIKE :key OR Country__c LIKE :key OR varcpq__Additional_Street__c LIKE :key
                   OR varcpq__Zipcode__c LIKE :key)
                ORDER BY Is_Default__c DESC
                
            ];
            for (varcpq__customer_address__c add : customerAddList) {
                conAddWrapper addWrap = new conAddWrapper();
                addWrap.recId = add.Id;
                addWrap.Name = add.Name;
                addWrap.email = '';
                addWrap.fullAddress = add.varcpq__Full_Address__c;
                if (String.isBlank(quote.Bill_Customer_Address_Id__c)) {
                    addWrap.DefaultBill = add.Default_Billing_Address__c;
                    addWrap.DefaultShip = add.Default_Shipping_Address__c;
                } else if (String.isBlank(quote.Ship_Customer_Address_Id__c)) {
                    addWrap.DefaultBill = add.Default_Billing_Address__c;
                    addWrap.DefaultShip = add.Default_Shipping_Address__c;
                } else if (
                    quote.Bill_Customer_Address_Id__c == quote.Ship_Customer_Address_Id__c && add.Id == quote.Bill_Customer_Address_Id__c
                ) {
                    addWrap.DefaultBill = true;
                    addWrap.DefaultShip = true;
                } else if (quote.Bill_Customer_Address_Id__c == add.Id) {
                    addWrap.DefaultBill = true;
                    addWrap.DefaultShip = false;
                } else if (quote.Ship_Customer_Address_Id__c == add.Id) {
                    addWrap.DefaultShip = true;
                    addWrap.DefaultBill = false;
                } else {
                    addWrap.DefaultBill = false;
                    addWrap.DefaultShip = false;
                }
                
                addWrapList.add(addWrap);
                
            }
            System.debug('Wrapper Add '+addWrapList);
        } else {
            customerAddList = [
                SELECT Id, name, varcpq__Full_Address__c
                FROM varcpq__customer_address__c
                WHERE
                varcpq__Customer__c = :quote.AccountId
                AND varcpq__Active__c = TRUE
                ORDER BY Is_Default__c DESC
                
            ];
            for (varcpq__customer_address__c add : customerAddList) {
                conAddWrapper addWrap = new conAddWrapper();
                addWrap.recId = add.Id;
                addWrap.Name = add.Name;
                addWrap.email = '';
                addWrap.fullAddress = add.varcpq__Full_Address__c;
                addWrap.DefaultBill = add.Default_Billing_Address__c;
                addWrap.DefaultShip = add.Default_Shipping_Address__c;
                addWrapList.add(addWrap);
                System.debug('In if');
            }
        }
        if (!addWrapList.isEmpty()) {
            return addWrapList;
        }
        return null;
    }
    
    @AuraEnabled
    public static varcpq__Partial_Invoice_Setting__c getPartialInvoiceSett() {
        varcpq__Partial_Invoice_Setting__c pis = [
            SELECT Id, Name, varcpq__Allow_Partial_Invoice__c
            FROM varcpq__Partial_Invoice_Setting__c
            LIMIT 1
        ];
        if (pis.id != null) {
            return pis;
        }
        return null;
    }
    @AuraEnabled
    public static List<RenewalWrapper> getRenewalProduct(Id quoteId) {
        Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quoteId];
        List<OpportunityLineItem> opliList = [
            SELECT Id, Product2Id, Product2.name, product2.description
            FROM OpportunityLineItem
            WHERE opportunityId = :quote.OpportunityId
        ];
        List<RenewalWrapper> renWrapList = new List<RenewalWrapper>();
        for (OpportunityLineItem opli : opliList) {
            RenewalWrapper rw = new RenewalWrapper();
            rw.prodId = opli.Product2Id;
            rw.partNumber = opli.Product2.Name;
            rw.description = opli.Product2.Description;
            rw.trackRenewal = 'false';
            rw.startDate = System.today();
            rw.endDate = System.today().addYears(1);
            renWrapList.add(rw);
        }
        return renWrapList;
    }
    
    @AuraEnabled
    public static fileWrapper getQuoteFiles(Id quoteId) {
        fileWrapper filewrap = new fileWrapper();
        Quote quote = [
            SELECT Id, Sales_Order_Default_Files__c
            FROM Quote
            WHERE Id = :quoteId
        ];
        String fileString = quote.Sales_Order_Default_Files__c;
        List<contentDocumentLink> contentDL = [
            SELECT Id, contentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :quoteId
        ];
        List<ContentDocument> files = new List<ContentDocument>();
        set<id> cdIds = new Set<id>();
        for (contentDocumentLink cdl : contentDL) {
            cdIds.add(cdl.ContentDocumentId);
        }
        files = [
            SELECT Id, Title, Description, FileType, parentId
            FROM ContentDocument
            WHERE Id = :cdIds
        ];
        fileWrap.files = files; // Get all the files
        List<String> fileNames = new List<String>();
        if (fileString != null) {
            fileNames = fileString.split(';', 0);
        }
        fileWrap.defaultFiles = fileNames;
        if (!files.isEmpty()) {
            return fileWrap;
        }
        return null;
    }
    
    @AuraEnabled
    public static varcpq__sales_order__c insertSO(Id quoteId) {
        varcpq__sales_order__c newSO = new varcpq__sales_order__c();
        List<varcpq__sales_order__c> existingSO = [SELECT Id from varcpq__sales_order__c WHERE Quote__c=:quoteId AND varcpq__Stage__c = 'Send Sales Order to Customer' AND Order_Completed__c = false LIMIT 1];
        if(!existingSO.isEmpty()){
            return existingSO[0];
        }
        
        Quote quote = [
            SELECT
            id,
            name,
            accountId,
            opportunityId,
            Customer_PO__c,
            ContractId,
            Shipping_Method__c,
            varcpq__Estimated_Taxes__c,
            AVA_SFCLOUD__ShippingHandling_Tax__c,
            Additional_Ship_To_Header__c,
            ShippingHandling,
            Quote_Net_Terms__c,
            Tax_Rate_GST__c,
            Tax_Rate_PST__c,
            Tax_Rate_HST__c,
            Tax_Rate_QST__c,
            Cost_Centre_Reference__c // Apexify -- Ticket 32 -- Px - Cost Centre Reference Support Missing in Salesforce (Available in VARCOM)
            FROM quote
            WHERE id = :quoteId
        ];
        Opportunity opp = [
            SELECT
            Id,
            AccountId,
            Name,
            Amount,
            Type,
            ContactId,
            ContractId,
            varcpq__Billing_Contact__c,
            varcpq__IsSOCreated__c,
            varcpq__Margin__c,
            varcpq__Notes__c,
            varcpq__Sync_Shipping__c,
            varcpq__Remaining_to_Invoice__c,
            varcpq__Total__c,
            varcpq__Opportunity_Contact_IsPrimary__c
            FROM Opportunity
            WHERE Id = :quote.OpportunityId
        ];
        
        /*if(quote.Name.length() > 68){
            newSO.Name = quote.Name.substring(0,68) +'Sales Order';
        }else{
        	newSO.Name = quote.Name + ' Sales Order';
        }*/
        newSO.Name = quote.Name + ' Sales Order';
        newSO.varcpq__Client__c = quote.AccountId;
        newSO.varcpq__Opportunity__c = quote.OpportunityId;
        newSO.varcpq__Amount__c = opp.Amount;
        newSO.varcpq__Total__c = opp.varcpq__Total__c;
        newSO.varcpq__Billing_Contact__c = opp.varcpq__Billing_Contact__c;
        newSO.varcpq__Open_Closed__c = 'Open';
        newSO.varcpq__Customer_PO__c = '';
        newSO.Contract__c = quote.ContractId;
        newSO.varcpq__Notes__c = '';
        newSO.varcpq__Shipping_and_Handling__c = opp.varcpq__Sync_Shipping__c;
        newSO.Shipping_and_Handling_Tax__c = quote.AVA_SFCLOUD__ShippingHandling_Tax__c;
        newSO.Shipping_Method__c = quote.Shipping_Method__c;
        newSO.Additional_Ship_To_Header__c = quote.Additional_Ship_To_Header__c;
        newSO.Quote__c = quote.id;
        newSO.Taxes__c = quote.varcpq__Estimated_Taxes__c;
        newSO.SO_Net_Terms__c = quote.Quote_Net_Terms__c;
        newSO.Tax_Rate_GST__c = quote.Tax_Rate_GST__c;
        newSO.Tax_Rate_PST__c = quote.Tax_Rate_PST__c;
        newSO.Tax_Rate_HST__c = quote.Tax_Rate_HST__c;
        newSO.Tax_Rate_QST__c = quote.Tax_Rate_QST__c;
        newSO.varcpq__Shipping_and_Handling__c = quote.ShippingHandling;
        newSO.Additional_Ship_To_Header__c = quote.Additional_Ship_To_Header__c;
        newSO.Cost_Centre_Reference__c = quote.Cost_Centre_Reference__c; // Apexify -- Ticket 32 -- Px - Cost Centre Reference Support Missing in Salesforce (Available in VARCOM)

        try {
            insert newSO;
            if (newSO.Id != null || newSO.Id != '') {
                opp.varcpq__IsSOCreated__c = true;
                update opp;
            }
            Contract cntr = new Contract();
            cntr.AccountId = newSO.varcpq__Client__c;
            cntr.varcpq__Sales_Order__c = newSO.Id;
            cntr.StartDate = System.Today();
            insert cntr;
            return newSO;
        } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex)); // Apexify -- Added by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        }
        
       // return null; // Apexify -- Commented by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
    }
    
    @AuraEnabled
    public static varcpq__sales_order__c createSalesOrder(
        String soResp,
        List<RenewalWrapper> renewalProd
    ) {
        System.debug('soResp ' + soResp);
        soResponse soWrap = (soResponse) System.JSON.deserialize(
            soResp,
            soResponse.class
        );
        
        System.debug('Sales Order Wrapper ' + soWrap);
        System.debug('Renewal Wraper ' + renewalProd);
        SalesConAddWrapper shippingAddress = getConAddForSO(
            soWrap.shipAddId,
            'address'
        );
        SalesConAddWrapper billingAddress = getConAddForSO(
            soWrap.billAddId,
            'address'
        );
        SalesConAddWrapper shippingContact = getConAddForSO(
            soWrap.shipConId,
            'contact'
        );
        SalesConAddWrapper billingContact = getConAddForSO(
            soWrap.billConId,
            'contact'
        );
        varcpq__sales_order__c theSO = [
            SELECT Id, Name, varcpq__Opportunity__c
            FROM varcpq__sales_order__c
            WHERE Id = :soWrap.soId
        ];
        varcpq__sales_order__c newSO = new varcpq__sales_order__c();
        newSO.Id = soWrap.soId;
        newSO.varcpq__Shipping_Address__c = soWrap.shipAddId;
        newSO.varcpq__Shipping_Contact__c = soWrap.shipConId;
        newSO.varcpq__Billing_Address__c = soWrap.billAddId;
        newSO.varcpq__Billing_Contact__c = soWrap.billConId;
        newSO.varcpq__Customer_PO__c = soWrap.customerPONum;
        newSO.Order_Type__c = soWrap.typeOfOrder;
        // Build customer-facing notes for Sales Order PDF
        String customerNotes = '';
        if (!String.isBlank(soWrap.customerFacingShippingNote)) {
            customerNotes +=
                'Shipping Note: ' +
                soWrap.customerFacingShippingNote +
                '\n\n';
        }
        if (!String.isBlank(soWrap.customerFacingBillingNote)) {
            customerNotes +=
                'Billing Note: ' +
                soWrap.customerFacingBillingNote +
                '\n\n';
        }
        /*newSO.varcpq__Notes__c = !String.isBlank(customerNotes)
            ? customerNotes.trim()
            : soWrap.supplierPONotes;*/
        
        //add shipping address
        if (shippingAddress != null) {
            newSO.varcpq__Shipping_Street__c = shippingAddress.street;
            newSO.varcpq__Shipping_City__c = shippingAddress.city;
            newSO.varcpq__Shipping_State__c = shippingAddress.state;
            newSO.Shipping_Country__c = shippingAddress.country;
            newSO.varcpq__Shipping_Zip__c = shippingAddress.zip;
            newSO.Shipping_Company__c = shippingAddress.companyName;
        }
        //add billing address
        if (billingAddress != null) {
            newSO.varcpq__Billing_Street__c = billingAddress.street;
            newSO.varcpq__Billing_City__c = billingAddress.city;
            newSO.varcpq__Billing_State__c = billingAddress.state;
            newSO.Billing_Country__c = billingAddress.country;
            newSO.varcpq__Billing_Zip__c = billingAddress.zip;
            newSO.Billing_Company__c = billingAddress.companyName;
        }
        //add shipping contact
        if (shippingContact != null) {
            newSO.shipping_contact_name__c = shippingContact.name;
            newSO.Shipping_Email__c = shippingContact.email;
            newSO.Shipping_Phone__c = shippingContact.phone;
        }
        //add billing contact
        if (billingContact != null) {
            newSO.Billing_contact_name__c = billingContact.name;
            newSO.Billing_Email__c = billingContact.email;
            newSO.Billing_Phone__c = billingContact.phone;
        }
        varcpq__Partial_Invoice_Setting__c pis = getPartialInvoiceSett();
        if (pis != null) {
            newSO.varcpq__Allowed_Partial_Invoices__c = pis.varcpq__Allow_Partial_Invoice__c;
        }
	// Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try {
        update newSO;
         } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        
        Contract cntr = [
            SELECT Id, StartDate, EndDate, Status, ContractTerm
            FROM Contract
            WHERE varcpq__Sales_order__c = :newSO.Id
        ];
        cntr.Status = 'Activated';
        cntr.EndDate = cntr.StartDate.addYears(1); //Added one year
        // Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try {
        update cntr;
         } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        Contact shipContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id = :newSO.varcpq__Shipping_Contact__c
        ];
        Contact billContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id = :newSO.varcpq__Billing_Contact__c
        ];
        List<varcpq__Order_Contact_Role__c> ocrList = new List<varcpq__Order_Contact_Role__c>();
        
        varcpq__Order_Contact_Role__c ocrShip = new varcpq__Order_Contact_Role__c();
        ocrShip.varcpq__Sales_Order__c = newSO.Id;
        ocrShip.varcpq__Role__c = 'Shipping Contact';
        ocrShip.varcpq__Contact__c = newSO.varcpq__Shipping_Contact__c;
        ocrShip.Name = shipContact.Name;
        
        ocrList.add(ocrShip);
        
        varcpq__Order_Contact_Role__c ocrBill = new varcpq__Order_Contact_Role__c();
        ocrBill.varcpq__Sales_Order__c = newSO.Id;
        ocrBill.varcpq__Role__c = 'Billing Contact';
        ocrBill.varcpq__Contact__c = newSO.varcpq__Billing_Contact__c;
        ocrBill.Name = billContact.Name;
        
        ocrList.add(ocrBill);
	// Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try {
        insert ocrList;
        } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        
        Opportunity opp = [
            SELECT Id, Name, SyncedQuoteId
            FROM Opportunity
            WHERE Id = :theSO.varcpq__Opportunity__c
        ];
        List<OpportunityLineItem> opliList = [
            SELECT
            Id,
            OpportunityId,
            Opportunity.accountId,
            Product2.varcpq__Distributor_account__c,
            Product2.varcpq__Distributor_account__r.name,
            Product2.Name,
            Product2.varcpq__Manufacturer__r.name,
            Product2Id,
            ProductCode,
            Name,
            Quantity,
            Discount,
            Subtotal,
            TotalPrice,
            UnitPrice,
            ListPrice,
            varcpq__Product_Name__c,
            varcpq__Cost_Price__c,
            varcpq__DH_Line__c,
            varcpq__Distributor_Name__c,
            varcpq__Unit_Cost__c,
            varcpq__Manufacturer__c,
            Description,
            Quote_Group_Id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];
        
        //Create sales order group
        Set<Id> QtGroup = new Set<Id>();
        List<Sales_Order_Group__c> SOGroupList = new List<Sales_Order_Group__c>();
        for(opportunityLineItem opli : opliList){
            QtGroup.add(opli.Quote_Group_Id__c);
        }
        List<varcpq__DH_Quote_Group__c> QuoteGroupList = [SELECT Id, Name,varcpq__DH_Quote__c, varcpq__DH_Margin_Sub_Total__c, varcpq__DH_Sequence__c, varcpq__DH_Sub_Total__c 
                                                          FROM varcpq__DH_Quote_Group__c WHERE Id=:QtGroup];
        for(varcpq__DH_Quote_Group__c grp : QuoteGroupList){
            Sales_Order_Group__c sogrp = new Sales_Order_Group__c();
            sogrp.Name = grp.Name;
            sogrp.Sales_Order__c = newSO.Id;
            sogrp.Margin_Sub_Total__c = grp.varcpq__DH_Margin_Sub_Total__c;
            sogrp.Sequence__c = grp.varcpq__DH_Sequence__c;
            sogrp.Sub_Total__c = grp.varcpq__DH_Sub_Total__c;
            sogrp.Quote_Group_Id__c = Id.valueof(grp.Id);
            SOGroupList.add(sogrp);
        }
	// Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try {
        Insert SOGroupList;
        } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        
        Map<String,Id> groupsMap = new Map<String,Id>();
        for(Sales_Order_Group__c sogrp : SOGroupList){
            groupsMap.put(sogrp.Quote_Group_Id__c,sogrp.Id);
        }
        
        Map<id, RenewalWrapper> renWrap = new Map<Id, RenewalWrapper>();
        for (RenewalWrapper ren : renewalProd) {
            renWrap.put(ren.prodId, ren);
        }
        List<Asset> assList = new List<Asset>();
        List<varcpq__Sales_order_Line_Item__c> soliList = new List<varcpq__Sales_order_Line_Item__c>();
        Double conFee = 0;
        for (opportunityLineItem opli : opliList) {
            Asset newAss = new Asset();
            newAss.AccountId = opli.Opportunity.AccountId;
            newAss.Product2Id = opli.Product2Id;
            newAss.Name = opli.Product2.Name;
            newAss.Quantity = opli.Quantity;
            newAss.varcpq__Active__c = true;
            newAss.varcpq__Contract__c = cntr.Id;
            newAss.varcpq__DH_Line__c = opli.varcpq__DH_Line__c;
            newAss.varcpq__Distributor_Name__c = opli.Product2.varcpq__Distributor_account__r.name;
            newAss.varcpq__End_Date__c = renWrap.get(opli.Product2Id).endDate;
            newAss.varcpq__Manufacturer__c = opli.Product2.varcpq__Manufacturer__r.name;
            newAss.varcpq__Notes__c = opli.Description;
            newAss.varcpq__Remaining_To_Purchage__c = opli.Quantity;
            newAss.varcpq__Sales_Order__c = newSO.Id;
            newAss.varcpq__Start_Date__c = renWrap.get(opli.Product2Id).startDate;
            newAss.varcpq__Total_Cost__c = opli.TotalPrice;
            newAss.varcpq__Unit_Cost__c = opli.varcpq__Unit_Cost__c;
            newAss.varcpq__Unit_Price__c = opli.UnitPrice;
            assList.add(newAss);
            
            varcpq__Sales_Order_Line_item__c soli = new varcpq__Sales_Order_Line_item__c();
            
            soli.varcpq__Contract_Fee__c = conFee;
            soli.varcpq__Account__c = opli.opportunity.accountid;
            soli.varcpq__Sales_Order__c = newSO.Id;
            soli.varcpq__Line__c = opli.varcpq__DH_Line__c;
            soli.varcpq__List_Price__c = opli.ListPrice;
            soli.varcpq__Product__c = opli.Product2Id;
            Boolean trckRenew;
            if (renWrap.get(opli.Product2Id).trackRenewal == 'false') {
                trckRenew = false;
            } else {
                trckRenew = true;
            }
            soli.varcpq__Renewal__c = trckRenew;
            soli.varcpq__Quantity__c = opli.Quantity;
            soli.varcpq__Shipping_Contact__c = newSO.varcpq__Shipping_Contact__c;
            soli.varcpq__Status__c = 'New';
            soli.varcpq__Unit_Cost__c = opli.varcpq__Unit_Cost__c;
            soli.varcpq__Unit_Price__c = opli.UnitPrice;
            soli.varcpq__Ship_to_Address__c = newSO.varcpq__Shipping_Address__c;
            soli.varcpq__Distributor__c = opli.Product2.varcpq__Distributor_account__c;
            soli.Sales_Order_Group__c = groupsMap.get(opli.Quote_Group_Id__c);
            soliList.add(soli);
        }
        // Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try{

        insert assList;
        insert soliList;

        } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        
        Map<Id, Id> assetMap = new Map<Id, Id>();
        for (Asset ass : assList) {
            assetMap.put(ass.Product2Id, ass.Id);
        }
        
        for (varcpq__Sales_Order_Line_item__c soli : soliList) {
            soli.varcpq__Asset__c = assetMap.get(soli.varcpq__Product__c);
        }
	// Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try{

        update soliList;

        } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        
        List<ContentVersion> contentverList = [
            SELECT
            Id,
            ContentDocumentId,
            VersionNumber,
            ContentLocation,
            PathOnClient,
            Title,
            SharingOption,
            SharingPrivacy,
            VersionData,
            FileType,
            File_category__c
            FROM ContentVersion
            WHERE ContentDocumentId = :soWrap.files
        ];
        
        List<ContentVersion> newCntVers = new List<ContentVersion>();
        if (!contentverList.isEmpty()) {
            for (contentversion cntv : contentverList) {
                contentversion newcv = new contentversion();
                newcv.ContentLocation = cntv.ContentLocation;
                newcv.VersionData = cntv.versiondata;
                newcv.PathOnClient = cntv.PathOnClient;
                newcv.Title = cntv.Title;
                newcv.File_Category__c = cntv.File_Category__c;
                newCntVers.add(newcv);
            }
        }
        if (!newCntVers.isEmpty()) {
            insert newCntVers;
        }
        List<ContentVersion> contentvernewList = [
            SELECT
            Id,
            ContentDocumentId,
            VersionNumber,
            ContentLocation,
            PathOnClient,
            Title,
            SharingOption,
            SharingPrivacy,
            VersionData,
            FileType
            FROM ContentVersion
            WHERE Id IN :newCntVers
        ];
        Set<id> contDocIds = new Set<id>();
        for (contentversion cntver : contentvernewList) {
            contDocIds.add(cntver.ContentDocumentId);
        }
        List<ContentDocument> docs = new List<ContentDocument>();
        if (!contDocIds.isEmpty()) {
            docs = [
                SELECT
                Id,
                Title,
                ParentId,
                FileType,
                FileExtension,
                SharingOption,
                SharingPrivacy,
                ContentAssetId
                FROM ContentDocument
                WHERE Id = :contDocIds
            ];
        }
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (Contentdocument doc : docs) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = doc.Id;
            cdl.LinkedEntityId = newSO.Id;
            cdl.ShareType = 'v';
            cdlList.add(cdl);
        }
        if (!cdlList.isEmpty()) {
            insert cdlList;
        }
        Map<String,String> supplierNotes = soWrap.supplierPONotes;
        if (
            !String.isBlank(soWrap.customerFacingShippingNote) ||
            !String.isBlank(soWrap.customerFacingBillingNote) ||
            !String.isBlank(soWrap.internalShippingNote) ||
            !String.isBlank(soWrap.internalBillingNote)|| !supplierNotes.isEmpty()
        ) {
            
            // Prepare the Body for Shipping and Billing Notes
            String Body = '';
            
            // Concatenate non-empty notes
            List<Custom_Note__c> notesToInsert = new List<Custom_Note__c>();

            if (!String.isBlank(soWrap.customerFacingShippingNote)) {
                notesToInsert.add(new Custom_Note__c(
                    Note_Type__c = 'Customer Facing - Shipping', 
                    Compose_Text__c = soWrap.customerFacingShippingNote,
                    Sales_Order__c = newSO.Id
                ));
            }

            if (!String.isBlank(soWrap.customerFacingBillingNote)) {
                notesToInsert.add(new Custom_Note__c(
                    Note_Type__c = 'Customer Facing - Billing',
                    Compose_Text__c = soWrap.customerFacingBillingNote,
                    Sales_Order__c = newSO.Id
                ));
            }

            if (!String.isBlank(soWrap.internalShippingNote)) {
                notesToInsert.add(new Custom_Note__c(
                    Note_Type__c = 'Internal - Shipping',
                    Compose_Text__c = soWrap.internalShippingNote,
                    Sales_Order__c = newSO.Id
                ));
            }

            if (!String.isBlank(soWrap.internalBillingNote)) {
                notesToInsert.add(new Custom_Note__c(
                    Note_Type__c = 'Internal - Billing',
                    Compose_Text__c = soWrap.internalBillingNote,
                    Sales_Order__c = newSO.Id
                ));
            }
            
            
            if(!supplierNotes.isEmpty()){
                for(String suppId : supplierNotes.keySet()){
                    notesToInsert.add(new Custom_Note__c(
                        Note_Type__c = 'Supplier',
                        Supplier__c = suppId,
                        Compose_Text__c = supplierNotes.get(suppId),
                        Sales_Order__c = newSO.Id
                    ));
                }
            }
            
			/*List<suppnote> supplierNotes = soWrap.supplierPONotes;         
            if (!supplierNotes.isEmpty()) {
                for(suppnote sn: supplierNotes){
                    notesToInsert.add(new Custom_Note__c(
                        Note_Type__c = 'Supplier',
                        Supplier__c = sn.supplierId,
                        Compose_Text__c = sn.note,
                        Sales_Order__c = newSO.Id
                    ));
                }
            }*/
			System.debug('Notess added '+notesToInsert);
            if (!notesToInsert.isEmpty()) {
                try {
                    insert notesToInsert;
	
               } catch (Exception e) {
                    System.debug('Error inserting custom notes: ' + e.getMessage());
                }
            }

        }
        
        Quote qt = [SELECT Id, Status FROM Quote WHERE id = :opp.SyncedQuoteId];
        qt.Status = 'Sales Order Created';
	// Apexify -- Added try catch block by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
        try {
       update qt;
       
         } catch (exception ex) {
            System.debug('exception ' + ex);
            throw new AuraHandledException(getUserErrorMessage(ex));
        }
        return newSO;
    }
    
    @AuraEnabled
    public static boolean deleteSO(Id soId) {
        varcpq__Sales_Order__c so = new varcpq__Sales_order__c();
        if (soId != null || soId != '') {
            so.Id = soId;
            try {
                delete so;
                return true;
            } catch (exception ex) {
                system.debug(ex);
                return false;
            }
        }
        return false;
    }
    
    @AuraEnabled
    public static Quote getQuoteInfo(Id quoteId) {
        Quote quote = [
            SELECT
            ID,
            Name,
            BillingName,
            ShippingName,
            Bill_Customer_Address_Id__c,
            Ship_Customer_Address_Id__c,
            Quote_Net_Terms__c,
            GrandTotal,Additional_Ship_To_Header__c,
            TotalPrice
            FROM Quote
            WHERE Id = :quoteId
        ];
        return quote;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getNetTerms() {
        List<String> netTermOpt = new List<String>();
        Schema.DescribeFieldResult fieldResult = Quote.Quote_Net_Terms__c.getDescribe();
        List<PicklistEntry> pleList = fieldResult.getPickListValues();
        for (PicklistEntry ple : pleList) {
            netTermOpt.add(ple.getValue());
        }
        return netTermOpt;
    }
    
    private static SalesConAddWrapper getConAddForSO(Id recId, String entity) {
        SalesConAddWrapper wrap = new SalesConAddWrapper();
        if (entity == 'contact') {
            Contact con = [
                SELECT Id, Name, Email, Phone
                FROM Contact
                WHERE Id = :recId
            ];
            wrap.name = con.Name;
            wrap.email = con.Email;
            wrap.phone = con.Phone;
        } else if (entity == 'address') {
            varcpq__customer_address__c add = [
                SELECT
                Id,
                Name,
                varcpq__City__c,
                varcpq__State__c,
                varcpq__Street__c,
                varcpq__Zipcode__c,
                Country__c,
                Company_Name__c
                FROM varcpq__Customer_Address__c
                WHERE Id = :recId
            ];
            wrap.street = add.varcpq__Street__c;
            wrap.state = add.varcpq__State__c;
            wrap.city = add.varcpq__City__c;
            wrap.country = add.Country__c;
            wrap.zip = add.varcpq__Zipcode__c;
            wrap.companyName = add.Company_Name__c;
        }
        return wrap;
    }
    
    @AuraEnabled
    public static void savePOFile(Id quoteId,String fileId, String versionId){
        Quote quote = [SELECT Id,Default_PO_File__c FROM Quote WHERE Id=:quoteId];
        if(!String.isBlank(quote.Default_PO_File__c)){
            quote.Default_PO_File__c += fileId+';';
        }else{
            quote.Default_PO_File__c = fileId+';';
        }
        update quote;
        
        ContentVersion cv = new ContentVersion();
        cv.Id = versionId;
        cv.File_Category__c = 'Customer Purchase Order';
        update cv;
        
        ContentDocument cd = [SELECT Id,Title FROM ContentDocument WHERE Id=: fileId];
        cd.Title = 'CustomerPO_'+cd.Title;
        update cd;
    }
    
    @AuraEnabled
    public static List<ContentDocument> getPOFiles(Id quoteId){
        Quote quote = [SELECT Id,Default_PO_File__c FROM Quote WHERE Id=:quoteId];
        String fileString = quote.Default_PO_File__c;
        List<String> poFiles = new List<String>();
        List<ContentDocument> poDocs = new List<ContentDocument>();
        if (!String.isBlank(fileString)) {
            poFiles = fileString.split(';', 0);
        }
        if(!poFiles.isEmpty()){
            poDocs = [SELECT Id, Title, Description, FileType, parentId
                      FROM ContentDocument
                      WHERE Id = :poFiles];
        }
        // Apexify -- Work-Item 56 -- Surya -- Start -- Added below else condition to fetch the Customer PO Files from Quote
        else{
            
            Set<Id> docIds = new Set<Id>();
            
            // Query 1: All linked ContentDocument IDs
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :quoteId
            ]) {
                docIds.add(cdl.ContentDocumentId);
            }
            
          if (!docIds.isEmpty()) {
                // Query 2: Filter ContentVersions 
                for (ContentVersion cv : [
                    SELECT ContentDocument.Id,
                    ContentDocument.Title,
                    ContentDocument.Description,
                    ContentDocument.FileType,
                    ContentDocument.ParentId
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds
                    AND File_Category__c = 'Customer Purchase Order'
                    
                ]) {
                    poDocs.add(cv.ContentDocument);
                }
                
            }
          
        }
        // Apexify -- Work-Item 56 -- Surya -- End
        return poDocs;
    }
    // Apexify -- Added below method by SURYA on 18/11/2025 as part of Ticket 37 - Px - Sales Order Creation Fails Due to Non-Descriptive Errors and Decimal Value Mismatch Between UI and Backend
    public static String getUserErrorMessage(Exception ex) {

    String rawMessage = '';
    if(String.isNotBlank(ex.getMessage())){
        rawMessage = ex.getMessage();
    }

    // Query all error handling CMDT records
    List<Error_Handling_Message__mdt> mappings = [
        SELECT Exception_Type__c, User_Message__c
        FROM Error_Handling_Message__mdt
    ];

    // Loop through CMDT records and find matching rule
    for (Error_Handling_Message__mdt rule : mappings) {
        if (!String.isBlank(rule.Exception_Type__c) &&
            rawMessage.contains(rule.Exception_Type__c) && !String.isBlank(rule.User_Message__c)) {
            return rule.User_Message__c;
        }
    }

    // Fallback: return original message if no mapping found
    return 'Failed to create Sales Order';
}
    
    public class SalesConAddWrapper {
        public String name;
        public String email;
        public String phone;
        public String street;
        public String city;
        public String state;
        public String country;
        public String zip;
        public String companyName;
    }
    public class soResponse {
        @AuraEnabled
        public String soId;
        @AuraEnabled
        public String shipConId;
        @AuraEnabled
        public String shipAddId;
        @AuraEnabled
        public String customerFacingShippingNote;
        @AuraEnabled
        public String internalShippingNote;
        @AuraEnabled
        public String billConId;
        @AuraEnabled
        public String billAddId;
        @AuraEnabled
        public String customerFacingBillingNote;
        @AuraEnabled
        public String internalBillingNote;
        @AuraEnabled
        public String customerPONum;
       /* @AuraEnabled
        public String supplierPONotes;*/
        @AuraEnabled
        public Map<String,String> supplierPONotes;
        @AuraEnabled 
        public string typeOfOrder;
        @AuraEnabled
        public List<String> files;
    }
    
    public class conAddWrapper {
        @AuraEnabled
        public String recId;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public Boolean DefaultShip;
        @AuraEnabled
        public Boolean DefaultBill;
        @AuraEnabled
        public String fullAddress;
    }
    
    public class RenewalWrapper {
        @AuraEnabled
        public String prodId { get; set; }
        @AuraEnabled
        public String partNumber { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String trackRenewal { get; set; }
        @AuraEnabled
        public Date startDate { get; set; }
        @AuraEnabled
        public Date endDate { get; set; }
    }
    public class fileWrapper {
        @AuraEnabled
        public List<ContentDocument> files;
        @AuraEnabled
        public List<String> defaultFiles;
    }
    public class suppnote{
        @AuraEnabled
        public String supplierId;
       	@AuraEnabled
        public String note;
       
    }
}