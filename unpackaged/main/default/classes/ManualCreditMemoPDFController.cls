public class ManualCreditMemoPDFController extends BasePDFController {
    public Manual_Credit_Memo__c creditMemo { get; private set; }
    public Return_Merchandise_Authorization__c rma { get; private set; }
    public List<Return_Merchandise_Authorization_Line_It__c> rmaLineItems { get; private set; }
    public varcpq__Invoice__c invoice { get; private set; }
    public Account account { get; private set; }
    public varcpq__Sales_Order__c salesOrder { get; private set; }
    public Opportunity opportunity { get; private set; }
    public List<Shipping_and_Asset_Tracking__c> shippingAndAssetTracking { get; private set; }
    public List<Shipment_Tracking__c> shipmentTracking { get; private set; }
    
    //Modified data type by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    public Map<Id, String> lineItemDescriptionChunks { get; private set; }

    
  public List<NoteWrapper> customerNotes { get; set; }

    public class NoteWrapper {
        public String label { get; set; }
        public String text { get; set; }

        public NoteWrapper(Custom_Note__c note) {
            if (note.Note_Type__c == 'Customer Facing - Shipping') {
                label = 'Shipping Note';
            } else if (note.Note_Type__c == 'Customer Facing - Billing') {
                label = 'Billing Note';
            } else {
                label = note.Note_Type__c;
            }
            text = note.Compose_Text__c;
        }
    }
    
     public String getFormattedNoteType(Custom_Note__c note) {
        if (note.Note_Type__c == 'Customer Facing - Shipping') {
            return 'Shipping Note';
        } else if (note.Note_Type__c == 'Customer Facing - Billing') {
            return 'Billing Note';
        }
        return note.Note_Type__c;
    }
    
    public String pageOrientation {
        get {
            return getPageOrientation();
        }
    }
    @testVisible
    private Boolean isCanadianAccount {
        get {
            return this.account != null &&
                this.account.RecordType.Name == 'Canadian Account';
        }
    }
    
    public CompanyInfo companyInfo {
        get {
            String recordType = 'US Account';
            if (isCanadianAccount) {
                recordType = 'Canadian Account';
            }
            return getCompanyInfo(recordType);
        }
        private set;
    }
    
    public ManualCreditMemoPDFController() {
        super();
        if (recordId != null) {
            loadData();
        }
    }

    @TestVisible
    protected override void loadData() {
        
        // Load Manual Credit Memo
        creditMemo = [
            SELECT Id, Name, Status__c, Credit_Amount__c, Contract__c, Description__c, Customer_PO__c,Grand_Total__c,
                   Return_Merchandise_Authorization__c, Account__c, Reason_Code__c, CreatedDate,Invoice_Reference__c,RMA_Shipping_Refund__c,RMA_Restocking_Fee__c, 
            	   	Taxes__c, 	Tax_Rate__c,Accounts_Payable_Invoice__c   
            FROM Manual_Credit_Memo__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Load related RMA
        if (creditMemo.Return_Merchandise_Authorization__c != null) {
            rma = [
                SELECT Id, Name, Related_Invoice__c, Status__c, Shipping_Refund__c, Restocking_Fee__c, Reason_Code__c, Related_Sales_Order__r.varcpq__Contract_Number__c,
                Total_Amount__c, Related_Sales_Order__c, Account__c, Taxes__c, Related_Sales_Order__r.varcpq__Customer_PO__c, Related_Sales_Order__r.varcpq__SO_Number__c
                , Tax_Amount_GST__c, Tax_Amount_HST__c, Tax_Amount_PST__c, Tax_Amount_QST__c, Tax_Rate_GST__c,Tax_Rate_HST__c,Tax_Rate_PST__c,Tax_Rate_QST__c, Tax_Rate__c
                FROM Return_Merchandise_Authorization__c
                
                WHERE Id = :creditMemo.Return_Merchandise_Authorization__c
                LIMIT 1
            ];
        }

        // Load RMA Line Items
        rmaLineItems = new List<Return_Merchandise_Authorization_Line_It__c>();
        if (rma != null) {
            rmaLineItems = [
                SELECT Id, Name, Product__r.Name, Product__r.varcpq__Manufacturer__r.Name, Product__r.Description,
                       	Quantity__c, Unit_Price__c, Total_Ext_Price__c, Related_Sales_Order_Line_Item__c,RMA_Tax_Details__c,Tax_Amount_GST__c,
                        Tax_Amount_HST__c,Tax_Amount_PST__c, Tax_Amount_QST__c, Tax_Rate__c, Tax_Rate_AVATAX__c, Tax_Rate_GST__c, Tax_Rate_HST__c, Tax_Rate_PST__c,
                        Tax_Rate_QST__c,Product_Ava_Tax_Code__c, Description__c
                FROM Return_Merchandise_Authorization_Line_It__c
                WHERE Return_Merchandise_Authorization__c = :rma.Id
                ORDER BY CreatedDate
            ];
        }
        // Populate description chunks for each line item
        lineItemDescriptionChunks = new Map<Id, String>();
        for (Return_Merchandise_Authorization_Line_It__c line : rmaLineItems) {
            if(String.isNotBlank(line.Description__c)){
            String preserved = preserveFormatting(line.Description__c);
            lineItemDescriptionChunks.put(line.Id, breakLongWord(preserved,40));
            }
            else{
            lineItemDescriptionChunks.put(line.Id,'');
            }
        }
        
        
        // Load Invoice
         if (creditMemo.Invoice_Reference__c != null) {
            invoice = [
                SELECT
                Id,
                Name,
                CurrencyIsoCode,
                CreatedDate,
                varcpq__Sales_Order__r.Name,
                varcpq__Sales_Order__r.varcpq__SO_Number__c,
                varcpq__Issued_Date__c,
                varcpq__Due_Date__c,
                varcpq__Client__c,
                varcpq__Client__r.Name,
                varcpq__Sales_Order__r.CreatedDate,
                varcpq__Sales_Order__r.varcpq__Opportunity__r.Owner.Name,
                varcpq__Sales_Order__r.varcpq__Opportunity__r.Owner.Email,
                Bill_to_Company_Name__c,
                Bill_to_Name__c,
                Bill_to_Email__c,
                Bill_to_phone__c,
                Bill_to_Street__c,
                Bill_to_Additional_Street__c,
                Bill_to_City__c,
                Bill_to_State__c,
                Bill_to_zipcode__c,
                Bill_to_Country__c,
                varcpq__Billing_Contact__c,
                varcpq__Sales_Order__c,
                Contract_Number__c,
                Additional_Ship_To_Header__c,
                Ship_to_Company_Name__c,
                Ship_to_Name__c,
                Ship_to_Email__c,
                Ship_to_Phone__c,
                Ship_to_Street__c,
                Ship_to_Additional_Street__c,
                Ship_to_city__c,
                Ship_to_State__c,
                Ship_to_zipcode__c,
                Ship_to_Country__c,
                varcpq__Shipping_and_Handling__c,
                varcpq__PO_Number__c,
                varcpq__Terms__c,
                varcpq__Taxes__c,
                Tax_Rate__c,
                Tax_Amount_GST__c,
                Tax_Rate_GST__c,
                Tax_Amount_PST__c,
                Tax_Rate_PST__c,
                Tax_Amount_QST__c,
                Tax_Rate_QST__c,
                Tax_Amount_HST__c,
                Tax_Rate_HST__c,
                varcpq__LIT__c,
                Grand_Total__c
              FROM varcpq__Invoice__c
              WHERE Id =: creditMemo.Invoice_Reference__c
              LIMIT 1
            ];
        }

		
        // Load Account
        if (creditMemo.Account__c != null) {
               account = [
                  SELECT
                    Id,
                    Name,
                    varcpq__NET_TERMS__c,
                    Owner.Email,
                    Industry,
                    Phone,
                    Website,
                    Owner.Name,
                    RecordTypeId,
                    RecordType.Name
                  FROM Account
                  WHERE Id = :creditMemo.Account__c
                  LIMIT 1
    ];
        }
        //updated as part of #84 ASN by Vishnu S on 6/Jan/26
        //Start
         /*
     *  NEW SECTION: LOAD SHIPMENT TRACKING
     *  Shipment_Tracking__c.Accounts_Payable_Invoice__c  -->  creditMemo.Accounts_Payable_Invoice__c
     */
    shipmentTracking = new List<Shipment_Tracking__c>();
       /*
    if (creditMemo.Accounts_Payable_Invoice__c != null) {
        shipmentTracking = [
            SELECT Id,
                   Part_Number__c,
                   Shipping_Method__c,
                   Tracking_Number__c,
                   Ship_Date__c,
                   Serial_Numbers__c,
                   Accounts_Payable_Invoice__c
            FROM Shipment_Tracking__c
            WHERE Accounts_Payable_Invoice__c = :creditMemo.Accounts_Payable_Invoice__c
            ORDER BY CreatedDate
        ];
        if (creditMemo.Invoice_Reference__c != null) {
        shipmentTracking = [
            SELECT Id,
                   Part_Number__c,
                   Shipping_Method__c,
                   Tracking_Number__c,
                   Ship_Date__c,
                   Serial_Numbers__c,
                   Invoice_ID__c
            FROM Shipment_Tracking__c
            WHERE Invoice_ID__c  = :creditMemo.Invoice_Reference__c
            ORDER BY CreatedDate
        ];*/
     // Prefer Customer Invoice first (Invoice_Reference__c)
    if (creditMemo.Invoice_Reference__c != null) {
        shipmentTracking = [
            SELECT Id,
                   Part_Number__c,
                   Shipping_Method__c,
                   Tracking_Number__c,
                   Ship_Date__c,
                   Serial_Numbers__c,
                   Invoice_ID__c
            FROM Shipment_Tracking__c
            WHERE Invoice_ID__c = :creditMemo.Invoice_Reference__c
            ORDER BY CreatedDate
        ];
    }
    
    // If no shipment found, fallback to Accounts Payable Invoice
    if (shipmentTracking.isEmpty() && creditMemo.Accounts_Payable_Invoice__c != null) {
        shipmentTracking = [
            SELECT Id,
                   Part_Number__c,
                   Shipping_Method__c,
                   Tracking_Number__c,
                   Ship_Date__c,
                   Serial_Numbers__c,
                   Accounts_Payable_Invoice__c
            FROM Shipment_Tracking__c
            WHERE Accounts_Payable_Invoice__c = :creditMemo.Accounts_Payable_Invoice__c
            ORDER BY CreatedDate
        ];
    }
    //End
    }

    @AuraEnabled
    public static ContentVersion generateAndSavePDF(Id creditMemoId) {
        return savePDFToRecord(creditMemoId);
    }

    @AuraEnabled
    public static void generateAndEmailPDF(Id creditMemoId, List<String> toAddresses) {
        EmailTemplate template = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = 'Supplier_PO_Email_Template'
            LIMIT 1
        ];
        if (template != null) {
            emailPDF(creditMemoId, toAddresses, template.Id);
        }
    }
    
    // Helper method to split description text into 30-character chunks
    // Added by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    /* @TestVisible
    private List<String> splitDescription(String description) {
        List<String> chunks = new List<String>();
        if (String.isBlank(description)) return chunks;
        
        Integer maxLineLength = 40;
        String[] lines = description.split('\n');
        
        for (String line : lines) {
            if (String.isBlank(line)) {
                chunks.add(''); // preserve empty line
                continue;
            }
            
            String[] words = line.trim().split(' ');
            String currentLine = '';
            
         for (String word : words) {
    Integer space = currentLine == '' ? 0 : 1;
    if ((currentLine.length() + word.length() + space) <= maxLineLength) {
        currentLine += (space == 0 ? '' : ' ') + word;
    } else {
        if (currentLine != '') {
            chunks.add(currentLine);
        }
        // Handle long word that exceeds maxLineLength
        if (word.length() > maxLineLength && currentLine == '') {
            chunks.add(word);
            currentLine = '';
        } else {
            currentLine = word;
        }
    }
}

            if (currentLine != '') {
                chunks.add(currentLine);
            }
        }
        
        return chunks;
    }*/
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