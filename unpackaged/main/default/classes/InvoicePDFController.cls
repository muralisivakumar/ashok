public class InvoicePDFController extends BasePDFController {
    // Public properties for the template
    public varcpq__Invoice__c invoice { get; private set; }
    public List<varcpq__Invoice_Line_Item__c> lineItems { get; private set; }
    public varcpq__Sales_Order__c salesOrder { get; private set; }
    public Opportunity opportunity { get; private set; }
    public Account account { get; private set; }
    //Commented as part of #84 ASN by Vishnu S on 6/Jan/26
    //public List<Shipping_and_Asset_Tracking__c> shippingAndAssetTracking { get; private set; }
    public List<Shipment_Tracking__c> shipmentTracking { get; private set; }
    public List<ShippingTrackingWrapper> groupedShippingData { get; private set; }
    
    //Modified data type by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
    // New: Map to hold Line Item ID to List of description chunks
    public Map<Id,String> lineItemDescriptionChunks { get; private set; }

    // Group Support
    public List<InvoiceGroup> invoiceGroups { get; private set; }
    public List<varcpq__Invoice_Line_Item__c> ungroupedItems { get; private set; }
    public Boolean hasMultipleGroups { get; private set; }

    public List<NoteWrapper> customerNotes { get; set; }
    // Wrapper class for grouped shipping data
    public class ShippingTrackingWrapper {
    public String partNumber { get; set; }
    public String shippingMethod { get; set; }
    public String trackingNumber { get; set; }
    public Date shipDate { get; set; }
    public String serialNumbers { get; set; } // Comma-separated serial numbers
    
    public ShippingTrackingWrapper(String partNum, String shipMethod, String trackNum, Date shipDt, String serials) {
        this.partNumber = partNum;
        this.shippingMethod = shipMethod;
        this.trackingNumber = trackNum;
        this.shipDate = shipDt;
        this.serialNumbers = serials;
    }
    
    public String getGroupKey() {
        return partNumber + '|' + shippingMethod + '|' + trackingNumber + '|' + String.valueOf(shipDate);
    }
    }

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

    // Inner class to represent an invoice group with its line items
    public class InvoiceGroup implements Comparable {
        public Invoice_Group__c groupRecord { get; set; }
        public List<varcpq__Invoice_Line_Item__c> lineItems { get; set; }
        public Decimal subtotal { get; set; }
        public Decimal taxAmount { get; set; }
        public Decimal groupTotal { get; set; }

        public InvoiceGroup(Invoice_Group__c grp) {
            this.groupRecord = grp;
            this.lineItems = new List<varcpq__Invoice_Line_Item__c>();
            this.subtotal = 0;
            this.taxAmount = 0;
            this.groupTotal = 0;
        }

        public void calculateTotals() {
            // Use the pre-calculated subtotal from the group record if available, otherwise calculate it
            if (this.groupRecord.Sub_Total__c != null) {
                this.subtotal = this.groupRecord.Sub_Total__c;
            } else {
                this.subtotal = 0;
                for (varcpq__Invoice_Line_Item__c item : lineItems) {
                    this.subtotal += (item.varcpq__Ext_Total__c != null) ? item.varcpq__Ext_Total__c : 0;
                }
            }

            // Calculate tax amount if needed
            this.taxAmount = 0;
            // Tax calculation would go here if needed

            this.groupTotal = this.subtotal + this.taxAmount;
        }

        // Implement the compareTo method for sorting
        public Integer compareTo(Object objToCompare) {
            InvoiceGroup other = (InvoiceGroup)objToCompare;
            Integer thisSequence = Integer.valueOf(this.groupRecord.Sequence__c);
            Integer otherSequence = Integer.valueOf(other.groupRecord.Sequence__c);

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

    public InvoicePDFController() {
        super();
        if (recordId != null) {
            loadData();
        }
    }

    @TestVisible
    protected override void loadData() {
        // Load Invoice with all needed fields
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
                Grand_Total__c,
            Cost_Centre_Reference__c
            FROM varcpq__Invoice__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        System.debug('Invoice found: ' + invoice);

        // Load all line items for this invoice
        lineItems = [
            SELECT
                Id,
                IsDeleted,
                Name,
                CurrencyIsoCode,
                CreatedDate,
                CreatedById,
                LastModifiedDate,
                LastModifiedById,
                SystemModstamp,
                LastActivityDate,
                varcpq__Invoice__c,
                varcpq__Sales_Order_Line_Item__c,
                varcpq__Status__c,
                varcpq__Asset__c,
                varcpq__Contract_Fees__c,
                varcpq__Credit_Note__c,
                varcpq__Credit_Quantity__c,
                varcpq__DH_Line__c,
                varcpq__Notes__c,
                varcpq__Quantity__c,
                varcpq__Tax_Description_1__c,
                varcpq__Tax_Description_2__c,
                varcpq__Tax_Description_3__c,
                varcpq__Tax_Description_4__c,
                varcpq__Tax_Description_5__c,
                varcpq__Tax_Description_6__c,
                varcpq__Tax_Rate_1__c,
                varcpq__Tax_Rate_2__c,
                varcpq__Tax_Rate_3__c,
                varcpq__Tax_Rate_4__c,
                varcpq__Tax_Rate_5__c,
                varcpq__Tax_Rate_6__c,
                varcpq__Total_Cost__c,
                varcpq__Unit_Price__c,
                varcpq__Asset_Status__c,
                varcpq__Credit_Amount__c,
                varcpq__Description__c,
                varcpq__Ext_Margin__c,
                varcpq__Ext_Tax__c,
                varcpq__Ext_Total__c,
                varcpq__Part_No__c,
                varcpq__Tax_Amount_1__c,
                varcpq__Tax_Amount_2__c,
                varcpq__Tax_Amount_3__c,
                varcpq__Tax_Amount_4__c,
                varcpq__Tax_Amount_5__c,
                varcpq__Tax_Amount_6__c,
                Product__r.Name, 
                Product__r.varcpq__Manufacturer__r.Name,
                Product__c,
                Invoice_Group__c
            FROM varcpq__Invoice_Line_Item__c
            WHERE varcpq__Invoice__c = :recordId
            ORDER BY varcpq__DH_Line__c
        ];
        System.debug('Line items found: ' + lineItems.size());
        
        // Populate description chunks for each line item
        lineItemDescriptionChunks = new Map<Id,String>();
        for (varcpq__Invoice_Line_Item__c line : lineItems) {
            if(String.isNotBlank(line.varcpq__Description__c)){
            String preserved = preserveFormatting(line.varcpq__Description__c);
            lineItemDescriptionChunks.put(line.Id, breakLongWord(preserved,40));
            }
            else{
                 lineItemDescriptionChunks.put(line.Id,'');
            }
        }

        // Load related Sales Order
        salesOrder = [
            SELECT
                Id,
                Name,
                Taxes__c,
                Billing_Contact_Name__c,
                varcpq__Opportunity__c,
                varcpq__Billing_Street__c,
                varcpq__Billing_City__c,
                varcpq__Billing_State__c,
                varcpq__Billing_Zip__c,
                Billing_Country__c,
                Shipping_Contact_Name__c,
                varcpq__Shipping_Street__c,
                varcpq__Shipping_City__c,
                varcpq__Shipping_State__c,
                varcpq__Shipping_Zip__c,
                Shipping_Country__c,
                Billing_Email__c,
                Shipping_Email__c,
                Billing_Company__c,
                Shipping_Company__c,
                Billing_Phone__c,
                Shipping_Phone__c,
                Shipping_Method__c,
                varcpq__Estimated_Ship_Date__c,
                CurrencyIsoCode,
                varcpq__Shipping_and_Handling__c,
                Shipping_and_Handling_Tax__c,
                varcpq__Total_Expected_Revenue__c,
                Grand_Total__c,
                varcpq__Total_Taxes__c,
                CreatedBy.Name,
                CreatedBy.Email,
                Tax_Amount_GST__c,
                Tax_Amount_PST__c,
                Tax_Amount_HST__c,
                Tax_Amount_QST__c,
                Tax_Rate_GST__c,
                Tax_Rate_PST__c,
                Tax_Rate_HST__c,
                Tax_Rate_QST__c,
                Tax_Rate__c,
                SO_Net_Terms__c
            FROM varcpq__Sales_Order__c
            WHERE Id = :invoice.varcpq__Sales_Order__c
            LIMIT 1
        ];

        // Load Customer Notes related to Sales Order
        customerNotes = new List<NoteWrapper>();
        for (Custom_Note__c note : [
            SELECT Id, Note_Type__c, Compose_Text__c
            FROM Custom_Note__c
            WHERE (Sales_Order__c = :salesOrder.Id OR Invoice__c = :invoice.Id)
            AND Note_Type__c IN ('Customer Facing - Shipping', 'Customer Facing - Billing','Customer Notes') // Apexify -- Surya -- Added 'Customer Notes' filter
            ORDER BY Note_Type__c
        ]) {
            customerNotes.add(new NoteWrapper(note));
        }

        // Load related Opportunity
        opportunity = [
            SELECT Id, Name, StageName, CloseDate, Amount, AccountId, OwnerId
            FROM Opportunity
            WHERE Id = :salesOrder.varcpq__Opportunity__c
            LIMIT 1
        ];

        // Load related Account
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
            WHERE Id = :opportunity.AccountId
            LIMIT 1
        ];

        // Load shipment tracking information from new object
        shipmentTracking = [
        SELECT 
            Id,
            Purchase_Order__r.Name,
            Asset__r.Parent.Product2.Name,
            Asset__r.Parent.varcpq__Sales_Order__r.Id,
            Asset__r.varcpq__Sales_Order__r.Id,
            Asset__r.varcpq__Sales_Order__r.varcpq__SO_Number__c,
            Asset__r.Product2.Name,
            Asset__r.SerialNumber,
            Shipping_Method__c,
            Ship_Date__c,
            Tracking_Number__c
        FROM Shipment_Tracking__c
        WHERE Asset__r.varcpq__Sales_Order__r.Id = :salesOrder.Id or Asset__r.Parent.varcpq__Sales_Order__r.Id = :salesOrder.Id
    ];

        // Load shipping and asset tracking information
        // Commented as part of #84 ASN by Vishnu S on 6/Jan/26
        /*shippingAndAssetTracking = [
            SELECT 
                Id, 
                Name, 
                Part_Number__c, 
                Account_Payable_Invoice_Line_Item__c, 
                Accounts_Payable_Invoice__c, 
                Shipping_Method__c, 
                Tracking_Number__c, 
                Ship_Date__c, 
                Serial_Numbers__c, 
                Invoice_ID__c, 
                Sales_Order_Record_ID__c 
            FROM Shipping_and_Asset_Tracking__c 
            WHERE Invoice_ID__c = :recordId
        ];*/

        // New code to handle invoice groups
        Map<Id, Invoice_Group__c> groupsMap = new Map<Id, Invoice_Group__c>(
            [SELECT Id, Name, Sequence__c, Sub_Total__c
             FROM Invoice_Group__c 
             WHERE Invoice__c = :recordId 
             ORDER BY Sequence__c ASC]
        );
        System.debug('Invoice groups: ' + groupsMap);

        // Initialize group collections
        invoiceGroups = new List<InvoiceGroup>();
        ungroupedItems = new List<varcpq__Invoice_Line_Item__c>();
        Map<Id, InvoiceGroup> invoiceGroupMap = new Map<Id, InvoiceGroup>();

        // Create InvoiceGroup objects for each group
        for (Invoice_Group__c groupRecord : groupsMap.values()) {
            if (groupRecord.Name != 'Untitled') { // Skip "Untitled" groups
                InvoiceGroup ig = new InvoiceGroup(groupRecord);
                invoiceGroups.add(ig);
                invoiceGroupMap.put(groupRecord.Id, ig);
            }
        }

        // Determine if we should show groups (more than one group that isn't "Untitled")
        hasMultipleGroups = invoiceGroups.size() > 0;

        // Organize line items into their respective groups
        for (varcpq__Invoice_Line_Item__c item : lineItems) {
            if (item.Invoice_Group__c != null && invoiceGroupMap.containsKey(item.Invoice_Group__c)) {
                invoiceGroupMap.get(item.Invoice_Group__c).lineItems.add(item);
            } else {
                ungroupedItems.add(item);
            }
        }

        // Calculate totals for each group
        for (InvoiceGroup groupWrapper : invoiceGroups) {
            groupWrapper.calculateTotals();
        }

        // Sort groups by sequence
        invoiceGroups.sort();
        
        // Group shipping data
        groupShippingData();
    }

    private void groupShippingData() {
        Map<String, ShippingTrackingWrapper> groupedMap = new Map<String, ShippingTrackingWrapper>();
        
        // Process Shipping_and_Asset_Tracking__c records
        // Commented as part of #84 ASN by Vishnu S on 6/Jan/26
        /*if (shippingAndAssetTracking != null) {
            for (Shipping_and_Asset_Tracking__c track : shippingAndAssetTracking) {
                String partNum = track.Part_Number__c != null ? track.Part_Number__c : '';
                String shipMethod = track.Shipping_Method__c != null ? track.Shipping_Method__c : '';
                String trackNum = track.Tracking_Number__c != null ? track.Tracking_Number__c : '';
                Date shipDt = track.Ship_Date__c;
                String serials = track.Serial_Numbers__c != null ? track.Serial_Numbers__c : '';
                
                ShippingTrackingWrapper wrapper = new ShippingTrackingWrapper(partNum, shipMethod, trackNum, shipDt, serials);
                String key = wrapper.getGroupKey();
                
                if (groupedMap.containsKey(key)) {
                    // Append serial numbers if not already empty
                    if (String.isNotBlank(serials)) {
                        String existing = groupedMap.get(key).serialNumbers;
                        if (String.isNotBlank(existing)) {
                            groupedMap.get(key).serialNumbers = existing + ', ' + serials;
                        } else {
                            groupedMap.get(key).serialNumbers = serials;
                        }
                    }
                } else {
                    groupedMap.put(key, wrapper);
                }
            }
        }*/
        
        // Process Shipment_Tracking__c records
        if (shipmentTracking != null) {
            for (Shipment_Tracking__c track : shipmentTracking) {
                // Use Asset__r.Product2.Name if available, otherwise use parent
                String partNum = String.isNotBlank(track.Asset__r.Product2.Name) 
                    ? track.Asset__r.Product2.Name 
                    : (track.Asset__r.Parent.Product2.Name != null ? track.Asset__r.Parent.Product2.Name : '');
                String shipMethod = track.Shipping_Method__c != null ? track.Shipping_Method__c : '';
                String trackNum = track.Tracking_Number__c != null ? track.Tracking_Number__c : '';
                Date shipDt = track.Ship_Date__c;
                String serials = track.Asset__r.SerialNumber != null ? track.Asset__r.SerialNumber : '';
                
                ShippingTrackingWrapper wrapper = new ShippingTrackingWrapper(partNum, shipMethod, trackNum, shipDt, serials);
                String key = wrapper.getGroupKey();
                
                if (groupedMap.containsKey(key)) {
                    // Append serial numbers if not already empty
                    if (String.isNotBlank(serials)) {
                        String existing = groupedMap.get(key).serialNumbers;
                        if (String.isNotBlank(existing)) {
                            groupedMap.get(key).serialNumbers = existing + ', ' + serials;
                        } else {
                            groupedMap.get(key).serialNumbers = serials;
                        }
                    }
                } else {
                    groupedMap.put(key, wrapper);
                }
            }
        }
        
        groupedShippingData = groupedMap.values();
    }

    @AuraEnabled
    public static ContentVersion generateAndSavePDF(Id invoiceId) {
        return savePDFToRecord(invoiceId);
    }

    @AuraEnabled
    public static void generateAndEmailPDF(
        Id invoiceId,
        List<String> toAddresses
    ) {
        EmailTemplate emailtemplate = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = 'Supplier_PO_Email_Template'
        ];
        if (emailTemplate != null) {
            emailPDF(invoiceId, toAddresses, emailTemplate.Id);
        }
    }
     
    //Commented below method by Surya on 14/11/2025 for "P6 - Customer Notes Formatting Lost When Generating PDF"
/*
    // Helper method to split description text into 30-character chunks
    private List<String> splitDescription(String description) {
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