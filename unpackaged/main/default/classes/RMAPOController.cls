public with sharing class RMAPOController {

   @AuraEnabled(cacheable=true)
    public static List<varcpq__Purchase_Order__c> getPORecords(String poNumber) {
        if (String.isBlank(poNumber)) {
            return new List<varcpq__Purchase_Order__c>();
        }

        poNumber = poNumber.trim().toLowerCase();

        if (!poNumber.startsWith('po-')) {
            poNumber = 'po-' + poNumber;
        }

        return [
            SELECT Id, Name, CreatedDate, varcpq__PO_Status__c, varcpq__Ship_To_Account__c, varcpq__Ship_To_Account__r.Name,
            varcpq__Sales_Order__c, varcpq__Sales_Order__r.Name
            FROM varcpq__Purchase_Order__c
            WHERE Name LIKE :('%' + poNumber + '%')
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }


    @AuraEnabled(cacheable=true)
    public static List<InvoiceWrapper> getInvoicesByPOIds(List<Id> poIds) {
        if (poIds == null || poIds.isEmpty()) {
            return new List<InvoiceWrapper>();
        }

        List<InvoiceWrapper> results = new List<InvoiceWrapper>();

        // Step 1: Fetch Purchase Order Lines
        List<varcpq__Purchase_Order_Line_Item__c> poLines = [
            SELECT Id, varcpq__Purchase_Order__c, varcpq__Sales_Order_Line_Item__c
            FROM varcpq__Purchase_Order_Line_Item__c
            WHERE varcpq__Purchase_Order__c IN :poIds
        ];

        if (poLines.isEmpty()) {
            return results;
        }

        // Step 2: Collect Sales Order Line Ids
        Set<Id> soLineIds = new Set<Id>();
        for (varcpq__Purchase_Order_Line_Item__c pol : poLines) {
            if (pol.varcpq__Sales_Order_Line_Item__c != null) {
                soLineIds.add(pol.varcpq__Sales_Order_Line_Item__c);
            }
        }

        if (soLineIds.isEmpty()) {
            return results;
        }

        // Step 3: Fetch Invoice Line Items related to those SO Lines
        List<varcpq__Invoice_Line_Item__c> invoiceLines = [
            SELECT Id, Name, varcpq__Invoice__c, varcpq__Quantity__c, varcpq__Ext_Total__c, 
                varcpq__Part_No__c, Return_Quantity__c, Return_Amount__c, Distributor__r.Name, varcpq__Total_Cost__c,varcpq__Description__c,
                varcpq__Sales_Order_Line_Item__c
            FROM varcpq__Invoice_Line_Item__c
            WHERE varcpq__Sales_Order_Line_Item__c IN :soLineIds
        ];

        if (invoiceLines.isEmpty()) {
            return results;
        }

        // Step 4: Collect Invoice Ids
        Set<Id> invoiceIds = new Set<Id>();
        for (varcpq__Invoice_Line_Item__c ili : invoiceLines) {
            if (ili.varcpq__Invoice__c != null) {
                invoiceIds.add(ili.varcpq__Invoice__c);
            }
        }

        // Step 5: Fetch Invoices
        Map<Id, varcpq__Invoice__c> invoiceMap = new Map<Id, varcpq__Invoice__c>(
            [SELECT Id, Name, varcpq__Status__c, varcpq__Client__c, Grand_Total__c
            FROM varcpq__Invoice__c
            WHERE Id IN :invoiceIds]
        );

        // Step 6: Group invoice lines by invoice
        Map<Id, List<InvoiceLineItemWrapper>> invoiceLineMap = new Map<Id, List<InvoiceLineItemWrapper>>();
        for (varcpq__Invoice_Line_Item__c ili : invoiceLines) {
            if (!invoiceLineMap.containsKey(ili.varcpq__Invoice__c)) {
                invoiceLineMap.put(ili.varcpq__Invoice__c, new List<InvoiceLineItemWrapper>());
            }
            invoiceLineMap.get(ili.varcpq__Invoice__c).add(new InvoiceLineItemWrapper(ili));
        }

        // Step 7: Wrap results
        for (Id invId : invoiceMap.keySet()) {
            varcpq__Invoice__c inv = invoiceMap.get(invId);
            InvoiceWrapper wrap = new InvoiceWrapper(inv);
            wrap.LineItems = invoiceLineMap.containsKey(invId) ? invoiceLineMap.get(invId) : new List<InvoiceLineItemWrapper>();
            results.add(wrap);
        }

        System.debug('Invoices found: ' + results.size());
        return results;
    }


    
    @AuraEnabled
    public static List<varcpq__Invoice_Line_Item__c> updateInvoiceLineItems(List<varcpq__Invoice_Line_Item__c> lineItems) {
        List<varcpq__Invoice_Line_Item__c> updatedLines = new List<varcpq__Invoice_Line_Item__c>();

        if (lineItems == null || lineItems.isEmpty()) return updatedLines;

        // Bulk query existing invoice lines
        Set<Id> lineIds = new Set<Id>();
        for (varcpq__Invoice_Line_Item__c li : lineItems) {
            if (li.Id != null) lineIds.add(li.Id);
        }

        Map<Id, varcpq__Invoice_Line_Item__c> dbLines = new Map<Id, varcpq__Invoice_Line_Item__c>(
            [SELECT Id, varcpq__Quantity__c, varcpq__Unit_Price__c,varcpq__Description__c,varcpq__Total_Cost__c, Return_Quantity__c, Return_Amount__c, Remaining_Quantity__c
            FROM varcpq__Invoice_Line_Item__c
            WHERE Id IN :lineIds]
        );

        for (varcpq__Invoice_Line_Item__c li : lineItems) {
            varcpq__Invoice_Line_Item__c dbLine = dbLines.get(li.Id);
            if (dbLine == null) continue;

            Decimal jsReturnQty = li.Return_Quantity__c != null ? li.Return_Quantity__c : 0;
            Decimal unitPrice = dbLine.varcpq__Unit_Price__c != null ? dbLine.varcpq__Unit_Price__c : 0;

            // Calculate remaining quantity safely
            Decimal remainingQty = dbLine.varcpq__Quantity__c - jsReturnQty;
            if (remainingQty < 0) {
                remainingQty = 0;
                System.debug('Warning: JS sent return quantity greater than original quantity for LineItem: ' + li.Id);
            }

            // Update dbLine directly from JS
            dbLine.Return_Quantity__c = jsReturnQty;
            dbLine.Remaining_Quantity__c = remainingQty;
            dbLine.Return_Amount__c = jsReturnQty * unitPrice;

            System.debug('Updating InvoiceLine: ' + dbLine.Id +
                        ', OriginalQty: ' + dbLine.varcpq__Quantity__c +
                        ', JSReturnQty: ' + jsReturnQty +
                        ', RemainingQty: ' + remainingQty +
                        ', ReturnAmount: ' + dbLine.Return_Amount__c);

            updatedLines.add(dbLine);
        }

        if (!updatedLines.isEmpty()) {
            update updatedLines;
        }

        return updatedLines;
    }
    @AuraEnabled
    public static void myApexMethod() {
        Id loggedInUserId = UserInfo.getUserId();
        System.debug('Current User ID: ' + loggedInUserId);
    }

    @AuraEnabled
    public static List<Id> createRMAWithLines(
        Map<Id, List<ReturnLineWrapper>> invoiceLineMap, 
        String rmaType, 
        Id poId,
        List<Id> uploadedFileIds,
        String creditMemoNumber

    ) {
        System.debug('Uploaded File IDs from LWC: ' + uploadedFileIds);

        List<Id> createdRMAIds = new List<Id>();

        // Fetch invoices in bulk
        Map<Id, varcpq__Invoice__c> invoices = new Map<Id, varcpq__Invoice__c>(
            [SELECT Id, varcpq__Client__c, varcpq__PO_Number__c, varcpq__Sales_Order__c, CurrencyIsoCode
             FROM varcpq__Invoice__c
             WHERE Id IN :invoiceLineMap.keySet()]
        );
    
        // Fetch invoice lines in bulk
        Map<Id, varcpq__Invoice_Line_Item__c> allInvoiceLines = new Map<Id, varcpq__Invoice_Line_Item__c>(
            [SELECT Id, Product__c, varcpq__Unit_Price__c, varcpq__Quantity__c, varcpq__Invoice__c, CurrencyIsoCode,Distributor__r.Name,
                    Return_Quantity__c, Return_Amount__c, Remaining_Quantity__c, varcpq__Sales_Order_Line_Item__c, 
                    Distributor__c, varcpq__Description__c,varcpq__Total_Cost__c
             FROM varcpq__Invoice_Line_Item__c
             WHERE varcpq__Invoice__c IN :invoiceLineMap.keySet()]
        );
    
        // Fetch Purchase Order info
        varcpq__Purchase_Order__c po = [
            SELECT Id, varcpq__Distributor_Name__c 
            FROM varcpq__Purchase_Order__c 
            WHERE Id = :poId
            LIMIT 1
        ];
    
        List<Return_Merchandise_Authorization__c> rmasToInsert = new List<Return_Merchandise_Authorization__c>();
        List<Return_Merchandise_Authorization_Line_It__c> rmaLinesToInsert = new List<Return_Merchandise_Authorization_Line_It__c>();
        List<varcpq__Invoice_Line_Item__c> linesToUpdate = new List<varcpq__Invoice_Line_Item__c>();
        Map<Id, Return_Merchandise_Authorization__c> invoiceIdToRMA = new Map<Id, Return_Merchandise_Authorization__c>();
    
        // Step 1: Create RMAs
        for (Id invId : invoiceLineMap.keySet()) {
            varcpq__Invoice__c inv = invoices.get(invId);
            if (inv == null) continue;
    
            Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
                Related_Invoice__c = inv.Id,
                Account__c = inv.varcpq__Client__c,
                CurrencyIsoCode = inv.CurrencyIsoCode,
                Related_Purchase_Order__c = po.Id,
                Supplier__c = po.varcpq__Distributor_Name__c,
                Related_Sales_Order__c = inv.varcpq__Sales_Order__c,
                Source__c = 'Manual',
                RMA_Type__c = rmaType,
                Status__c = 'Initiated',
                Credit_Memo__c = creditMemoNumber,
                Submitted_By__c = UserInfo.getUserId()
            );
            rmasToInsert.add(rma);
            invoiceIdToRMA.put(invId, rma);
        }
    
        insert rmasToInsert;

        // Link uploaded files to first RMA
        if (!uploadedFileIds.isEmpty() && !rmasToInsert.isEmpty()) {
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();

            for (Id docId : uploadedFileIds) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = rmasToInsert[0].Id, // or loop through and link to all if needed
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }

            insert links;
            System.debug('Linked files to RMA: ' + rmasToInsert[0].Id);
        }
    
        // Step 2: Create RMA lines & update invoice lines
        for (Id invId : invoiceLineMap.keySet()) {
            Return_Merchandise_Authorization__c rma = invoiceIdToRMA.get(invId);
            if (rma == null) continue;
    
            for (ReturnLineWrapper rl : invoiceLineMap.get(invId)) {
                varcpq__Invoice_Line_Item__c invLine = allInvoiceLines.get(rl.lineItemId);
                if (invLine == null) continue;
    
                Decimal jsReturnQty = rl.quantity != null ? rl.quantity : 0;
                Decimal prevReturned = invLine.Return_Quantity__c != null ? invLine.Return_Quantity__c : 0;
                Decimal unitPrice = invLine.varcpq__Unit_Price__c != null ? invLine.varcpq__Unit_Price__c : 0;
    
                // Total returned including previous RMAs
                Decimal totalReturned = prevReturned + jsReturnQty;
    
                // Safeguard remaining quantity
                Decimal remainingQty = invLine.varcpq__Quantity__c - totalReturned;
                if (remainingQty < 0) remainingQty = 0;
    
                // Update invoice line
                invLine.Return_Quantity__c = totalReturned;
                invLine.Remaining_Quantity__c = remainingQty;
                invLine.Return_Amount__c = totalReturned * unitPrice;
                invLine.Has_RMA__c = true;
                linesToUpdate.add(invLine);
    
                // Create RMA line
                rmaLinesToInsert.add(new Return_Merchandise_Authorization_Line_It__c(
                    Return_Merchandise_Authorization__c = rma.Id,
                    Invoice_Line_Reference__c = rl.lineItemId,
                    Quantity__c = jsReturnQty,
                    Product__c = invLine.Product__c,
                    CurrencyIsoCode = invLine.CurrencyIsoCode,
                    Unit_Price__c = unitPrice,
                    Total_Ext_Price__c = jsReturnQty * unitPrice,
                    Remaining_Quantity__c = remainingQty,
                    Returned_Quantity__c = totalReturned,
                    Return_Type__c = rl.returnType,
                    Reason__c = rl.reason,
                    Notes__c = rl.note,
                    Related_Sales_Order_Line_Item__c = invLine.varcpq__Sales_Order_Line_Item__c,
                    Distributor__c = invLine.Distributor__c
                ));
            }
            createdRMAIds.add(rma.Id);
        }
    
        if (!rmaLinesToInsert.isEmpty()) insert rmaLinesToInsert;
        if (!linesToUpdate.isEmpty()) update linesToUpdate;
    
        return createdRMAIds;
    }



    public class PurchaseOrderWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Status;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String SalesOrderName;
        @AuraEnabled public String RMAType;


        public PurchaseOrderWrapper(varcpq__Purchase_Order__c po) {
            this.Id = po.Id;
            this.Name = po.Name;
            this.Status = po.varcpq__PO_Status__c;
            this.AccountName = po.varcpq__Ship_To_Account__r != null ? po.varcpq__Ship_To_Account__r.Name : null;
            this.SalesOrderName = po.varcpq__Sales_Order__r != null ? po.varcpq__Sales_Order__r.Name : null;
            this.RMAType = null;
        }
    }

    
    public class InvoiceWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Decimal Total;
        @AuraEnabled public String Status;
        @AuraEnabled public List<InvoiceLineItemWrapper> LineItems;

        public InvoiceWrapper(varcpq__Invoice__c inv) {
            this.Id = inv.Id;
            this.Name = inv.Name;
            this.Total = inv.Grand_Total__c;
            this.Status = inv.varcpq__Status__c;
            this.LineItems = new List<InvoiceLineItemWrapper>();
        }
    }

   
    public class InvoiceLineItemWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Decimal Quantity;
        @AuraEnabled public Decimal Price;
        @AuraEnabled public Decimal Cost;
        @AuraEnabled public String Description;
        @AuraEnabled public String PartNo;
        @AuraEnabled public String Distributor;
        @AuraEnabled public Boolean isSelected { get; set; }
        @AuraEnabled public Decimal ReturnQuantity { get; set; }  // User input for this session
        @AuraEnabled public String ReturnType { get; set; }  
        @AuraEnabled public Decimal ReturnedQuantity { get; set; }  // Total returned including this session
        @AuraEnabled public Decimal RemainingQuantity { get; set; } // Quantity left
        @AuraEnabled public Decimal ReturnedQuantityFromApex { get; set; } // Total previously returned from DB
        @AuraEnabled public String Reason { get; set; } 

        public InvoiceLineItemWrapper(varcpq__Invoice_Line_Item__c item) {
            this.Id = item.Id;
            this.Name = item.Name;
            this.Cost = item.varcpq__Total_Cost__c;
            this.Description = item.varcpq__Description__c;
            this.Quantity = item.varcpq__Quantity__c != null ? item.varcpq__Quantity__c : 0;
            this.Price = item.varcpq__Ext_Total__c != null ? item.varcpq__Ext_Total__c : 0;
            this.PartNo = item.varcpq__Part_No__c;
            this.Distributor = item.Distributor__r.Name;

            this.isSelected = false;
            this.ReturnedQuantityFromApex = item.Return_Quantity__c != null ? item.Return_Quantity__c : 0; 
            this.ReturnQuantity = 0;  // User input
            this.ReturnedQuantity = this.ReturnedQuantityFromApex + this.ReturnQuantity; 
            this.RemainingQuantity = this.Quantity - this.ReturnedQuantity; 
            this.ReturnType = ''; 
            this.Reason = '';  
        }
    }

    public class ReturnLineWrapper {
        @AuraEnabled public String lineItemId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal returnedQuantity { get; set; } 
        @AuraEnabled public Decimal remainingQuantity { get; set; } 
        @AuraEnabled public String productId { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public String returnType { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public String note { get; set; }
        @AuraEnabled public Id purchaseOrderId { get; set; }
    }
}