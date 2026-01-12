public class rmaLineItemTriggerHandler {
    public static void handleAfterInsert(List<Return_Merchandise_Authorization_Line_It__c> newRmaLines) {
        System.debug('=== RMA Line Items Inserted === ' + newRmaLines);
 
        // Step 1: Filter only "Missing/Lost" RMAs with Invoice Line Item linked
        List<Return_Merchandise_Authorization_Line_It__c> missingLostRmas = new List<Return_Merchandise_Authorization_Line_It__c>();
        Set<Id> invoiceLineIds = new Set<Id>();
        for (Return_Merchandise_Authorization_Line_It__c rma : newRmaLines) {
            System.debug('Checking RMA Line Item: ' + rma.Id + ' | Type=' + rma.Return_Type__c + ' | InvoiceLineRef=' + rma.Invoice_Line_Reference__c);
            if (rma.Return_Type__c == 'Missing/Lost' && rma.Invoice_Line_Reference__c != null) {
                missingLostRmas.add(rma);
                invoiceLineIds.add(rma.Invoice_Line_Reference__c);
            }
        }
        System.debug('Filtered Missing/Lost RMAs: ' + missingLostRmas);
        System.debug('Collected Invoice Line Item Ids: ' + invoiceLineIds);
        if (missingLostRmas.isEmpty()) {
            System.debug('No Missing/Lost RMAs found. Exiting.');
            return;
        }
        // Step 2: Fetch related Invoice Line Items + Sales Order Line Items
        Map<Id, varcpq__Invoice_Line_Item__c> invoiceLineMap = new Map<Id, varcpq__Invoice_Line_Item__c>(
            [SELECT Id, varcpq__Sales_Order_Line_Item__c,
                    varcpq__Sales_Order_Line_Item__r.varcpq__Product__c,
                    varcpq__Sales_Order_Line_Item__r.varcpq__Total_Ext_Price__c,
                    varcpq__Sales_Order_Line_Item__r.varcpq__Quantity__c,
                    varcpq__Sales_Order_Line_Item__r.varcpq__Sales_Order__c
             FROM varcpq__Invoice_Line_Item__c
             WHERE Id IN :invoiceLineIds]
        );
        System.debug('Fetched Invoice Line Items: ' + invoiceLineMap);
        // Step 3: Prepare new Sales Order Line Items
        List<varcpq__Sales_Order_Line_Item__c> newSOLines = new List<varcpq__Sales_Order_Line_Item__c>();
 
        for (Return_Merchandise_Authorization_Line_It__c rma : missingLostRmas) {
            varcpq__Invoice_Line_Item__c invLine = invoiceLineMap.get(rma.Invoice_Line_Reference__c);
            System.debug('Processing RMA ' + rma.Id + ' | InvoiceLine=' + invLine);
 
            if (invLine == null || invLine.varcpq__Sales_Order_Line_Item__c == null) {
                System.debug('Skipping RMA ' + rma.Id + ' because InvoiceLine or SOLI is null');
                continue;
            }
            varcpq__Sales_Order_Line_Item__c origSO = invLine.varcpq__Sales_Order_Line_Item__r;
 
            // Clone sales order line item
            varcpq__Sales_Order_Line_Item__c newSO = new varcpq__Sales_Order_Line_Item__c();
            newSO.varcpq__Sales_Order__c = origSO.varcpq__Sales_Order__c;
            newSO.varcpq__Product__c = origSO.varcpq__Product__c;
          	newSO.varcpq__DO_NOT_INVOICE__c = TRUE;
            // Override quantity & amount from RMA Line Item
            newSO.varcpq__Quantity__c = rma.Quantity__c;
            newSO.varcpq__Unit_Price__c = rma.Unit_Price__c;
            newSO.varcpq__Distributor__c = rma.Distributor__c;
 
            System.debug('Cloned new SO Line Item (not inserted yet): ' + newSO);
 
            newSOLines.add(newSO);
        }
 
        System.debug('Prepared SO Line Items for insert: ' + newSOLines);
 
        if (!newSOLines.isEmpty()) {
            insert newSOLines;
            System.debug('Inserted new SO Line Items: ' + newSOLines);
        } else {
            System.debug('No SO Line Items prepared for insert.');
        }
    }
}