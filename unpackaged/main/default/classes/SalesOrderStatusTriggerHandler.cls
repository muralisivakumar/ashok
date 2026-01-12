public class SalesOrderStatusTriggerHandler {
    public void run() {
        if (Trigger.isUpdate) {
            System.debug('trigger.new so '+Trigger.new);
            handleBeforeUpdate(
                (List<varcpq__Sales_Order__c>) Trigger.new,
                (Map<Id, varcpq__Sales_Order__c>) Trigger.oldMap
            );
        }
    }
    
    public void handleBeforeUpdate(
        List<varcpq__Sales_Order__c> newSalesOrders,
        Map<Id, varcpq__Sales_Order__c> oldSalesOrderMap
    ) {
        // Skip if running from PO confirmation
        if (TriggerExecutionContext.getIsRunningFromPOConfirmation()) {
            return;
        }
        
        for (varcpq__Sales_Order__c so : newSalesOrders) {
            varcpq__Sales_Order__c oldSO = oldSalesOrderMap.get(so.Id);
            
            Decimal totalAmount =
                (so.varcpq__Total_Purchase_Order_Amount__c != null
                 ? so.varcpq__Total_Purchase_Order_Amount__c
                 : 0) +
                (so.varcpq__Total_Margin__c != null ? so.varcpq__Total_Margin__c : 0);
            
            // Get payment and grand total values with null safety
            Decimal totalPayments = so.Total_Customer_Invoice_Payments__c != null 
                ? so.Total_Customer_Invoice_Payments__c 
                : 0;
            Decimal grandTotal = so.Grand_Total__c != null 
                ? so.Grand_Total__c 
                : 0;
            
            // Store old stage to track transitions
            String oldStage = oldSO.varcpq__Stage__c;
            
            // Check payment stages first (highest priority as they're latest in the lifecycle)
            if (grandTotal > 0 && totalPayments >= grandTotal) {
                // Fully paid
                so.varcpq__Stage__c = 'Paid';
            } else if (grandTotal > 0 && totalPayments > 0) {
                // Partially paid
                so.varcpq__Stage__c = 'Partially Paid';
            } else if (
                so.varcpq__Total_Purchase_Order_Amount__c != null &&
                so.varcpq__Total_Purchase_Order_Amount__c != 0
            ) {
                // Original logic for non-payment stages
                if (
                    so.varcpq__Total_Invoice_AmountNew__c != null &&
                    so.varcpq__Total_Invoice_AmountNew__c >=
                    so.varcpq__Total_Expected_Revenue__c &&
                    so.Total_Number_of_Units__c == so.varcpq__Total_Units_Shipped__c
                ) {
                    so.varcpq__Stage__c = 'Shipped/Assets Created';
                } else if (
                    so.varcpq__Total_Invoice_AmountNew__c != null &&
                    so.varcpq__Total_Invoice_AmountNew__c >=
                    so.varcpq__Total_Expected_Revenue__c
                ) {
                    so.varcpq__Stage__c = 'Invoices Created';
                } else if (
                    totalAmount >= so.varcpq__Total_Expected_Revenue__c &&
                    so.varcpq__Stage__c != 'POs Confirmed'
                ) {
                    so.varcpq__Stage__c = 'POs Created';
                }
            }
            
            // Update Order_Fully_Paid_Date__c based on stage transition
            if (so.varcpq__Stage__c == 'Paid' && oldStage != 'Paid') {
                // Moving into Paid stage - set date
                so.Order_Fully_Paid_Date__c = Date.today();
            } else if (so.varcpq__Stage__c != 'Paid' && oldStage == 'Paid') {
                // Moving out of Paid stage - clear date
                so.Order_Fully_Paid_Date__c = null;
            }
            
            // Update Order_Fully_Shipped__c based on PO shipping status
            if (so.Total_Number_of_Units__c != null && 
                so.Total_Number_of_Units__c > 0 && 
                so.Number_of_POs_Fully_Shipped__c != null &&
                so.Number_of_POs_Fully_Shipped__c > 0 && 
                (so.Number_of_POs_Not_Fully_Shipped__c == null || 
                 so.Number_of_POs_Not_Fully_Shipped__c == 0)) {
                so.Order_Fully_Shipped__c = true;
            } else {
                so.Order_Fully_Shipped__c = false;
            }
        }
    }
}