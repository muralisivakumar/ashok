public class SalesOrderStatusClass {

  @AuraEnabled
    public static String changeSoStatus(Id salesOrderId){
        varcpq__Sales_Order__c SO = [SELECT ID,varcpq__Stage__c FROM varcpq__Sales_Order__c WHERE Id =: salesOrderId ];
        
        if(SO.varcpq__Stage__c == 'Send Sales Order to Customer'){
          SO.varcpq__Stage__c = 'Pending PO Creation';
        }
        
        UPDATE SO;
        RETURN 'Record Updated Succesfully';
    }
}