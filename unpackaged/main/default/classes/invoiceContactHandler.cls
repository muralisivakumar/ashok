public class invoiceContactHandler {
    public static void handleSOtoInvoiceContact(List<varcpq__Invoice__c> invList){
        Set<Id> soIds = new Set<Id>();
        for(varcpq__Invoice__c invoice:invList){
            soIds.add(invoice.varcpq__Sales_order__c);
        }
        //Map<Id,varcpq__Sales_order__c> invSoMap = new Map<Id,varcpq__Sales_order__c>(); // Map of id(invoice) and its related sales order
        Map<Id,varcpq__Sales_order__c> soMap = new Map<Id,varcpq__Sales_order__c>(
            [SELECT Id, varcpq__Billing_City__c,Shipping_Additional_Street__c,Billing_Additional_Street__c, varcpq__Billing_State__c, varcpq__Billing_Street__c, varcpq__Billing_Zip__c, 
             varcpq__Shipping_City__c, varcpq__Shipping_State__c, varcpq__Shipping_Street__c, varcpq__Shipping_Zip__c, 
             Billing_Company__c, Billing_Email__c, Shipping_Company__c, Shipping_Email__c, Billing_Contact_Name__c, 
             Billing_Country__c, Billing_Phone__c, Shipping_Contact_Name__c, Shipping_Country__c, Shipping_Phone__c 
             FROM varcpq__Sales_Order__c
             WHERE Id=:soIds]);
        for(varcpq__Invoice__c invoice:invList){
            invoice.Bill_to_Name__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Contact_Name__c;
            invoice.Bill_to_Email__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Email__c;
            invoice.Bill_to_Phone__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Phone__c;
            
            invoice.Bill_to_Street__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Billing_Street__c;
            invoice.Bill_to_City__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Billing_City__c;
            invoice.Bill_to_State__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Billing_State__c;
            invoice.Bill_to_Country__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Country__c;
            invoice.Bill_to_zipcode__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Billing_Zip__c;
            invoice.Bill_to_Company_Name__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Company__c; 
            invoice.Bill_to_Additional_Street__c = soMap.get(invoice.varcpq__Sales_Order__c).Billing_Additional_Street__c;
            
            
            invoice.Ship_to_Name__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Contact_Name__c;
            invoice.Ship_to_Email__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Email__c;
            invoice.Ship_to_Phone__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Phone__c;
            
            invoice.Ship_to_Street__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Shipping_Street__c;
            invoice.Ship_to_City__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Shipping_City__c;
            invoice.Ship_to_State__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Shipping_State__c;
            invoice.Ship_to_Country__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Country__c;
            invoice.Ship_to_zipcode__c = soMap.get(invoice.varcpq__Sales_Order__c).varcpq__Shipping_Zip__c;
            invoice.Ship_to_Company_Name__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Company__c;
            invoice.Ship_to_Additional_Street__c = soMap.get(invoice.varcpq__Sales_Order__c).Shipping_Additional_Street__c;
        }
        System.debug('Trigger new updated '+invList);
    }
}