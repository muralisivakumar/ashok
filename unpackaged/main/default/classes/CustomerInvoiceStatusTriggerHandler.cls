// Handler Class
public class CustomerInvoiceStatusTriggerHandler {
    
    public static void handleAfterUpdate(List<varcpq__Invoice__c> newInvoices, Map<Id, varcpq__Invoice__c> oldInvoiceMap) {
        List<varcpq__Invoice__c> invoicesToUpdate = new List<varcpq__Invoice__c>();
        
        for (varcpq__Invoice__c newInvoice : newInvoices) {
            varcpq__Invoice__c oldInvoice = oldInvoiceMap.get(newInvoice.Id);
			System.debug('new balance '+newInvoice.Invoice_Balance__c+' old balance '+oldInvoice.Invoice_Balance__c);
			System.debug('new invoice values G'+newInvoice.Grand_Total__c + ' T:'+newInvoice.Total_Payments__c+' B:'+newInvoice.Invoice_Balance__c);
			System.debug('old invoice values G'+oldInvoice.Grand_Total__c + ' T:'+oldInvoice.Total_Payments__c+' B:'+oldInvoice.Invoice_Balance__c);           
            // Check if Invoice_Balance__c has changed
            if (newInvoice.Invoice_Balance__c != oldInvoice.Invoice_Balance__c) {
                
                varcpq__Invoice__c invoiceToUpdate = new varcpq__Invoice__c(Id = newInvoice.Id);
                Boolean needsUpdate = false;
                
                // If balance is 0 and status is not already 'Paid', update to 'Paid' and set Date Paid
                if (newInvoice.Invoice_Balance__c == 0 && newInvoice.varcpq__Status__c != 'Paid') {
                    invoiceToUpdate.varcpq__Status__c = 'Paid';
                    invoiceToUpdate.varcpq__Date_Paid__c = Date.today();
                    needsUpdate = true;
                }
                // If balance is greater than 0 and status is 'Paid', update to 'Issued' and clear Date Paid
                else if (newInvoice.Invoice_Balance__c > 0 && newInvoice.varcpq__Status__c == 'Paid') {
                    invoiceToUpdate.varcpq__Status__c = 'Issued';
                    invoiceToUpdate.varcpq__Date_Paid__c = null;
                    needsUpdate = true;
                }
                
                if (needsUpdate) {
                    invoicesToUpdate.add(invoiceToUpdate);
                }
            }
        }
        
        // Update records if there are any changes
        if (!invoicesToUpdate.isEmpty()) {
            // Disable trigger to prevent recursion
            CustomerInvoiceStatusTriggerHelper.skipTrigger = true;
            
            try {
                update invoicesToUpdate;
            } catch (Exception e) {
                System.debug('Error updating invoice status: ' + e.getMessage());
                // Handle error appropriately - could throw custom exception or add error to records
                for (varcpq__Invoice__c invoice : newInvoices) {
                    invoice.addError('Failed to update invoice status: ' + e.getMessage());
                }
            } finally {
                CustomerInvoiceStatusTriggerHelper.skipTrigger = false;
            }
        }
    }
    
    // Method for testing - allows injection of mock invoice data
    /*@TestVisible
    private static void handleAfterUpdateWithMockData(
        List<varcpq__Invoice__c> newInvoices, 
        Map<Id, varcpq__Invoice__c> oldInvoiceMap,
        Map<Id, Decimal> mockBalances,
        Map<Id, Decimal> mockOldBalances
    ) {
        List<varcpq__Invoice__c> invoicesToUpdate = new List<varcpq__Invoice__c>();
        
        for (varcpq__Invoice__c newInvoice : newInvoices) {
            varcpq__Invoice__c oldInvoice = oldInvoiceMap.get(newInvoice.Id);
            
            // Use mock balances if provided (for testing), otherwise use actual
            Decimal newBalance = mockBalances != null && mockBalances.containsKey(newInvoice.Id) 
                ? mockBalances.get(newInvoice.Id) 
                : newInvoice.Invoice_Balance__c;
            
            Decimal oldBalance = mockOldBalances != null && mockOldBalances.containsKey(oldInvoice.Id)
                ? mockOldBalances.get(oldInvoice.Id)
                : oldInvoice.Invoice_Balance__c;
            
            // Check if balance has changed
            if (newBalance != oldBalance) {
                varcpq__Invoice__c invoiceToUpdate = new varcpq__Invoice__c(Id = newInvoice.Id);
                Boolean needsUpdate = false;
                
                // If balance is 0 and status is not already 'Paid', update to 'Paid'
                if (newBalance == 0 && newInvoice.varcpq__Status__c != 'Paid') {
                    invoiceToUpdate.varcpq__Status__c = 'Paid';
                    invoiceToUpdate.varcpq__Date_Paid__c = Date.today();
                    needsUpdate = true;
                }
                // If balance is greater than 0 and status is 'Paid', update to 'Issued'
                else if (newBalance > 0 && newInvoice.varcpq__Status__c == 'Paid') {
                    invoiceToUpdate.varcpq__Status__c = 'Issued';
                    invoiceToUpdate.varcpq__Date_Paid__c = null;
                    needsUpdate = true;
                }
                
                if (needsUpdate) {
                    invoicesToUpdate.add(invoiceToUpdate);
                }
            }
        }
        
        // Update records if there are any changes
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }*/
}