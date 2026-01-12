public class RMATriggerHandler {
    
    // This method handles the RMA updates
    public static void updateShippingInfo(List<Return_Merchandise_Authorization__c> rmas) {
        
        // Collect Sales Order IDs from RMA records that have a Related Sales Order
        Set<Id> salesOrderIds = new Set<Id>();
        List<Return_Merchandise_Authorization__c> rmasToUpdate = new List<Return_Merchandise_Authorization__c>();
        
        // Step 1: Collect related Sales Order IDs
        for (Return_Merchandise_Authorization__c rma : rmas) {
            // Check if Related_Sales_Order__c field is populated
            if (rma.Related_Sales_Order__c != null) {
                salesOrderIds.add(rma.Related_Sales_Order__c);
            }
        }
        
        // Step 2: Query Sales Orders for shipping information if Sales Order IDs exist
        if (!salesOrderIds.isEmpty()) {
            
            Map<Id, varcpq__Sales_Order__c> salesOrderMap = new Map<Id, varcpq__Sales_Order__c>([
                SELECT Id, 
                       varcpq__Shipping_Address__c,
                       varcpq__Shipping_City__c, 
                       varcpq__Shipping_State__c,
                       varcpq__Shipping_Street__c,
                       varcpq__Shipping_Zip__c,
                       Shipping_Country__c,
                       CurrencyIsoCode
                FROM varcpq__Sales_Order__c 
                WHERE Id IN :salesOrderIds
            ]);
            
            // Step 3: Process each RMA record
            for (Return_Merchandise_Authorization__c rma : rmas) {
                // Skip if no related sales order
                if (rma.Related_Sales_Order__c == null) {
                    continue;
                }
                
                // Get the related Sales Order
                varcpq__Sales_Order__c salesOrder = salesOrderMap.get(rma.Related_Sales_Order__c);
                
                if (salesOrder != null) {
                    
                    // Check if we need to update (avoid unnecessary updates)
                    Boolean needsUpdate = false;
                    
                    // Create a copy of the RMA record for updates
                    Return_Merchandise_Authorization__c rmaToUpdate = new Return_Merchandise_Authorization__c();
                    rmaToUpdate.Id = rma.Id;
                    
                    // Step 4: Compare and update RMA fields based on Sales Order data
                    
                    // Copy Ship To City
                    if (rma.Ship_to_City__c != salesOrder.varcpq__Shipping_City__c) {
                        rmaToUpdate.Ship_to_City__c = salesOrder.varcpq__Shipping_City__c;
                        needsUpdate = true;
                    }
                    
                    // Copy Ship To State
                    if (rma.Ship_to_State__c != salesOrder.varcpq__Shipping_State__c) {
                        rmaToUpdate.Ship_to_State__c = salesOrder.varcpq__Shipping_State__c;
                        needsUpdate = true;
                    }
                    
                    // Copy Ship To Street
                    if (rma.Ship_to_Street__c != salesOrder.varcpq__Shipping_Street__c) {
                        rmaToUpdate.Ship_to_Street__c = salesOrder.varcpq__Shipping_Street__c;
                        needsUpdate = true;
                    }
                    
                    // Copy Ship To Country
                    if (rma.Ship_to_Country__c != salesOrder.Shipping_Country__c) {
                        rmaToUpdate.Ship_to_Country__c = salesOrder.Shipping_Country__c;
                        needsUpdate = true;
                    }
                    
                    // Copy Ship To Zipcode
                    if (rma.Ship_To_Zipcode__c != salesOrder.varcpq__Shipping_Zip__c) {
                        rmaToUpdate.Ship_To_Zipcode__c = salesOrder.varcpq__Shipping_Zip__c;
                        needsUpdate = true;
                    }
                    
                    // Copy Currency IsoCode
                    if (rma.CurrencyIsoCode != salesOrder.CurrencyIsoCode) {
                        rmaToUpdate.CurrencyIsoCode = salesOrder.CurrencyIsoCode;
                        needsUpdate = true;
                    }
                    
                    // Step 5: Add to update list if changes are needed
                    if (needsUpdate) {
                        rmasToUpdate.add(rmaToUpdate);
                    }
                }
            }
            
            // Step 6: Perform the updates if any records need updating
            if (!rmasToUpdate.isEmpty()) {
                try {
                    update rmasToUpdate;
                } catch (Exception e) {
                    // Handle any DML exceptions
                    System.debug('Error updating RMA records: ' + e.getMessage());
                    
                    // Add error to the first record in the trigger context
                    if (!rmas.isEmpty()) {
                        rmas[0].addError('Error copying shipping information from Sales Order: ' + e.getMessage());
                    }
                }
            }
        }
    }
    
   

    public static Boolean hasRunFuture = false;
    
    public static void createSupplierCrediMemo(List<Return_Merchandise_Authorization__c> rmaList){
        Set<Id> rmaIds = new Set<Id>();
        Set<Id> poIds = new Set<Id>();
        
        Set<Id> invoiceId = new Set<Id>();
        
        
        
        for (Return_Merchandise_Authorization__c rma : rmaList) {
            rmaIds.add(rma.Id);
            if (rma.Related_Purchase_Order__c != null) {
                poIds.add(rma.Related_Purchase_Order__c);
            }
        }
        Map<Id, Decimal> rmaToTotalCost = new Map<Id, Decimal>();
		Map<Id, Decimal> rmaToTotalPrice = new Map<Id, Decimal>();
        List<Return_Merchandise_Authorization_Line_It__c> lineItems = [
            SELECT Id, Return_Merchandise_Authorization__c, Total_Ext_Unit_Cost__c, Total_Ext_Unit_Price__c
            FROM Return_Merchandise_Authorization_Line_It__c
            WHERE Return_Merchandise_Authorization__c IN :rmaIds
        ];
        
        for (Return_Merchandise_Authorization_Line_It__c li : lineItems) {
            Decimal cost = li.Total_Ext_Unit_Cost__c != null ? li.Total_Ext_Unit_Cost__c : 0;
            Decimal price = li.Total_Ext_Unit_Price__c != null ? li.Total_Ext_Unit_Price__c : 0;
        
            rmaToTotalCost.put(li.Return_Merchandise_Authorization__c,
                rmaToTotalCost.get(li.Return_Merchandise_Authorization__c) == null
                ? cost : rmaToTotalCost.get(li.Return_Merchandise_Authorization__c) + cost);
        
            rmaToTotalPrice.put(li.Return_Merchandise_Authorization__c,
                rmaToTotalPrice.get(li.Return_Merchandise_Authorization__c) == null
                ? price : rmaToTotalPrice.get(li.Return_Merchandise_Authorization__c) + price);
        }
    
        List<varcpq__Invoice_Line_Item__c> invLI = [Select Id, varcpq__Ext_Total__c, varcpq__Total_Cost__c From varcpq__Invoice_Line_Item__c where varcpq__Invoice__c IN :invoiceId];
        System.debug('invLI: ' + invLI);
        
        Map<Id, Manual_Credit_Memo__c> existingMemos = new Map<Id, Manual_Credit_Memo__c>();
        for (Manual_Credit_Memo__c m : [
            SELECT Id, Return_Merchandise_Authorization__c 
            FROM Manual_Credit_Memo__c 
            WHERE Return_Merchandise_Authorization__c IN :rmaIds
        ]) {
            existingMemos.put(m.Return_Merchandise_Authorization__c, m);
        }
    
        // AP Invoice 
        Map<Id, varcpq__Accounts_Payable_Invoice__c> apInvoiceMap = new Map<Id, varcpq__Accounts_Payable_Invoice__c>();
        if (!poIds.isEmpty()) {
            for (varcpq__Accounts_Payable_Invoice__c apInv :
                [SELECT Id, Invoice__c, Invoice__r.varcpq__Client__c, varcpq__Supplier__c,
                        varcpq__Purchase_Order__c 
                 FROM varcpq__Accounts_Payable_Invoice__c 
                 WHERE varcpq__Purchase_Order__c IN :poIds]) {
                apInvoiceMap.put(apInv.varcpq__Purchase_Order__c, apInv);
            }
        }
    
        List<Manual_Credit_Memo__c> memosToInsert = new List<Manual_Credit_Memo__c>();
    
        for (Return_Merchandise_Authorization__c rma : rmaList) {
            if (existingMemos.containsKey(rma.Id)) {
                continue; 
            }
    
            // Supplier Credit memo 
            Manual_Credit_Memo__c suppMemo = new Manual_Credit_Memo__c();
            suppMemo.Return_Merchandise_Authorization__c = rma.Id;
           // suppMemo.Credit_Amount__c = rma.Total_Amount__c;
            suppMemo.Credit_Amount__c = rmaToTotalCost.containsKey(rma.Id) ? rmaToTotalCost.get(rma.Id) : 0;
            suppMemo.Invoice_Reference__c = rma.Related_Invoice__c;
            suppMemo.Customer_PO__c = rma.Related_Purchase_Order__r != null ? 
                                      rma.Related_Purchase_Order__r.Name : null;
            suppMemo.Credit_Memo_Type__c = 'Supplier';
            suppMemo.Reason_Code__c = rma.Reason_Code__c;
            suppMemo.CurrencyIsoCode = rma.CurrencyIsoCode;
            suppMemo.Credit_Memo__c = rma.Credit_Memo__c;
            suppMemo.Status__c = 'Draft';

            if (rma.Related_Purchase_Order__c != null &&
                apInvoiceMap.containsKey(rma.Related_Purchase_Order__c)) {
                suppMemo.Accounts_Payable_Invoice__c = apInvoiceMap.get(rma.Related_Purchase_Order__c).Id;
                suppMemo.Account__C = apInvoiceMap.get(rma.Related_Purchase_Order__c).varcpq__Supplier__c;
            }
    
            memosToInsert.add(suppMemo);
            
            System.debug('Memos to insert after supplier: ' + memosToInsert);
    
            // Customer Credit memo 
            Manual_Credit_Memo__c custMemo = new Manual_Credit_Memo__c();
            custMemo.Credit_Memo_Type__c = 'Customer';
            custMemo.Reason_Code__c = rma.Reason_Code__c;
           // custMemo.Credit_Amount__c = rma.Total_Amount__c;
           custMemo.Credit_Amount__c = rmaToTotalPrice.containsKey(rma.Id) ? rmaToTotalPrice.get(rma.Id) : 0;
            custMemo.Return_Merchandise_Authorization__c = rma.Id;
    		custMemo.CurrencyIsoCode = rma.CurrencyIsoCode;
            custMemo.Credit_Memo__c = rma.Credit_Memo__c;
            custMemo.Status__c = 'Draft';
            custMemo.Account__c = rma.Related_Invoice__r.varcpq__Client__c;
            custMemo.Invoice_Reference__c = rma.Related_Invoice__c;
            
            if (rma.Related_Purchase_Order__c != null &&
                apInvoiceMap.containsKey(rma.Related_Purchase_Order__c)) {
                varcpq__Accounts_Payable_Invoice__c apiRec = apInvoiceMap.get(rma.Related_Purchase_Order__c);
                custMemo.Accounts_Payable_Invoice__c = apiRec.Id;
                if (apiRec.Invoice__r != null) {
                    //custMemo.Account__c = apiRec.Invoice__r.varcpq__Client__c; 
                    //custMemo.Invoice_Reference__c = apiRec.Invoice__c;
                }
            }
    
            custMemo.Customer_PO__c = rma.Related_Purchase_Order__r != null ? 
                                      rma.Related_Purchase_Order__r.Name : null;
    
            memosToInsert.add(custMemo);
            System.debug('Memos to insert after customer: ' + memosToInsert);
        }
        
            if(!memosToInsert.isEmpty()){
                insert memosToInsert;
				System.debug('Memos inserted***' + memosToInsert);
                
                List<Manual_Credit_Memo__c> insertedMemos = [
                    SELECT Id, Return_Merchandise_Authorization__c, Credit_Memo_Type__c
                    FROM Manual_Credit_Memo__c
                    WHERE Id IN :memosToInsert
                ];
                updateRMALineItem(insertedMemos);
            
        }
    }
    
    public static void updateRMALineItem(List<Manual_Credit_Memo__c> manualCreditMemo){
        System.debug('Inside createRMALineItem: ' + manualCreditMemo);
    
        Set<Id> rmaIds = new Set<Id>();
        for (Manual_Credit_Memo__c mcc : manualCreditMemo) {
            if (mcc.Return_Merchandise_Authorization__c != null) {
                rmaIds.add(mcc.Return_Merchandise_Authorization__c);
            }
        }
    
        System.debug('rmaIds: ' + rmaIds);
    
        if (rmaIds.isEmpty()) {
            System.debug('No related RMAs found exiting.');
            return;
        }
    
        List<Return_Merchandise_Authorization_Line_It__c> rmaLineItems = [
            SELECT Id, Supplier_Credit_Memo_Applied__c, Credit_Memo_Applied__c, Return_Merchandise_Authorization__c, Unit_Cost__c,Quantity__c, Unit_Price__c
            FROM Return_Merchandise_Authorization_Line_It__c
            WHERE Return_Merchandise_Authorization__c IN :rmaIds
        ];
    
        System.debug('Fetched RMA Line Items: ' + rmaLineItems);
    
        Map<Id, Id> rmaToSupplierMemo = new Map<Id, Id>();
        Map<Id, Id> rmaToCustomerMemo = new Map<Id, Id>();
    
        for (Manual_Credit_Memo__c memo : manualCreditMemo) {
            if (memo.Return_Merchandise_Authorization__c != null) {
                if (memo.Credit_Memo_Type__c == 'Supplier') {
                    rmaToSupplierMemo.put(memo.Return_Merchandise_Authorization__c, memo.Id);
                } else if (memo.Credit_Memo_Type__c == 'Customer') {
                    rmaToCustomerMemo.put(memo.Return_Merchandise_Authorization__c, memo.Id);
                }
            }
        }
    
        List<Return_Merchandise_Authorization_Line_It__c> updates = new List<Return_Merchandise_Authorization_Line_It__c>();
    
        for (Return_Merchandise_Authorization_Line_It__c lineItem : rmaLineItems) {
            Boolean needsUpdate = false;
            Id rmaId = lineItem.Return_Merchandise_Authorization__c;
    
            if (rmaToSupplierMemo.containsKey(rmaId) && lineItem.Supplier_Credit_Memo_Applied__c != rmaToSupplierMemo.get(rmaId)) {
                lineItem.Supplier_Credit_Memo_Applied__c = rmaToSupplierMemo.get(rmaId);
                needsUpdate = true;
            }
            if (rmaToCustomerMemo.containsKey(rmaId) && lineItem.Credit_Memo_Applied__c != rmaToCustomerMemo.get(rmaId)) {
                lineItem.Credit_Memo_Applied__c = rmaToCustomerMemo.get(rmaId);
                needsUpdate = true;
            }
    
            if (needsUpdate) {
                updates.add(lineItem);
            }
        }
    	System.debug('line item to update: ' + updates);
        if (!updates.isEmpty()) {
            update updates;
            System.debug('Updated RMA Line Items with Supplier and Customer Credit Memos: ' + updates);
        } else {
            System.debug('No RMA Line Item updates needed.');
        }
    }
    
    
    @future
    public static void createSupplierCrediMemoFuture(List<Id> rmaIds) {
        List<Return_Merchandise_Authorization__c> rmas = [
            SELECT Id,
                   Total_Amount__c,
                   Reason_Code__c,
                   Related_Invoice__c,
                   Related_Purchase_Order__c,
            	   Related_Purchase_Order__r.Name,
            	   Related_Invoice__r.varcpq__Client__c,
            	   Credit_Memo__c,
            	   CurrencyIsoCode,
            		Status__C
            FROM Return_Merchandise_Authorization__c
            WHERE Id IN :rmaIds
        ];

        createSupplierCrediMemo(rmas);
    }
    
    public static void handleBeforeDelete(List<Return_Merchandise_Authorization__c> deletedRMA){
        System.debug('deletedRMA:+++' + deletedRMA);
        Set<Id> deletedId = new Set<Id>();
        
        for(Return_Merchandise_Authorization__c rma: deletedRMA){
            deletedId.add(rma.Id);
        }
        System.debug('deletedId***' + deletedId);
        
        List<Return_Merchandise_Authorization_Line_It__c> deletedRMALineIt = [Select Id,Quantity__c,Total_Ext_Price__c, Return_Merchandise_Authorization__r.Name, Invoice_Line_Reference__c,Invoice_Line_Reference__r.varcpq__Quantity__c, Returned_Quantity__c, Remaining_Quantity__c From Return_Merchandise_Authorization_Line_It__c where Return_Merchandise_Authorization__c In :deletedId and Invoice_Line_Reference__c != null];
        System.debug('oldRMALineIt:*** ' + deletedRMALineIt);
        
        Map<Id, Decimal> invLineToDeletedQty = new Map<Id, Decimal>();
        Map<Id, Decimal> invLineToDeletedAmount = new Map<Id, Decimal>();

        for (Return_Merchandise_Authorization_Line_It__c rmaLineItem : deletedRMALineIt) {
            Decimal qty = rmaLineItem.Quantity__c != null ? rmaLineItem.Quantity__c : 0;
            Decimal amt   = rmaLineItem.Total_Ext_Price__c != null ? rmaLineItem.Total_Ext_Price__c : 0;

            if (!invLineToDeletedQty.containsKey(rmaLineItem.Invoice_Line_Reference__c)) {
                invLineToDeletedQty.put(rmaLineItem.Invoice_Line_Reference__c, qty);
            } else {
                invLineToDeletedQty.put(
                    rmaLineItem.Invoice_Line_Reference__c,
                    invLineToDeletedQty.get(rmaLineItem.Invoice_Line_Reference__c) + qty
                );
            }
            
            if (!invLineToDeletedAmount.containsKey(rmaLineItem.Invoice_Line_Reference__c)) {
                invLineToDeletedAmount.put(rmaLineItem.Invoice_Line_Reference__c, amt);
            } else {
                invLineToDeletedAmount.put(
                    rmaLineItem.Invoice_Line_Reference__c,
                    invLineToDeletedAmount.get(rmaLineItem.Invoice_Line_Reference__c) + amt
                );
            }
        }
        System.debug('Invoice to deleted qty map: ' + invLineToDeletedQty);
        System.debug('Invoice to deleted amount map: ' + invLineToDeletedAmount);

        List<varcpq__Invoice_Line_Item__c> invLineItemsToUpdate = [
            SELECT Id, Return_Quantity__c, Remaining_Quantity__c, varcpq__Quantity__c, Return_Amount__c
            FROM varcpq__Invoice_Line_Item__c
            WHERE Id IN :invLineToDeletedQty.keySet()
        ];
    
        for (varcpq__Invoice_Line_Item__c inv : invLineItemsToUpdate) {
            Decimal totalQty = inv.varcpq__Quantity__c != null ? inv.varcpq__Quantity__c : 0;
            Decimal returnedQty = inv.Return_Quantity__c != null ? inv.Return_Quantity__c : 0;
            Decimal delQty = invLineToDeletedQty.get(inv.Id);
        	Decimal returnedAmt = inv.Return_Amount__c   != null ? inv.Return_Amount__c   : 0;
			Decimal delAmt = invLineToDeletedAmount.containsKey(inv.Id) ? invLineToDeletedAmount.get(inv.Id) : 0;

            inv.Return_Quantity__c = returnedQty - delQty;
            if (inv.Return_Quantity__c < 0) inv.Return_Quantity__c = 0;
        
            inv.Remaining_Quantity__c = totalQty - inv.Return_Quantity__c;
            if (inv.Remaining_Quantity__c < 0) inv.Remaining_Quantity__c = 0;
            
            inv.Return_Amount__c = returnedAmt - delAmt;
    		if (inv.Return_Amount__c < 0) inv.Return_Amount__c = 0;
        
            System.debug('Updating invoice ' + inv.Id + ' → Returned: ' + inv.Return_Quantity__c + ', Remaining: ' + inv.Remaining_Quantity__c + ',Return Amount: ' + inv.Return_Amount__c);
        }
        
        update invLineItemsToUpdate;
   		
        
        
        List<Manual_Credit_Memo__c> relatedMemos = [
            SELECT Id, Status__c, Credit_Memo_Type__c, Return_Merchandise_Authorization__c
            FROM Manual_Credit_Memo__c
            WHERE Return_Merchandise_Authorization__c IN :deletedId
        ];
        
        
        System.debug('relatedMemos:*** ' + relatedMemos);
        
        List<Manual_Credit_Memo__c> memosToDelete = new List<Manual_Credit_Memo__c>();

        for (Return_Merchandise_Authorization__c rma : deletedRMA) {
            Boolean blockDeletion = false;
        
            for (Manual_Credit_Memo__c memo : relatedMemos) {
                if (memo.Return_Merchandise_Authorization__c == rma.Id) {
                    if (memo.Status__c != 'Draft') {
                        blockDeletion = true;
                    } else {
                        memosToDelete.add(memo);
                    }
                }
            }
        
            if (blockDeletion) {
                rma.addError('You can’t delete this RMA because one or more related Credit Memos aren’t in Draft status.');
            }
        }
        
        if (!memosToDelete.isEmpty()) {
            delete memosToDelete;
        }
    
        /*if(!memosToDelete.isEmpty()){
            for (Manual_Credit_Memo__c memo : memosToDelete) {
            if (memo.Status__c != 'Draft') {
				for (Return_Merchandise_Authorization__c rma : deletedRMA) {
                    if (rma.Id == memo.Return_Merchandise_Authorization__c) {
                        rma.addError('You cannot delete this RMA because a related Credit Memo is not in Draft status.');
                    }
                }
           }
        }
            delete memosToDelete;
        }*/
    }
    
    /*public static void handleAfterUndelete(List<Return_Merchandise_Authorization__c> undeletedRma){
        System.debug('undeletedRma: ' + undeletedRma);
        
         Set<Id> undeletedRmaIds = new Set<Id>();
        for (Return_Merchandise_Authorization__c rma : undeletedRma) {
            undeletedRmaIds.add(rma.Id);
        }
    
        List<Manual_Credit_Memo__c> deletedMemos = [
            SELECT Id, Name, Return_Merchandise_Authorization__c, IsDeleted
            FROM Manual_Credit_Memo__c
            WHERE Return_Merchandise_Authorization__c IN :undeletedRmaIds
            AND IsDeleted = true
            ALL ROWS
        ];
    
        if (!deletedMemos.isEmpty()) {
            undelete deletedMemos;
        }
    }*/
    
}