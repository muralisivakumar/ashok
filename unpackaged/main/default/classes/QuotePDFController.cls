public class QuotePDFController extends BasePDFController {
    public List<NoteWrapper> customerNotes { get; set; }
    // Public properties for the template
    public Quote quote { get; private set; }
    public Opportunity opportunity { get; private set; }
    public Account account { get; private set; }

    // New properties for group support
    public List<QuoteGroup> quoteGroups { get; private set; }
    public List<QuoteLineItem> ungroupedItems { get; private set; }
    public Boolean hasMultipleGroups { get; private set; }
    public Boolean hasRenewalDates { get; set; }

    // Public property to hold processed descriptions
    public List<String> processedDescriptions { get; private set; }
    
    //Modified data type by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    // New: Map to hold Line Item ID to List of description chunks
     public Map<Id, String> lineItemDescriptionChunks { get; private set; }  
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

    // Inner class to represent a quote group with its line items
    public class QuoteGroup implements Comparable {
        public varcpq__DH_Quote_Group__c groupRecord { get; set; }
        public List<QuoteLineItem> lineItems { get; set; }
        public Decimal subtotal { get; set; }
        public Decimal taxAmount { get; set; }
        public Decimal groupTotal { get; set; }

        public QuoteGroup(varcpq__DH_Quote_Group__c grp) {
            this.groupRecord = grp;
            this.lineItems = new List<QuoteLineItem>();
            this.subtotal = 0;
            this.taxAmount = 0;
            this.groupTotal = 0;
        }

        public void calculateTotals() {
            // Use the pre-calculated subtotal from the group record if available, otherwise calculate it
            if (this.groupRecord.varcpq__DH_Sub_Total__c != null) {
                this.subtotal = this.groupRecord.varcpq__DH_Sub_Total__c;
            } else {
                this.subtotal = 0;
                for (QuoteLineItem item : lineItems) {
                    this.subtotal += (item.varcpq__EXT_Price__c != null) ? item.varcpq__EXT_Price__c : 0;
                }
            }

            // Calculate tax amount based on quote tax rate
            this.taxAmount = 0;
            for (QuoteLineItem item : lineItems) {
                Decimal itemTax = 0;
                if (item.varcpq__EXT_Price__c != null && item.Quote.varcpq__Tax_Rate__c != null) {
                    itemTax = (item.varcpq__EXT_Price__c * item.Quote.varcpq__Tax_Rate__c) / 100.0;
                }
                this.taxAmount += itemTax;
            }

            this.groupTotal = this.subtotal + this.taxAmount;
        }

        // Implement the compareTo method for sorting
        public Integer compareTo(Object objToCompare) {
            QuoteGroup other = (QuoteGroup) objToCompare;
            Integer thisSequence = Integer.valueOf(this.groupRecord.varcpq__DH_Sequence__c);
            Integer otherSequence = Integer.valueOf(other.groupRecord.varcpq__DH_Sequence__c);

            if (thisSequence > otherSequence) {
                return 1;
            } else if (thisSequence < otherSequence) {
                return -1;
            } else {
                return 0;
            }
        }
    }

    public String pageOrientation {
        get {
            if (!hasRenewalDates) {
                return getPageOrientation();
            }
            return 'A4 landscape';
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

    public QuotePDFController() {
        super();
        if (recordId != null) {
            loadData();
        }
        
        Id quoteId = ApexPages.currentPage().getParameters().get('id');
        customerNotes = new List<NoteWrapper>();

        for (Custom_Note__c note : [
            SELECT Id, Note_Type__c, Compose_Text__c
            FROM Custom_Note__c
            WHERE Quote__c = :quoteId
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

    @TestVisible
    protected override void loadData() {
        // Load Quote with all needed fields
        quote = [
            SELECT
                Id,
                Name,
                Status,
                QuoteNumber,
                ExpirationDate,
                OpportunityId,
                BillingName,
                BillingStreet,
                BillingAdditionalStreet__c,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry,
                ShippingName,
                ShippingStreet,
                ShippingAdditionalStreet__c,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                Email,
                Description,
                Contract.Name,
                AVA_SFCLOUD__Shipping_Method__c,
                CurrencyIsoCode,
                ShippingHandling,
                varcpq__Sub_Total__c,
                varcpq__Tax_Rate__c,
                varcpq__Total_Tax__c,
                GrandTotal,
                CreatedBy.Name,
                CreatedBy.Email,
                Quote_Net_Terms__c,
                varcpq__Customer_Notes__c,
                Bill_to_email__c,
                Ship_to_email__c,
                Bill_To_Company__c,
                Ship_To_Company__c,
                Bill_to_phone__c,
                Ship_to_phone__c,
                varcpq__Estimated_Taxes__c,
                AVA_SFCLOUD__ShippingHandling_Tax__c,
                Tax_Amount_GST__c,
                Tax_Rate_GST__c,
                Tax_Amount_PST__c,
                Tax_Rate_PST__c,
                Tax_Amount_HST__c,
                Tax_Rate_HST__c,
                Tax_Amount_QST__c,
                Tax_Rate_QST__c,
                Tax,
                Tax_Rate__c,
                Additional_Ship_To_Header__c,
                Shipping_Method__c,
                Customer_PO__c,
                Line_Start_Date__c,
                Line_End_Date__c,
                Cost_Centre_Reference__c
            FROM Quote
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Load related Opportunity
        opportunity = [
            SELECT Id, Name, StageName, CloseDate, Amount, AccountId
            FROM Opportunity
            WHERE Id = :quote.OpportunityId
            LIMIT 1
        ];

        // Load related Account
        account = [
            SELECT
                Id,
                Name,
                varcpq__NET_TERMS__c,
                Industry,
                Phone,
                Website,
                Owner.Name,
                RecordTypeId,
                RecordType.Name,
                Owner.Phone,
                Owner.Extension,
                Owner.Email
            FROM Account
            WHERE Id = :opportunity.AccountId
            LIMIT 1
        ];


        // Get all Quote Groups for this quote
        Map<Id, varcpq__DH_Quote_Group__c> groupsMap = new Map<Id, varcpq__DH_Quote_Group__c>(
            [SELECT Id, Name, varcpq__DH_Sequence__c, varcpq__DH_Sub_Total__c
             FROM varcpq__DH_Quote_Group__c 
             WHERE varcpq__DH_Quote__c = :recordId 
             ORDER BY varcpq__DH_Sequence__c ASC]
        );

        // Load Quote Line Items with group information
        List<QuoteLineItem> allLineItems = [
            SELECT
                Id,
                QuoteId,
                varcpq__DH_Line__c,
                LineNumber,
                Product2Id,
                varcpq__PartNumber__c,
                varcpq__Manufacturer__c,
                Quantity,
                Subtotal,
                Description,
                Description__c,
                ListPrice,
                varcpq__EXT_Price__c,
                UnitPrice,
                varcpq__DH_Quote_Group__c,
                Quote.varcpq__Tax_Rate__c,
                Term_Start_Date__c,
                Term_End_Date__c
            FROM QuoteLineItem
            WHERE QuoteId = :recordId
            ORDER BY varcpq__DH_Line__c
        ];

        // Initialize group collections
        quoteGroups = new List<QuoteGroup>();
        ungroupedItems = new List<QuoteLineItem>();
        Map<Id, QuoteGroup> quoteGroupMap = new Map<Id, QuoteGroup>();

        // Create QuoteGroup objects for each group
        for (varcpq__DH_Quote_Group__c groupRecord : groupsMap.values()) {
            if (groupRecord.Name != 'Untitled') { // Skip "Untitled" groups
                QuoteGroup qg = new QuoteGroup(groupRecord);
                quoteGroups.add(qg);
                quoteGroupMap.put(groupRecord.Id, qg);
            }
        }

        // Determine if we should show groups (more than one group that isn't "Untitled")
        hasMultipleGroups = quoteGroups.size() > 0;
        hasRenewalDates = quote.Line_Start_Date__c != null || quote.Line_End_Date__c != null ? true : false;

        // Organize line items into their respective groups
        
        for (QuoteLineItem item : allLineItems) {
            if (item.varcpq__DH_Quote_Group__c != null && quoteGroupMap.containsKey(item.varcpq__DH_Quote_Group__c)) {
                quoteGroupMap.get(item.varcpq__DH_Quote_Group__c).lineItems.add(item);
            } else {
                ungroupedItems.add(item);
            }
        }
        
        // Calculate totals for each group
        for (QuoteGroup groupWrapper : quoteGroups) {
            groupWrapper.calculateTotals();
        }

        // Sort groups by sequence
        quoteGroups.sort();

        // Populate processedDescriptions with longer descriptions from all line items
        processedDescriptions = new List<String>();
        lineItemDescriptionChunks = new Map<Id, String>();

        // Process all line items (both grouped and ungrouped)
        for (QuoteGroup groupWrapper : quoteGroups) {
            for (QuoteLineItem item : groupWrapper.lineItems) {
                if(String.isNotBlank(item.Description__c)){
                 String preserved = preserveFormatting(item.Description__c);
                lineItemDescriptionChunks.put(item.Id, breakLongWord(preserved,30));
                }
                else{
                    lineItemDescriptionChunks.put(item.Id,'');
                }
            }
        }
        for (QuoteLineItem item : ungroupedItems) {
            processedDescriptions.add(getLongerDescription(item));
             if(String.isNotBlank(item.Description__c)){
            String preserved = preserveFormatting(item.Description__c);
            lineItemDescriptionChunks.put(item.Id, breakLongWord(preserved,30));
             }
             else{
                  lineItemDescriptionChunks.put(item.Id,'');
             }
        }
    }
    
    @TestVisible
    private String formatCurrency(Decimal amount) {
        if (amount == null)
            return quote.CurrencyIsoCode + ' 0.00';
        return quote.CurrencyIsoCode + ' $' + amount.setScale(2).format();
    }

    @AuraEnabled
    public static ContentVersion generateAndSavePDF(Id quoteId) {
        return savePDFToRecord(quoteId);
    }

    @AuraEnabled
    public static void generateAndEmailPDF(Id quoteId, List<String> toAddresses) {
        EmailTemplate emailTemplate = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = 'Clutch_Quote_Email_Template'
            LIMIT 1
        ];
        if (emailTemplate != null) {
            emailPDF(quoteId, toAddresses, emailTemplate.Id);
        }
    }

    @AuraEnabled
    public static List<String> getDefaultEmailRecipients(Id quoteId) {
        Quote quote = [
            SELECT Id, Bill_to_email__c, Ship_to_email__c
            FROM Quote
            WHERE Id = :quoteId
        ];

        Set<String> recipients = new Set<String>();

        if (String.isNotBlank(quote.Bill_to_email__c)) {
            recipients.add(quote.Bill_to_email__c);
        }
        if (String.isNotBlank(quote.Ship_to_email__c)) {
            recipients.add(quote.Ship_to_email__c);
        }

        return new List<String>(recipients);
    }

    /* Updated by Vishnu on 07/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    // Helper method to split description text into 40-char chunks
    @TestVisible  private List<String> splitDescription(String description) {
        List<String> chunks = new List<String>();
        if (description == null) return chunks;

        Integer chunkSize = 30;
        Integer pos = 0;

        while (pos < description.length()) {
            Integer endPos = Math.min(pos + chunkSize, description.length());
            chunks.add(description.substring(pos, endPos));
            pos += chunkSize;
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
   

    // Add this method inside your QuotePDFController class
//private String getLongerDescription(QuoteLineItem item) {
  //  String desc1 = item.Description != null ? item.Description.trim() : '';
   // String desc2 = item.Description__c != null ? item.Description__c.trim() : '';

   // if (desc1.length() >= desc2.length()) {
   //     return desc1;
   // } else {
   //     return desc2;
   // }
//}
    //Added by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    @TestVisible private String getLongerDescription(QuoteLineItem item) {
        String desc1 = (item.Description != null && item.Description.trim() != '') ? item.Description.trim() : null;
        String desc2 = (item.Description__c != null && item.Description__c.trim() != '') ? item.Description__c.trim() : null;
        
        if (desc1 == null && desc2 == null) {
            return '';
        }
        if (desc1 == null) {
            return desc2;
        }
        if (desc2 == null) {
            return desc1;
        }
        
        return (desc1.length() > desc2.length()) ? desc1 : desc2;
    }
}