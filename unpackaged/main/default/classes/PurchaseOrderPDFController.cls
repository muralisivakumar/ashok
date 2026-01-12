public class PurchaseOrderPDFController extends BasePDFController {
    public List<NoteWrapper> customerNotes { get; set; }
    public varcpq__Purchase_Order__c purchaseOrder { get; private set; }
    public List<varcpq__Purchase_Order_Line_Item__c> lineItems {
        get;
        private set;
    }
    public Account account { get; private set; }
    public varcpq__Sales_Order__c salesOrder { get; private set; }
    public  varcpq__Customer_Address__c supplierAddress { get; private set; }
    
    //Added by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    public Map<Id, String> lineItemDescriptionChunks { get; private set; }
    
    public class NoteWrapper {
        public String label { get; set; }
        public String text { get; set; }
        
        public NoteWrapper(Custom_Note__c note) {
            if (note.Note_Type__c == 'Supplier') {
                label = 'Supplier Note';
            } else {
                label = note.Note_Type__c;
            }
            text = note.Compose_Text__c;
        }
    }
    
    public String pageOrientation {
        get {
            return getPageOrientation();
        }
    }
    
    public CompanyInfo companyInfo {
        get {
            String recordType = 'US Account';
            if (
                this.account != null &&
                this.account.RecordType.Name == 'Canadian Account'
            ) {
                recordType = 'Canadian Account';
            }
            return getCompanyInfo(recordType);
        }
        private set;
    }
    
    public PurchaseOrderPDFController() {
        super();
        if (recordId != null) {
            loadData();
        }
        Id purchaseOrderId = ApexPages.currentPage().getParameters().get('id');
        customerNotes = new List<NoteWrapper>();
        
        for (Custom_Note__c note : [
            SELECT Id, Note_Type__c, Compose_Text__c
            FROM Custom_Note__c
            WHERE Purchase_Order__c = :purchaseOrderId
            AND Note_Type__c IN ('Customer Facing - Shipping', 'Customer Facing - Billing','Supplier')
            ORDER BY Note_Type__c
        ]) {
            customerNotes.add(new NoteWrapper(note));
        }
    }
    
    public String getFormattedNoteType(Custom_Note__c note) {
        if (note.Note_Type__c == 'Supplier') {
            return 'Supplier Note';
        } 
        return note.Note_Type__c;
    }
    
    
    protected override void loadData() {
        System.debug('Loading Purchase Order data for recordId: ' + recordId);
        
        purchaseOrder = [
            SELECT
            Id,
            Name,
            varcpq__PO_Status__c,
            varcpq__Customer_PO__c,
            varcpq__PO_Date__c,
            varcpq__Expected_Delivery_Date__c,
            varcpq__Distributor_Name__c,
            varcpq__Distributor_Contact__c,
            varcpq__Ship_To_Account__c,
            varcpq__Shipping_Instructions__c,
            varcpq__Shipping_Method__c,
            varcpq__Comments__c,
            varcpq__Sales_Order__c,
            varcpq__Purchase_Order_Total__c,
            varcpq__LIT__c,
            Purchase_Order_Grand_Total__c,
            CreatedBy.Name,
            CreatedBy.Email,
            CurrencyIsoCode,
            varcpq__Distributor_Terms__c,
            varcpq__PO_Terms_and_Conditions__c,
            varcpq__Freight_Allowance__c,
            varcpq__Distributor_Name__r.Name,
            varcpq__Distributor_Name__r.varcpq__NET_TERMS__c,
            varcpq__Distributor_Contact__r.Name,
            varcpq__Distributor_Contact__r.Phone,
            varcpq__Distributor_Contact__r.Email,
            varcpq__Ship_To_Account__r.Name,
            varcpq__Ship_To_Account__r.ShippingStreet,
            varcpq__Ship_To_Account__r.ShippingCity,
            varcpq__Ship_To_Account__r.ShippingState,
            varcpq__Ship_To_Account__r.ShippingPostalCode,
            varcpq__Ship_To_Account__r.ShippingCountry,
            PO_Confirmation_Number__c,
            Pay_Account__c,
            Taxes__c,
            Tax_Rate__c,
            Tax_Rate_GST__c, Tax_Rate_PST__c, Tax_Rate_HST__c, Tax_Rate_QST__c, Tax_Amount_GST__c, Tax_Amount_PST__c, Tax_Amount_HST__c, Tax_Amount_QST__c
            FROM varcpq__Purchase_Order__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        System.debug('Purchase Order found: ' + purchaseOrder);
        
        lineItems = [
            SELECT
            Id,
            Name,
            varcpq__Status__c,
            varcpq__DH_Line__c,
            varcpq__Manufacturer__c,
            varcpq__Part_No__c,
            varcpq__Unit_Cost__c,
            varcpq__Quantity__c,
            varcpq__Description__c,
            varcpq__AP_Line_Total_Amount__c,
            varcpq__Expected_Ship_Date__c
            FROM varcpq__Purchase_Order_Line_Item__c
            WHERE varcpq__Purchase_Order__c = :recordId
            ORDER BY Name
        ];
        System.debug('Line items found: ' + lineItems.size());
        lineItemDescriptionChunks = new Map<Id, String>();
        
        for(varcpq__Purchase_Order_Line_Item__c po: lineItems){
            if(String.isNotBlank(po.varcpq__Description__c)){
                
                String preserved = preserveFormatting(po.varcpq__Description__c);
                lineItemDescriptionChunks.put(po.Id, breakLongWord(preserved,30));
            }
            else{
                lineItemDescriptionChunks.put(po.Id,'');
            }
        }
        
        salesOrder = [
            SELECT Id, 
            Shipping_Company__c,
            Shipping_Contact_Name__c,
            Shipping_Country__c,
            Shipping_Email__c,
            Shipping_Phone__c,
            varcpq__Shipping_Address__c,
            varcpq__Shipping_and_Handling__c,
            varcpq__Shipping_City__c,
            varcpq__Shipping_Contact__c,
            varcpq__Shipping_State__c,
            varcpq__Shipping_Street__c,
            Shipping_Additional_Street__c,
            Additional_Ship_To_Header__c,
            varcpq__Shipping_Zip__c
            FROM varcpq__Sales_Order__c
            WHERE id = :purchaseOrder.varcpq__Sales_Order__c
            LIMIT 1
        ];
        System.debug('Sales Order found: ' + salesOrder);
        
        // FIX: Use a list to query and then check if records exist
        List<varcpq__Customer_Address__c> supplierAddresses = [
            SELECT
            Id,
            Name,
            Company_Name__c,
            varcpq__Street__c,
            varcpq__Additional_Street__c,
            varcpq__City__c,
            varcpq__State__c,
            varcpq__Zipcode__c,
            Country__c
            FROM varcpq__Customer_Address__c
            WHERE varcpq__Customer__c = :purchaseOrder.varcpq__Distributor_Name__c 
            AND Default_Billing_Address__c = true 
            AND varcpq__Active__c = true
            LIMIT 1
        ];
        
        // Check if any addresses were found
        if (!supplierAddresses.isEmpty()) {
            supplierAddress = supplierAddresses[0];
            System.debug('Supplier Default Address found: ' + supplierAddress);
        } else {
            // Initialize an empty address object if no address is found
            supplierAddress = new varcpq__Customer_Address__c();
            System.debug('No Supplier Default Address found - using empty address');
        }
        
        if (purchaseOrder.varcpq__Ship_To_Account__c != null) {
            System.debug(
                'Loading Account for Id: ' + purchaseOrder.varcpq__Ship_To_Account__c
            );
            account = [
                SELECT
                Id,
                Name,
                Industry,
                Phone,
                Website,
                Owner.Name,
                RecordTypeId,
                RecordType.Name
                FROM Account
                WHERE Id = :purchaseOrder.varcpq__Ship_To_Account__c
                LIMIT 1
            ];
            System.debug('Account found: ' + account);
        }
    }
    
    @AuraEnabled
    public static ContentVersion generateAndSavePDF(Id purchaseOrderId) {
        return savePDFToRecord(purchaseOrderId);
    }
    
    @AuraEnabled
    public static void generateAndEmailPDF(
        Id purchaseOrderId,
        List<String> toAddresses
    ) {
        //emailPDF(purchaseOrderId, toAddresses, 'Purchase_Order_PDF_EmailTemplate');
        EmailTemplate emailtemplate = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = 'Supplier_PO_Email_Template'
        ];
        if (emailTemplate != null) {
            emailPDF(purchaseOrderId, toAddresses, emailTemplate.Id);
        }
    }
    //Added by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    public static String breakLongWord(String input, Integer maxLength) {
        if (String.isBlank(input)) {
            return input;
        }
        
        List<String> words = input.split('\\s+');
        List<String> processedWords = new List<String>();
        
        for (String word : words) {
            if (word.length() > maxLength) {
                String broken = '';
                Integer startIdx = 0;
                while (startIdx < word.length()) {
                    Integer nextIdx = Math.min(startIdx + maxLength, word.length());
                    broken += word.substring(startIdx, nextIdx);
                    if (nextIdx < word.length()) {
                        // Use <wbr> instead of space — invisible break point
                        broken += '<wbr>';
                    }
                    startIdx = nextIdx;
                }
                processedWords.add(broken);
            } else {
                processedWords.add(word);
            }
        }
        
        return String.join(processedWords, ' ');
    }
    
    //Added by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    public static String preserveFormatting(String input) {
        if (String.isBlank(input)) return input;
        
        // Replace newline characters with <br/> for VF/PDF rendering
        String formatted = input.replace('\n', '<br/>');
        
        // Replace double spaces with non-breaking spaces (repeat until clean)
        while (formatted.contains('  ')) {
            formatted = formatted.replace('  ', '&nbsp;&nbsp;');
        }
        
        return formatted;
    }
}