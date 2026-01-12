public with sharing class PdfViewerController {
    @AuraEnabled(cacheable=true)
    public static PDF_Document_Configuration__mdt getDocumentConfiguration(Id recordId) {
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        
        List<PDF_Document_Configuration__mdt> configs = [
            SELECT Object_API_Name__c, 
            Template_Page_Name__c,
            Viewer_Header__c,
            Record_Id_Parameter__c,
            File_Name_Prefix__c,
            Record_Number_Field__c
            FROM PDF_Document_Configuration__mdt
            WHERE Object_API_Name__c = :objectApiName
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new AuraHandledException('No PDF configuration found for: ' + objectApiName);
        }
        
        return configs[0];
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getButtonConfiguration(String objectApiName) {
        List<PDF_Viewer_Configuration__mdt> configs = [
            SELECT Object_API_Name__c, 
            Show_Cancel_Button__c, 
            Show_Save_Button__c,
            Show_Download_Button__c, 
            Show_Email_Button__c, 
            Save_Button_Color__c,
            Download_Button_Color__c,
            Email_Button_Color__c
            FROM PDF_Viewer_Configuration__mdt
            WHERE Object_API_Name__c = :objectApiName
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new AuraHandledException('No viewer configuration found for: ' + objectApiName);
        }
        
        PDF_Viewer_Configuration__mdt config = configs[0];
        return new Map<String, Object>{
            'showSave' => config.Show_Save_Button__c,
                'showDownload' => config.Show_Download_Button__c,
                'showEmail' => config.Show_Email_Button__c,
                'showCancel' => config.Show_Cancel_Button__c,
                'saveButtonColor' => config.Save_Button_Color__c,
                'downloadButtonColor' => config.Download_Button_Color__c,
                'emailButtonColor' => config.Email_Button_Color__c
                };
                    }
    
    @AuraEnabled
    public static ContentVersion savePdf(Id recordId) {
        try {
            return BasePDFController.savePDFToRecord(recordId);
        } catch (Exception e) {
            throw new AuraHandledException('Error saving PDF: ' + e.getMessage());
        }
    }
    
    @AuraEnabled (cacheable = true)
    public static List<fieldOption> getFieldOptions(Id recordId){
        List<fieldOption> fields = new List<fieldOption>();
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        List<Schema.FieldSetMember> fieldSet = new List<Schema.FieldSetMember>();
        if(objectApiName == 'Quote'){
            fieldSet = SObjectType.QuoteLineItem.FieldSets.getMap().get('PDF_Fields_QLI').getFields();
            system.debug(fieldset);
        }
        for(Schema.FieldSetMember fsm : fieldSet){
            fieldOption fo = new fieldOption();
            fo.label = fsm.getLabel();
            fo.value = fsm.getFieldPath();
            fields.add(fo);
        }
        System.debug('fields '+fields);
        return fields;
    }
    
    public class fieldOption{
        @AuraEnabled public string label {get;set;}
        @AuraEnabled public string value {get;set;}
    }
    
	@AuraEnabled
    public static ContentVersion exportCSV(Id recordId) {
        return BasePDFController.saveCSVToRecord(recordId);
    }
    
    
    @AuraEnabled
    public static Map<String, Object> getDataForXlsx(Id recordId){
        Quote quote = [
            SELECT Id, QuoteNumber, Quote_Net_Terms__c, ExpirationDate, CreatedDate,
                   BillingName, ShippingName, Bill_to_email__c, Ship_to_email__c,
                   Bill_to_phone__c, Ship_to_phone__c,
                   Shipping_Method__c, Customer_PO__c, Tax_Rate__c,
                   Account.Name, Account.BillingCountry,
                   Opportunity.Name, Opportunity.Owner.Name, Opportunity.Owner.Email,
                   Contract.Name, BillingAddress, ShippingAddress, Account.RecordType.Name,
                   Tax_Rate_GST__c, Tax_Rate_HST__c, Tax_Rate_PST__c, Tax_Rate_QST__c, Tax_Amount_GST__c, Tax_Amount_HST__c, 
            	   Tax_Amount_PST__c, Tax_Amount_QST__c, CurrencyIsoCode,Tax,
                   AVA_SFCLOUD__ShippingHandling_Tax__c, ShippingHandling
            FROM Quote WHERE Id = :recordId
            LIMIT 1
        ];

        List<QuoteLineItem> items = [
            SELECT Product2.Name, Quantity, UnitPrice, varcpq__EXT_Price__c, 
                   varcpq__Manufacturer__c, Description , varcpq__DH_Quote_Group__r.name
            FROM QuoteLineItem WHERE QuoteId = :recordId
        ];

        // Fetch company info from metadata using RecordType
    String recordTypeName = quote.Account.RecordType.Name;
    List<PDF_Company_Information__mdt> companyInfoList = [
        SELECT Company_Name__c, Street__c, Suite__c, City_State_Zip__c, 
               Phone__c, Website__c, Record_Type__c
        FROM PDF_Company_Information__mdt 
        WHERE Record_Type__c = :recordTypeName
        LIMIT 1
    ];

        Map<String, String> companyInfoMap = new Map<String, String>();
        if (!companyInfoList.isEmpty()) {
            PDF_Company_Information__mdt companyInfo = companyInfoList[0];
            companyInfoMap.put('Company_Name__c', companyInfo.Company_Name__c);
            companyInfoMap.put('Street__c', companyInfo.Street__c);
            companyInfoMap.put('Suite__c', companyInfo.Suite__c);
            companyInfoMap.put('City_State_Zip__c', companyInfo.City_State_Zip__c);
            companyInfoMap.put('Phone__c', companyInfo.Phone__c);
            companyInfoMap.put('Website__c', companyInfo.Website__c);
        }
    
        return new Map<String, Object>{
            'quote' => quote,
            'lineItems' => items,
            'companyInfo' => companyInfoMap
        };
        
    }
    
    @AuraEnabled
    public static void saveExcelFileQuote(String base64Data, String fileName, Id quoteId){
        System.debug('fileName:: ' + fileName);
        System.debug('quoteId:: ' + quoteId);
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ].ContentDocumentId;
        cdl.LinkedEntityId = quoteId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    
}