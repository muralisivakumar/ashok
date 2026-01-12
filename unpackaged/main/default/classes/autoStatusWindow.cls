public class autoStatusWindow {
    @AuraEnabled
    public static Map<String, Object> getRecordStatus(String recordId){
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            String objectType = recordId.substring(0,3);
            if(objectType == '0Q0') { // Quote
                Quote record = [SELECT Id, Status, Quote_PDF_Count__c FROM Quote WHERE Id = :recordId];
                result.put('showPopup', (record.Status == 'Approved' && record.Quote_PDF_Count__c >= 1));
                result.put('objectType', 'Quote');
            } 
            else if(objectType == 'a1M') { // Sales Order - adjust prefix as needed
                varcpq__Sales_Order__c record = [SELECT Id, varcpq__Stage__c, SalesOrder_Email_Sent__c, 
                                               Sales_Order_PDF_Count__c FROM varcpq__Sales_Order__c 
                                               WHERE Id = :recordId];
                result.put('showPopup', (record.varcpq__Stage__c == 'Send Sales Order to Customer' 
                                       && !record.SalesOrder_Email_Sent__c 
                                       && record.Sales_Order_PDF_Count__c > 0));
                result.put('objectType', 'SalesOrder');
            }
        } catch(Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static void updateStatus(String recordId){
        String objectType = recordId.substring(0,3);
        
        if(objectType == '0Q0') {
            Quote record = [SELECT Id, Status, Quote_PDF_Count__c FROM Quote WHERE Id = :recordId];
            if(record.Status == 'Approved' && record.Quote_PDF_Count__c >= 1) {
                record.Status = 'Presented';
                update record;
            }
        } 
        else if(objectType == 'a1M') {
            varcpq__Sales_Order__c record = [SELECT Id, varcpq__Stage__c, SalesOrder_Email_Sent__c, 
                                           Sales_Order_PDF_Count__c FROM varcpq__Sales_Order__c 
                                           WHERE Id = :recordId];
            if(record.varcpq__Stage__c == 'Send Sales Order to Customer' 
               && !record.SalesOrder_Email_Sent__c 
               && record.Sales_Order_PDF_Count__c > 0) {
                record.varcpq__Stage__c = 'Pending PO Creation';
                record.SalesOrder_Email_Sent__c = true;
                update record;
            }
        }
    }
}