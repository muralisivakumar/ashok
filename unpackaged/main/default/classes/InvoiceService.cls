public class InvoiceService {
    public static void getAccountPayableInvoiceToInvoiceMap(List<varcpq__Invoice_line_item__c> invoiceLineItems) {
        try{
            System.debug('invoiceLineItems '+invoiceLineItems);        
            Map<Id, Id> apiToInvoiceMap = new Map<Id, Id>();
            Set<Id> invoiceIds = new Set<Id>();
            
            /*for (varcpq__Invoice__c inv : invoices) {
invoiceIds.add(inv.Id);
}*/
            for(varcpq__invoice_line_item__c invLine : invoiceLineItems){
                invoiceIds.add(invLine.varcpq__invoice__c);
            }
            System.debug('invoiceIds '+invoiceIds);
            // Step 1: Collect Sales Order Line Items per Invoice
            Map<Id, Set<Id>> invoiceToSolis = new Map<Id, Set<Id>>();
            /*for (varcpq__invoice_line_item__c line : [
SELECT varcpq__Invoice__c, varcpq__sales_order_line_item__c
FROM varcpq__invoice_line_item__c
WHERE varcpq__Invoice__c IN :invoiceIds
]) {
if (!invoiceToSolis.containsKey(line.varcpq__Invoice__c)) {
invoiceToSolis.put(line.varcpq__Invoice__c, new Set<Id>());
}
invoiceToSolis.get(line.varcpq__Invoice__c).add(line.varcpq__sales_order_line_item__c);
}*/
            for (varcpq__invoice_line_item__c line : invoiceLineItems) {
                if (!invoiceToSolis.containsKey(line.varcpq__Invoice__c)) {
                    invoiceToSolis.put(line.varcpq__Invoice__c, new Set<Id>());
                }
                invoiceToSolis.get(line.varcpq__Invoice__c).add(line.varcpq__sales_order_line_item__c);
            }
            System.debug('invoiceToSolis '+invoiceToSolis);
            
            // Step 2: Get all APIs under same Sales Orders with their related SOLIs
            List<varcpq__Accounts_Payable_Invoice__c> allApis = [
                SELECT Id, Sales_Order__c,
                (SELECT Id, varcpq__Purchase_Order_Line_Item__r.varcpq__sales_order_line_item__c
                 FROM varcpq__Account_Payable_Invoice_Line_Items__r)
                FROM varcpq__Accounts_Payable_Invoice__c
                WHERE Sales_Order__c IN (
                    SELECT varcpq__Sales_Order__c FROM varcpq__Invoice__c WHERE Id IN :invoiceIds
                )
            ];
            System.debug('allapis '+allapis);
            // Step 3: Match APIs to Invoice by shared SOLIs
            /*for (varcpq__Invoice__c inv : invoices) {
Set<Id> invSolis = invoiceToSolis.get(inv.Id);
if (invSolis == null || invSolis.isEmpty()) continue;

for (varcpq__Accounts_Payable_Invoice__c api : allApis) {
for (varcpq__account_payable_invoice_line_item__c apiLine : api.varcpq__Account_Payable_Invoice_Line_Items__r) {
Id apiSoli = apiLine.varcpq__Purchase_Order_Line_Item__r?.varcpq__sales_order_line_item__c;
if (invSolis.contains(apiSoli)) {
apiToInvoiceMap.put(api.Id, inv.Id);
break; // one match is enough
}
}
}
}*/
            
            for (Id invId : invoiceIds) {
                Set<Id> invSolis = invoiceToSolis.get(invId);
                if (invSolis == null || invSolis.isEmpty()) continue;
                
                for (varcpq__Accounts_Payable_Invoice__c api : allApis) {
                    for (varcpq__account_payable_invoice_line_item__c apiLine : api.varcpq__Account_Payable_Invoice_Line_Items__r) {
                        Id apiSoli = apiLine.varcpq__Purchase_Order_Line_Item__r?.varcpq__sales_order_line_item__c;
                        if (invSolis.contains(apiSoli)) {
                            apiToInvoiceMap.put(api.Id, invId);
                            break; // one match is enough
                        }
                    }
                }
            }
            List<varcpq__Accounts_Payable_Invoice__c> apiList = new List<varcpq__Accounts_Payable_Invoice__c>();
            for(Id apiId : apiToInvoiceMap.keyset()){
                varcpq__Accounts_Payable_Invoice__c api = new varcpq__Accounts_Payable_Invoice__c();
                api.Id = apiId;
                api.Invoice__c = apiToInvoiceMap.get(apiId);
                apiList.add(api);
            }
            system.debug('apiToInvoiceMap '+apiToInvoiceMap);
            if(!apiList.isEmpty()){
            	update apiList;
            }
            System.debug('apiList '+apiList);
            //return apiToInvoiceMap;
        }catch(exception ex){
            system.debug('exc '+ex);
        }
    }
}