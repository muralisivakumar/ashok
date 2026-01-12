public virtual class BasePDFController {
    public Id recordId;
    public String objectApiName;
    public Date today { get; private set; }
    
    public class PDFException extends Exception {
    }
    
    public class CompanyInfo {
        public String name { get; private set; }
        public String street { get; private set; }
        public String suite { get; private set; }
        public String cityStateZip { get; private set; }
        public String phone { get; private set; }
        public String website { get; private set; }
        public String operationsReplyToEmail { get; private set; }
        public String accountingReplyToEmail { get; private set; }
        public String invoiceReplyToEmail { get; private set; }
        public String remitToName { get; private set; }
        public String remitToAttnTo { get; private set; }
        public String remitToAddress1 {get; private set; }
        public String remitToAddress2 {get; private set; }
        public String remitToCityStateZip {get; private set; }
        public String remitToPhone {get; private set; }
    }
    
    @testVisible
    protected // Add new method for orientation
        String getPageOrientation() {
            String orientation = 'portrait'; // default
            try {
                List<PDF_Document_Configuration__mdt> configs = [
                    SELECT Page_Orientation__c
                    FROM PDF_Document_Configuration__mdt
                    WHERE Object_API_Name__c = :objectApiName
                    LIMIT 1
                ];
                if (!configs.isEmpty() && configs[0].Page_Orientation__c != null) {
                    orientation = configs[0].Page_Orientation__c.toLowerCase();
                }
            } catch (Exception e) {
                // If field doesn't exist yet or other error, default to portrait
                System.debug(
                    LoggingLevel.ERROR,
                    'Error getting orientation: ' + e.getMessage()
                );
            }
            return orientation;
        }
    
    public static CompanyInfo getCompanyInfo(String recordType) {
        PDF_Company_Information__mdt info = [
            SELECT
            Company_Name__c,
            Street__c,
            Suite__c,
            City_State_Zip__c,
            Phone__c,
            Website__c,
            Accounting_Reply_To_Email_Address__c,
            Operations_Reply_To_Email_Address__c,
            Invoice_Reply_To_Email_Address__c,
            Remit_To_Name__c, 
            Remit_To_Attn_To__c, 
            Remit_To_Address_1__c, 
            Remit_To_Address_2__c, 
            Remit_To_City_State_Zip__c,
            Remit_To_Phone__c
            FROM PDF_Company_Information__mdt
            WHERE Record_Type__c = :recordType
            LIMIT 1
        ];
        
        CompanyInfo result = new CompanyInfo();
        result.name = info.Company_Name__c;
        result.street = info.Street__c;
        result.suite = info.Suite__c;
        result.cityStateZip = info.City_State_Zip__c;
        result.phone = info.Phone__c;
        result.website = info.Website__c;
        result.accountingReplyToEmail = info.Accounting_Reply_To_Email_Address__c;
        result.operationsReplyToEmail = info.Operations_Reply_To_Email_Address__c;
        result.invoiceReplyToEmail = info.Invoice_Reply_To_Email_Address__c;
        result.remitToName = info.Remit_To_Name__c;
        result.remitToAttnTo = info.Remit_To_Attn_To__c;
        result.remitToAddress1 = info.Remit_To_Address_1__c;
        result.remitToAddress2 = info.Remit_To_Address_2__c;
        result.remitToCityStateZip = info.Remit_To_City_State_Zip__c;
        result.remitToPhone = info.Remit_To_Phone__c;
        return result;
    }
    
    public BasePDFController() {
        this.recordId = ApexPages.currentPage().getParameters().get('id');
        if (recordId != null) {
            this.objectApiName = recordId.getSObjectType().getDescribe().getName();
        }
        this.today = System.today();
    }
    
    @testVisible
    protected virtual void loadData() {
        // To be implemented by child classes
    }
    
    @testVisible
    private static PDF_Document_Configuration__mdt validateAndGetConfiguration(
        String objectApiName
    ) {
        if (String.isBlank(objectApiName)) {
            throw new PDFException('Object API Name cannot be blank');
        }
        
        List<PDF_Document_Configuration__mdt> configs = [
            SELECT
            Object_API_Name__c,
            File_Name_Prefix__c,
            Record_Number_Field__c,
            Template_Page_Name__c,
            Record_Id_Parameter__c,
            Page_Orientation__c
            FROM PDF_Document_Configuration__mdt
            WHERE Object_API_Name__c = :objectApiName
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new PDFException(
                'No PDF configuration found for object: ' + objectApiName
            );
        }
        
        PDF_Document_Configuration__mdt config = configs[0];
        
        if (String.isBlank(config.Template_Page_Name__c)) {
            throw new PDFException(
                'Template Page Name is required in PDF configuration'
            );
        }
        
        if (String.isBlank(config.File_Name_Prefix__c)) {
            throw new PDFException(
                'File Name Prefix is required in PDF configuration'
            );
        }
        
        if (String.isBlank(config.Record_Number_Field__c)) {
            throw new PDFException(
                'Record Number Field is required in PDF configuration'
            );
        }
        
        if (String.isBlank(config.Record_Id_Parameter__c)) {
            throw new PDFException(
                'Record Id Parameter is required in PDF configuration'
            );
        }
        
        return config;
    }
    
    @AuraEnabled
    public static ContentVersion savePDFToRecord(Id recordId) {
        System.debug('=== Starting PDF Generation ===');
        System.debug('Input recordId: ' + recordId);
        
        try {
            if (recordId == null) {
                throw new PDFException('Record ID cannot be null');
            }
            
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            System.debug('Object API Name: ' + objectApiName);
            
            PDF_Document_Configuration__mdt config = validateAndGetConfiguration(
                objectApiName
            );
            System.debug('Configuration: ' + config);
            
            String recordNumber = getRecordNumber(recordId, config);
            System.debug('Record Number: ' + recordNumber);
            
            if (String.isBlank(recordNumber)) {
                throw new PDFException(config.Record_Number_Field__c + ' is required');
            }
            
            String todayDate = Datetime.now().format('yyyyMMdd');
            System.debug('Today Date: ' + todayDate);
            
            Integer versionNumber = getNextVersionNumber(
                recordId,
                config.File_Name_Prefix__c,
                recordNumber,
                todayDate
            );
            System.debug('Version Number: ' + versionNumber);
            
            String versionSuffix = versionNumber > 1
                ? '_v' + String.valueOf(versionNumber)
                : '';
            String fileName = String.format(
                '{0}_{1}_{2}{3}.pdf',
                new List<String>{
                    config.File_Name_Prefix__c,
                        recordNumber,
                        todayDate,
                        versionSuffix
                        }
            );
            System.debug('Generated File Name: ' + fileName);
            
            PageReference pageRef = new PageReference(
                '/apex/' + config.Template_Page_Name__c
            );
            pageRef.getParameters().put(config.Record_Id_Parameter__c, recordId);
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test Content');
            } else {
                try {
                    pdfBlob = pageRef.getContentAsPDF();
                } catch (Exception e) {
                    throw new PDFException('Error generating PDF: ' + e.getMessage());
                }
            }
            
            ContentVersion result = saveContentVersion(recordId, fileName, pdfBlob);
            System.debug(
                'PDF Generated Successfully. ContentVersion Id: ' + result.Id
            );
            return result;
        } catch (PDFException e) {
            System.debug('PDF Exception: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error in savePDFToRecord: ' + e.getMessage()
            );
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(
                'An error occurred while generating the PDF. Please contact your administrator.'
            );
        }
    }
    
    @AuraEnabled
    public static void emailPDF(
        Id recordId,
        List<String> toAddresses,
        String emailTemplateId
    ) {
        try {
            ContentVersion cv = savePDFToRecord(recordId);
            
            cv = [
                SELECT Id, Title, VersionData
                FROM ContentVersion
                WHERE Id = :cv.Id
            ];
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            
            if (String.isNotBlank(emailTemplateId)) {
                email.setTemplateId(emailTemplateId);
                
                if (Test.isRunningTest()) {
                    Contact con = new Contact(
                        LastName = 'Test',
                        email = 'testunique@test.com'
                    );
                    insert con;
                    email.setTargetObjectId(con.Id);
                } else {
                    email.setTargetObjectId(UserInfo.getUserId());
                }
                email.setWhatId(recordId);
                if (Test.isRunningTest()) {
                    email.setsaveAsActivity(false);
                }
            }
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(cv.Title);
            attachment.setBody(cv.VersionData);
            email.setFileAttachments(
                new List<Messaging.EmailFileAttachment>{ attachment }
            );
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
    
    @testVisible
    private static String getRecordNumber(
        Id recordId,
        PDF_Document_Configuration__mdt config
    ) {
        try {
            System.debug('Getting record number for Id: ' + recordId);
            System.debug('Using field: ' + config.Record_Number_Field__c);
            
            String queryString =
                'SELECT ' +
                String.escapeSingleQuotes(config.Record_Number_Field__c) +
                ' FROM ' +
                String.escapeSingleQuotes(config.Object_API_Name__c) +
                ' WHERE Id = :recordId';
            System.debug('Query: ' + queryString);
            
            SObject record = Database.query(queryString);
            System.debug('Record retrieved: ' + record);
            
            if (record == null) {
                throw new PDFException('Record not found');
            }
            
            Object fieldValue = record.get(config.Record_Number_Field__c);
            System.debug('Field Value: ' + fieldValue);
            
            if (fieldValue == null) {
                throw new PDFException(
                    'Record number field ' + config.Record_Number_Field__c + ' is empty'
                );
            }
            
            String result = String.valueOf(fieldValue);
            System.debug('Returning record number: ' + result);
            return result;
        } catch (System.QueryException e) {
            System.debug('Query Exception: ' + e.getMessage());
            throw new PDFException('Error querying record: ' + e.getMessage());
        }
    }
    
    @testvisible
    private static Integer getNextVersionNumber(
        Id recordId,
        String prefix,
        String recordNumber,
        String todayDate
    ) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title
            FROM ContentDocumentLink
            WHERE
            LinkedEntityId = :recordId
            AND ContentDocument.Title LIKE :String.format(
                '{0}_{1}_{2}%',
                new List<String>{ prefix, recordNumber, todayDate }
            )
        ];
        
        return links.size() + 1;
    }
    
    /*@testVisible
private static ContentVersion saveContentVersion(
Id recordId,
String fileName,
Blob pdfBlob
) {
String objApiName = recordId.getSObjectType().getDescribe().getName();
File_Category_Configuration__mdt fileCategory = [SELECT Id, Label, File_Prefix__c,ObjectApiName__c FROM File_Category_Configuration__mdt WHERE ObjectApiName__c =: objApiName LIMIT 1];

ContentVersion cv = new ContentVersion();
cv.Title = fileName;
cv.PathOnClient = fileName;
cv.VersionData = pdfBlob;
cv.FirstPublishLocationId = recordId;
if(fileCategory != null){
if(fileCategory.Label !='' || fileCategory.Label != null){
cv.File_Category__c = fileCategory.Label;
}
}        
insert cv;

return [SELECT Id FROM ContentVersion WHERE Id = :cv.Id];
}*/
    
    @testVisible
    private static ContentVersion saveContentVersion(
        Id recordId,
        String fileName,
        Blob pdfBlob
    ) {
        String objApiName = recordId.getSObjectType().getDescribe().getName();
        
        // Query file category configuration safely
        File_Category_Configuration__mdt fileCategory;
        List<File_Category_Configuration__mdt> configs = [
            SELECT Id, Label, File_Prefix__c, ObjectApiName__c
            FROM File_Category_Configuration__mdt
            WHERE ObjectApiName__c = :objApiName
            LIMIT 1
        ];
        if (!configs.isEmpty()) {
            fileCategory = configs[0];
        }
        
        // Create new ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = pdfBlob;
        cv.FirstPublishLocationId = recordId;
        
        if (fileCategory != null && String.isNotBlank(fileCategory.Label)) {
            cv.File_Category__c = fileCategory.Label;
        }
        
        insert cv;
        return cv;
    }
    
    
    public static String generateCSV(Id recordId, String sObjectType) {
        
        String csvContent = '';
        
        if (sObjectType == 'Quote') {
            List<QuoteLineItem> items = [
                SELECT Id, Product2.Name, Quantity, UnitPrice, varcpq__EXT_Price__c, Description,varcpq__Manufacturer__c ,varcpq__TAX__c,Quote.Tax,
                Quote.QuoteNumber, Quote.Quote_Net_Terms__c, Quote.ExpirationDate, Quote.Opportunity.Name, Quote.Customer_PO__c,Quote.Contract.Name,
                Quote.BillingAddress, Quote.ShippingAddress, Quote.Account.BillingCountry, Quote.CreatedDate, Quote.Account.Name, Quote.Account.RecordType.DeveloperName, Quote.Shipping_Method__c,
                Quote.Bill_to_email__c , Quote.Bill_to_phone__c, Quote.AccountId, Quote.BillingName, Quote.Ship_to_email__c,Quote.Ship_to_phone__c,Quote.ShippingName, Quote.Opportunity.Owner.Name, Quote.Opportunity.Owner.Email, Quote.Tax_Rate__c ,
                Quote.Tax_Rate_GST__c, Quote.Tax_Rate_HST__c, Quote.Tax_Rate_PST__c, Quote.Tax_Rate_QST__c, Quote.Tax_Amount_GST__c, Quote.Tax_Amount_HST__c, Quote.Tax_Amount_PST__c, Quote.Tax_Amount_QST__c, Quote.CurrencyIsoCode,
                Quote.AVA_SFCLOUD__ShippingHandling_Tax__c, Quote.ShippingHandling, varcpq__DH_Quote_Group__r.name
                FROM QuoteLineItem
                WHERE QuoteId = :recordId
            ];
            
            QuoteLineItem firstItem = items[0];
            Quote parentQuote = firstItem.Quote;
            
            String salesRepEmail = parentQuote.Opportunity.Owner.Email;
            String salesRepName = parentQuote.Opportunity.Owner.Name;
            
            // Quote details
            String quoteNumber = '="' + parentQuote.QuoteNumber + '"';
            String netTerms = parentQuote.Quote_Net_Terms__c;
            String quoteDate = System.now().format('M/d/yyyy');
            String expirationDate = parentQuote.ExpirationDate != null ? parentQuote.ExpirationDate.format() : '';
            String accountName = parentQuote.Account != null ? parentQuote.Account.Name : '';
            //String accId = parentQuote.AccountId;
            //String contactName = parentQuote.ContactId != null ? parentQuote.ContactId.Name : '';
            //System.debug('contactName:: ' + contactName);
            
            
            
            //company info
            String recType = parentQuote.Account.RecordType.DeveloperName;
            System.debug('recType:  ' +recType);
            String companyInfoRecType = '';
            if(recType == 'US_Account'){
                companyInfoRecType = 'US Account';
            }else{
                companyInfoRecType = 'Canadian Account';
            }
            PDF_Company_Information__mdt companyInfo  = [SELECT Company_Name__c, Street__c, Suite__c, City_State_Zip__c, Phone__c, Website__c, Record_Type__c FROM PDF_Company_Information__mdt where Record_Type__c =:companyInfoRecType ];
            System.debug('companyInfo:: ' + companyInfo);
            String billingName = parentQuote.BillingName != null ? parentQuote.BillingName : '';
            // Add quote header details before line items
            csvContent += sanitize(companyInfo.Company_Name__c) + ',,,,,Quote Number,' + parentQuote.QuoteNumber + '\n';
            csvContent += sanitize(companyInfo.Street__c) + ',,,,,Terms,' + sanitize(netTerms) + '\n';
            csvContent += sanitize(companyInfo.Suite__c) + ',,,,,Contact,' + sanitize(billingName) + '\n';
            csvContent += sanitize(companyInfo.City_State_Zip__c) + ',,,,,Quote Date,' + sanitize(quoteDate) + '\n';
            // csvContent += 'Phone: ' + sanitize(companyInfo.Phone__c) + ',,,,,Expiration Date,' + sanitize(expirationDate) + '\n';
            csvContent += 'Phone: ' + companyInfo.Phone__c + ',,,,,Expiration Date,' + sanitize(expirationDate) + '\n';
            csvContent += sanitize(companyInfo.Website__c) + '\n\n';
            
            //Sales rep
            csvContent += ',,,,,,' + sanitize('Sales Rep: ' + salesRepName) + '\n';
            //csvContent += ',,,,,,Sales Rep:,' + sanitize(salesRepName + ' - ' + salesRepEmail) + '\n';
            csvContent += ',,,,,,' + sanitize(salesRepEmail) + '\n\n';
            
            
            // Determine region based on country
            String country = parentQuote.Account.BillingCountry;
            String logoUrl = '';
            
            if (country != null && country.toLowerCase().contains('canada')) {
                logoUrl = 'https://clutchsol--quotelysb--c.sandbox.vf.force.com/resource/LogoCa.png'; // Replace with your public URL
            } else {
                logoUrl = 'https://clutchsol--quotelysb--c.sandbox.vf.force.com/resource/LogoUS.png'; // Replace with your public URL
            }
            
            // Contact ship to and bill to
            // Add Bill To block
            // Add Bill To and Ship To blocks using formatAddress
            String billingAddress = formatAddress(parentQuote.BillingAddress);
            String shippingAddress = formatAddress(parentQuote.ShippingAddress);
            
            String shippingName = parentQuote.ShippingName != null ? parentQuote.ShippingName : '';
            String billPhone = parentQuote.Bill_to_phone__c != null ? parentQuote.Bill_to_phone__c : '';
            String billEmail = parentQuote.Bill_to_email__c != null ? parentQuote.Bill_to_email__c : '';
            String shipPhone = parentQuote.Ship_to_phone__c != null ? parentQuote.Ship_to_phone__c : '';
            String shipEmail = parentQuote.Ship_to_email__c != null ? parentQuote.Ship_to_email__c : '';
            
            csvContent += 'Customer,Bill To,Ship To\n';
            
            csvContent += sanitize(accountName) + ',' + sanitize(accountName) + ',' + sanitize(accountName) + '\n';
            
            csvContent += sanitize(billingName) + ',' + sanitize(billingName) + ',' + sanitize(shippingName) + '\n';
            
            csvContent += sanitize(billingAddress) + ',' + sanitize(billingAddress) + ',' + sanitize(shippingAddress) + '\n';
            
            // Phones row
            csvContent += '\t' + sanitize(billPhone).replace('"', '') + ',' + '\t' + sanitize(billPhone).replace('"', '') + ',' + '\t' + sanitize(shipPhone).replace('"', '') + '\n';
            
            // Emails row
            csvContent += sanitize(billEmail) + ',' + sanitize(billEmail) + ',' + sanitize(shipEmail) + '\n\n';
            
            
            String opportunityName = parentQuote.Opportunity != null ? parentQuote.Opportunity.Name : '';
            String customerPO = parentQuote.Customer_PO__c != null ? parentQuote.Customer_PO__c : '';
            String contractName = parentQuote.Contract != null ? parentQuote.Contract.Name : '';
            String shipVia = parentQuote.Shipping_Method__c  != null ? parentQuote.Shipping_Method__c  : '';
            
            // Add header label row
            csvContent += 'Description     ,Customer PO     ,Contract    ,Ship Via     \n';
            
            // Add actual values row
            csvContent += sanitize(opportunityName) + ',' +
                sanitize(customerPO) + ',' +
                sanitize(contractName) + ',' +
                sanitize(shipVia) + '\n\n';                  
            
            
            // csvContent += '#,Mfg,Mfg Part#, Qty,Description,Price,Extended Price \n';
            
            //String quoteDate = Date.Today().format();
            //System.debug('quoteDate:: ' + quoteDate);
            // Decimal subtotal = 0;
            //Decimal taxTotal = 0;
            //Integer serialNo = 1;
            // Group line items
            Map<String, List<QuoteLineItem>> groupedItems = new Map<String, List<QuoteLineItem>>();
            List<QuoteLineItem> ungroupedItems = new List<QuoteLineItem>();
            
            for (QuoteLineItem item : items) {
                if ((item.varcpq__DH_Quote_Group__c != null &&item.varcpq__DH_Quote_Group__r.Name != 'Untitled' )&& String.isNotBlank(item.varcpq__DH_Quote_Group__r.Name)) {
                    String groupName = item.varcpq__DH_Quote_Group__r.Name;
                    if (!groupedItems.containsKey(groupName)) {
                        groupedItems.put(groupName, new List<QuoteLineItem>());
                    }
                    groupedItems.get(groupName).add(item);
                } else {
                    ungroupedItems.add(item);
                }
            }
            
            // Variables
            Decimal subtotal = 0;
            Decimal taxTotal = 0;
            Integer serialNo = 1;
            // Render grouped items
            for (String groupName : groupedItems.keySet()) {
                Decimal groupSubtotal = 0;
                csvContent += '\n' + sanitize(groupName) + '\n';
                csvContent += '#,Mfg,Mfg Part#, Qty,Description,Price,Extended Price \n';
                
                for (QuoteLineItem item : groupedItems.get(groupName)) {
                    Decimal lineSubtotal = item.UnitPrice * item.Quantity;
                    Decimal lineTax = item.varcpq__TAX__c != null ? item.varcpq__TAX__c : 0;
                    
                    subtotal += lineSubtotal;
                    taxTotal = item.Quote.Tax ;
                    groupSubtotal += lineSubtotal;
                    
                    csvContent += '\t' + serialNo + ',' +  // ← Serial number with tab
                        sanitize(item.varcpq__Manufacturer__c) + ',' +
                        sanitize(item.Product2.Name) + ',' +
                        '\t' + String.valueOf(item.Quantity.intValue()) + ',' +  // Format Quantity as integer
                        sanitize(item.Description) + ',' +
                        fCurrency(item.UnitPrice, parentQuote.CurrencyIsoCode) + ',' +
                        fCurrency(item.varcpq__EXT_Price__c, parentQuote.CurrencyIsoCode) + '\n';
                    serialNo++;
                    
                }
                csvContent += ',,,,,' + groupName + ' Subtotal,' + fCurrency(groupSubtotal, parentQuote.CurrencyIsoCode) + '\n';
            }
            
            // Render ungrouped items if any
            if (!ungroupedItems.isEmpty()) {
                
                csvContent += '#,Mfg,Mfg Part#, Qty,Description,Price,Extended Price \n';
                
                for (QuoteLineItem item : ungroupedItems) {
                    Decimal lineSubtotal = item.UnitPrice * item.Quantity;
                    Decimal lineTax = item.varcpq__TAX__c != null ? item.varcpq__TAX__c : 0;
                    
                    subtotal += lineSubtotal;
                    taxTotal = item.Quote.Tax;
                    
                    csvContent += '\t' + serialNo + ',' +  // ← Serial number with tab
                        sanitize(item.varcpq__Manufacturer__c) + ',' +
                        sanitize(item.Product2.Name) + ',' +
                        '\t' + String.valueOf(item.Quantity.intValue()) + ',' +  // ← Quantity with tab
                        sanitize(item.Description) + ',' +
                        fCurrency(item.UnitPrice, parentQuote.CurrencyIsoCode) + ',' +
                        fCurrency(item.varcpq__EXT_Price__c, parentQuote.CurrencyIsoCode) + '\n';
                    serialNo++;
                }
            }
            System.debug('amountss '+subtotal +' '+taxTotal);
            
            /*  for (QuoteLineItem item : items) {
// String billingAddress = formatAddress(item.Quote.BillingAddress);
//String shippingAddress = formatAddress(item.Quote.ShippingAddress);

Decimal lineSubtotal = item.UnitPrice * item.Quantity;
Decimal lineTax = item.varcpq__TAX__c != null ? item.varcpq__TAX__c : 0;

subtotal += lineSubtotal;
taxTotal += lineTax;

csvContent += serialNo + ',' +
sanitize(item.varcpq__Manufacturer__c) + ',' +
sanitize(item.Product2.Name) + ',' +
item.Quantity + ',' +
sanitize(item.Description) + ',' +
//item.UnitPrice + ',' +
fCurrency(item.UnitPrice, parentQuote.CurrencyIsoCode) + ',' +
fCurrency(item.varcpq__EXT_Price__c, parentQuote.CurrencyIsoCode) + '\n';
serialNo++;	
}*/
            
            /*Decimal totalAmount = subtotal + taxTotal;
System.debug('totalAmount: ' + totalAmount);

csvContent += '\n,,,,,Subtotal,' + String.valueOf(subtotal) + '\n';
csvContent += ',,,,,Tax,' + String.valueOf(taxTotal) + '\n';
csvContent += formattedTaxLabel + ',' + sanitize(taxAmount) + '\n';
csvContent += ',,,,,Total,' + String.valueOf(totalAmount) + '\n';
            Decimal totalAmount = subtotal + taxTotal;
            System.debug('totalAmount: ' + totalAmount);*/
            
            csvContent += '\n,,,,,Subtotal,' + fCurrency(subtotal, parentQuote.CurrencyIsoCode) + '\n';
            
            Boolean hasSpecificTaxes = false;
            Map<String, Decimal> taxRates = new Map<String, Decimal>{
                'GST' => parentQuote.Tax_Rate_GST__c,
                    'HST' => parentQuote.Tax_Rate_HST__c,
                    'PST' => parentQuote.Tax_Rate_PST__c,
                    'QST' => parentQuote.Tax_Rate_QST__c
                    };
                        Map<String, Decimal> taxAmounts = new Map<String, Decimal>{
                            'GST' => parentQuote.Tax_Amount_GST__c,
                                'HST' => parentQuote.Tax_Amount_HST__c,
                                'PST' => parentQuote.Tax_Amount_PST__c,
                                'QST' => parentQuote.Tax_Amount_QST__c
                                };
                                    Decimal runningTotal = subtotal;
            for (String taxName : taxRates.keySet()) {
                Decimal rate = taxRates.get(taxName);
                Decimal amount = taxAmounts.get(taxName);
                if (rate != null && rate > 0 && amount != null && amount > 0) {
                    hasSpecificTaxes = true;
                    String formattedRate = String.valueOf(rate.setScale(3));
                    csvContent += ',,,,,' + taxName + ' (' + formattedRate + '%),' 
                        + fCurrency(amount, parentQuote.CurrencyIsoCode) + '\n';
                    runningTotal += amount;
                }
            }
            
            // If no specific tax, use generic
            if (!hasSpecificTaxes && taxTotal != null) {
                Decimal rawRate = parentQuote.Tax_Rate__c != null ? parentQuote.Tax_Rate__c : 0;
                String formattedRate = String.valueOf(rawRate.setScale(3));
                csvContent += ',,,,,' + 'Tax(' + formattedRate + '%),' 
                    + fCurrency(taxTotal, parentQuote.CurrencyIsoCode) + '\n';
                runningTotal += taxTotal;
            }
            
            if (parentQuote.AVA_SFCLOUD__ShippingHandling_Tax__c != null && 
                parentQuote.ShippingHandling > 0) {
                    csvContent += '\n,,,,,' + 'Shipping and Handling,' 
                        + fCurrency(parentQuote.ShippingHandling, parentQuote.CurrencyIsoCode) + '\n';
                    csvContent += ',,,,,' + 'Shipping and Handling Tax,' 
                        + fCurrency(parentQuote.AVA_SFCLOUD__ShippingHandling_Tax__c, parentQuote.CurrencyIsoCode) + '\n';
                    runningTotal += parentQuote.AVA_SFCLOUD__ShippingHandling_Tax__c;
                    runningTotal += parentQuote.ShippingHandling;
                }
            
            // Total
            csvContent += ',,,,,Total,' + fCurrency(runningTotal, parentQuote.CurrencyIsoCode) + '\n';
        }
        return csvContent;
    }
    
    
    public static ContentVersion saveCSVToRecord(Id recordId) {
        String sObjectType = recordId.getSObjectType().getDescribe().getName();
        String csvContent = generateCSV(recordId, sObjectType);
        Quote quoteNum = [Select QuoteNumber From Quote where Id =: recordId];
        // Generate raw file name
        String rawFileName = 'Clutch_' + sObjectType + '_' + (quoteNum.QuoteNumber != null ? quoteNum.QuoteNumber : 'Export') + '.csv';
        
        // Sanitize the file name to remove invalid characters
        String safeFileName = sanitizeFileName(rawFileName);
        
        ContentVersion csvVersion = new ContentVersion();
        csvVersion.Title = safefileName;
        csvVersion.PathOnClient = safefileName;
        csvVersion.VersionData = Blob.valueOf(csvContent);
        csvVersion.IsMajorVersion = true;
        insert csvVersion;
        
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :csvVersion.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocId;
        cdl.LinkedEntityId = recordId; 
        cdl.ShareType = 'V';         
        cdl.Visibility = 'AllUsers';  
        insert cdl;
        
        return csvVersion;
    }
    
    // Helper method to sanitize the file name and remove invalid characters
    private static String sanitizeFileName(String fileName) {
        // Remove invalid Excel file name characters
        fileName = fileName.replaceAll('[\\\\/\\*\\?\\[\\]:]', '');  // Regex to remove invalid characters
        return fileName.length() > 31 ? fileName.substring(0, 31) : fileName; // Ensure file name does not exceed 31 characters
    }
    private static String formatAddress(Address addr) {
        if (addr == null) return '';
        List<String> parts = new List<String>();
        if (addr.street != null) parts.add(addr.street);
        if (addr.city != null) parts.add(addr.city);
        if (addr.state != null) parts.add(addr.state);
        if (addr.postalCode != null) parts.add(addr.postalCode);
        if (addr.country != null) parts.add(addr.country);
        return String.join(parts, ', ');
    }
    
    private static String sanitize(String input) {
        if (String.isBlank(input)) return '';
        input = input.replace('"', '""'); 
        return '"' + input.replace('\n', ' ').replace('\r', ' ') + '"';
    }
    
    public static String fCurrency(Decimal value) {
        return '$' + String.valueOf(value.setScale(2));
    }
    
    public static String fCurrency(Decimal value, String currencyCode){
        if (currencyCode == 'USD') {
            return '$' + String.valueOf(value.setScale(2));
        } else {
            return currencyCode + ' $' + String.valueOf(value.setScale(2));
        }
    }
    
    
}