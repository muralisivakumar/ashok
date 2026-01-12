public class SalesOrderPDFController extends BasePDFController {
    // Wrapped customer notes
    public List<NoteWrapper> customerNotes { get; set; }

    // Properties for template
    public varcpq__Sales_Order__c salesOrder { get; private set; }
    public Opportunity opportunity { get; private set; }
    public Account account { get; private set; }
    public List<varcpq__Sales_Order_Line_Item__c> lineItems { get; private set; }
    //Modified data type by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    public Map<Id, String> lineItemDescriptionChunks { get; private set; }

    public static boolean testRunning = false; 

    // New properties for group support
    public List<SalesOrderGroup> salesOrderGroups { get; private set; }
    public List<varcpq__Sales_Order_Line_Item__c> ungroupedItems { get; private set; }
    public Boolean hasMultipleGroups { get; private set; }

    // Inner classes
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

    public class SalesOrderGroup implements Comparable {
        public Sales_Order_Group__c groupRecord { get; set; }
        public List<varcpq__Sales_Order_Line_Item__c> lineItems { get; set; }
        public Decimal subtotal { get; set; }
        public Decimal taxAmount { get; set; }
        public Decimal groupTotal { get; set; }

        public SalesOrderGroup(Sales_Order_Group__c grp) {
            this.groupRecord = grp;
            this.lineItems = new List<varcpq__Sales_Order_Line_Item__c>();
            this.subtotal = 0;
            this.taxAmount = 0;
            this.groupTotal = 0;
        }

        public void calculateTotals() {
            if (this.groupRecord.Sub_Total__c != null) {
                this.subtotal = this.groupRecord.Sub_Total__c;
            } else {
                this.subtotal = 0;
                for (varcpq__Sales_Order_Line_Item__c item : lineItems) {
                    this.subtotal += (item.varcpq__Total_Ext_Price__c != null) ? item.varcpq__Total_Ext_Price__c : 0;
                }
            }

            this.taxAmount = 0;
            for (varcpq__Sales_Order_Line_Item__c item : lineItems) {
                Decimal itemTax = 0;
                if (item.varcpq__Total_Ext_Price__c != null && item.varcpq__Sales_Order__r != null && item.varcpq__Sales_Order__r.Tax_Rate__c != null) {
                    itemTax = (item.varcpq__Total_Ext_Price__c * item.varcpq__Sales_Order__r.Tax_Rate__c) / 100.0;
                }
                this.taxAmount += itemTax;
            }

            this.groupTotal = this.subtotal + this.taxAmount;
        }

        public Integer compareTo(Object objToCompare) {
            SalesOrderGroup other = (SalesOrderGroup)objToCompare;
            Integer thisSequence = Integer.valueOf(this.groupRecord.Sequence__c);
            Integer otherSequence = Integer.valueOf(other.groupRecord.Sequence__c);

            if (thisSequence > otherSequence) return 1;
            else if (thisSequence < otherSequence) return -1;
            else return 0;
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
            if (this.account != null && this.account.RecordType != null && this.account.RecordType.Name == 'Canadian Account') {
                recordType = 'Canadian Account';
            }
            return getCompanyInfo(recordType);
        }
        private set;
    }

    // Constructor
    public SalesOrderPDFController() {
        super();
        System.debug('Constructor - recordId from page params: ' + recordId);
        System.debug('All page parameters: ' + ApexPages.currentPage().getParameters());

        if (recordId != null) {
            loadData();
        }

        Id salesOrderId = ApexPages.currentPage().getParameters().get('id');
        customerNotes = new List<NoteWrapper>();

        for (Custom_Note__c note : [
            SELECT Id, Note_Type__c, Compose_Text__c
            FROM Custom_Note__c
            WHERE Sales_Order__c = :salesOrderId
            AND Note_Type__c IN ('Customer Facing - Shipping', 'Customer Facing - Billing','Customer Notes')  // Apexify -- Surya -- Added 'Customer Notes' filter
            ORDER BY Note_Type__c
        ]) {
            customerNotes.add(new NoteWrapper(note));
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

    protected override void loadData() {
        System.debug('Loading Sales Order data for recordId: ' + recordId);

        salesOrder = [
            SELECT
                Id, Name, varcpq__Stage__c, varcpq__SO_Number__c, Taxes__c,
                Billing_Contact_Name__c, varcpq__Billing_Street__c, varcpq__Billing_City__c,
                varcpq__Billing_State__c, varcpq__Billing_Zip__c, Billing_Additional_Street__c,
                Billing_Country__c, Billing_Email__c, Shipping_Contact_Name__c,
                varcpq__Shipping_Street__c, varcpq__Shipping_City__c, varcpq__Shipping_State__c,
                varcpq__Shipping_Zip__c, Shipping_Country__c, Shipping_Additional_Street__c,
                Shipping_Email__c, Billing_Company__c, Shipping_Company__c,
                Billing_Phone__c, Shipping_Phone__c, varcpq__Estimated_Ship_Date__c,
                CurrencyIsoCode, varcpq__Shipping_and_Handling__c, varcpq__Total_Expected_Revenue__c,
                Grand_Total__c, varcpq__Total_Taxes__c, varcpq__Notes__c,
                CreatedBy.Name, CreatedBy.Email, varcpq__Opportunity__c,
                Tax_Amount_GST__c, Tax_Amount_PST__c, Tax_Amount_HST__c,
                Tax_Amount_QST__c, Tax_Rate_GST__c, Tax_Rate_PST__c,
                Tax_Rate_HST__c, Tax_Rate_QST__c, Tax_Rate__c,
                SO_Net_Terms__c, Quote__c, Additional_Ship_To_Header__c,
                varcpq__Customer_PO__c, Contract__r.Name, Shipping_Method__c,
                Shipping_and_Handling_Tax__c, Sub_Total__c,Tax_Rate1__c, Order_Date__c,Cost_Centre_Reference__c
            FROM varcpq__Sales_Order__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (salesOrder.varcpq__Opportunity__c != null) {
            opportunity = [
                SELECT Id, Name, AccountId
                FROM Opportunity
                WHERE Id = :salesOrder.varcpq__Opportunity__c
                LIMIT 1
            ];

            if (opportunity.AccountId != null) {
                account = [
                    SELECT
                        Id, Name, Industry, Phone, Website,
                        Owner.Name, RecordTypeId, RecordType.Name, Owner.Email
                    FROM Account
                    WHERE Id = :opportunity.AccountId
                    LIMIT 1
                ];
            }
        }

        // Query line items
        List<varcpq__Sales_Order_Line_Item__c> allLineItems = [
            SELECT
                Id, varcpq__Line__c, varcpq__Product__c,
                varcpq__Product__r.varcpq__Manufacturer__c,
                varcpq__Product__r.Name,
                varcpq__Product__r.varcpq__Manufacturer__r.Name,
                varcpq__Quantity__c, varcpq__Description__c,
                varcpq__List_Price__c, varcpq__Total_Ext_Price__c,
                varcpq__Unit_Price__c, Sales_Order_Group__c,
                varcpq__Sales_Order__r.Tax_Rate__c
            FROM varcpq__Sales_Order_Line_Item__c
            WHERE varcpq__Sales_Order__c = :recordId
            ORDER BY varcpq__Line__c
        ];
        this.lineItems = allLineItems;

        // Group info
        Map<Id, Sales_Order_Group__c> groupsMap = new Map<Id, Sales_Order_Group__c>(
            [SELECT Id, Name, Sequence__c, Sub_Total__c
             FROM Sales_Order_Group__c
             WHERE Sales_Order__c = : salesOrder.Id
             ORDER BY Sequence__c ASC]
        );

        salesOrderGroups = new List<SalesOrderGroup>();
        ungroupedItems = new List<varcpq__Sales_Order_Line_Item__c>();
        Map<Id, SalesOrderGroup> salesOrderGroupMap = new Map<Id, SalesOrderGroup>();

        for (Sales_Order_Group__c groupRecord : groupsMap.values()) {
            if (groupRecord.Name != 'Untitled') { // Skip "Untitled" groups
                SalesOrderGroup qg = new SalesOrderGroup(groupRecord);
                salesOrderGroups.add(qg);
                salesOrderGroupMap.put(groupRecord.Id, qg);
            }
        }

        hasMultipleGroups = salesOrderGroups.size() > 0;

        for (varcpq__Sales_Order_Line_Item__c item : allLineItems) {
            if (item.Sales_Order_Group__c != null && salesOrderGroupMap.containsKey(item.Sales_Order_Group__c)) {
                salesOrderGroupMap.get(item.Sales_Order_Group__c).lineItems.add(item);
            } else {
                ungroupedItems.add(item);
            }
        }

        for (SalesOrderGroup groupWrapper : salesOrderGroups) {
            groupWrapper.calculateTotals();
        }

        salesOrderGroups.sort();

        // --- NEW: Build line item description chunks to wrap description on PDF ---
        lineItemDescriptionChunks = new Map<Id,String>();
        for (varcpq__Sales_Order_Line_Item__c line : allLineItems) {
            if(String.isNotBlank(line.varcpq__Description__c)){
            String preserved = preserveFormatting(line.varcpq__Description__c);
            lineItemDescriptionChunks.put(line.Id, breakLongWord(preserved,40));
            }
            else{
            lineItemDescriptionChunks.put(line.Id, breakLongWord('',40));            }
        }
    } @AuraEnabled
    public static ContentVersion generateAndSavePDF(Id salesOrderId) {
        // Call your existing logic to generate PDF and save as ContentVersion
        return savePDFToRecord(salesOrderId);
    }

    @AuraEnabled
    public static void generateAndEmailPDF(
        Id salesOrderId,
        List<String> toAddresses
    ) {
        EmailTemplate emailTemplate = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = 'Supplier_PO_Email_Template'
            LIMIT 1
        ];

        if (emailTemplate != null) {
            emailPDF(salesOrderId, toAddresses, emailTemplate.Id);
        }
    }
    @AuraEnabled
public static List<String> getDefaultEmailRecipients(Id salesOrderId) {
    varcpq__Sales_Order__c salesOrder = [
        SELECT Id, Billing_Email__c, Shipping_Email__c
        FROM varcpq__Sales_Order__c
        WHERE Id = :salesOrderId
        LIMIT 1
    ];

    Set<String> recipients = new Set<String>();

    if (String.isNotBlank(salesOrder.Billing_Email__c)) {
        recipients.add(salesOrder.Billing_Email__c);
    }
    if (String.isNotBlank(salesOrder.Shipping_Email__c)) {
        recipients.add(salesOrder.Shipping_Email__c);
    }

    return new List<String>(recipients);
}

    
   //Commented below method by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"

    // Helper method to split description text into 40-char chunks (can adjust chunk size here)
   /* private List<String> splitDescription(String description) {
        List<String> chunks = new List<String>();
        if (description == null) return chunks;

        Integer chunkSize = 40;
        Integer pos = 0;

        while (pos < description.length()) {
            Integer endPos = Math.min(pos + chunkSize, description.length());
            chunks.add(description.substring(pos, endPos));
            pos += chunkSize;
        }

        return chunks;
    }
    
    */
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