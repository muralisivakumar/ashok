public class SalesOrderRefUpdate {
    public static void updateReference (Map<Id,Map<String,Id>> referenceMap,List<varcpq__Sales_Order__c> salesOrders){
        
        set<Id> addressIds = new set<Id>();
        set<Id> conIds = new set<Id>();
        for(Id soId: referenceMap.keySet()){
            if(referenceMap.get(soId).containskey('varcpq__Shipping_Address__c')){
                addressIds.add(referenceMap.get(soId).get('varcpq__Shipping_Address__c'));
            }
            if(referenceMap.get(soId).containskey('varcpq__Billing_Address__c')){
                addressIds.add(referenceMap.get(soId).get('varcpq__Billing_Address__c'));
            }
            if(referenceMap.get(soId).containskey('varcpq__Shipping_Contact__c')){
                conIds.add(referenceMap.get(soId).get('varcpq__Shipping_Contact__c'));
            }
            if(referenceMap.get(soId).containskey('varcpq__Billing_Contact__c')){
                conIds.add(referenceMap.get(soId).get('varcpq__Billing_Contact__c'));
            }
        }
        Map<Id,varcpq__Customer_Address__c> addressMap = new Map<Id,varcpq__Customer_Address__c>();
        if(!addressIds.isEmpty()){
        	addressMap = new Map<Id,varcpq__Customer_Address__c>([SELECT Id,Name,varcpq__City__c,varcpq__State__c,varcpq__Street__c,varcpq__Additional_Street__c,varcpq__Zipcode__c,Country__c,Company_Name__c
                                                                                                  FROM varcpq__Customer_Address__c
                                                                                                  WHERE Id = :addressIds]);
        }
        Map<Id,contact> conMap = new Map<Id,contact>();
        if(!conIds.isEmpty()){
        	conMap = new Map<Id,contact>([Select Id,Name,Email,Phone FROM Contact WHERE Id=:conIds]);
        }
        for(varcpq__Sales_Order__c newSO : salesOrders){
            if(referenceMap.get(newSO.Id).containskey('varcpq__Shipping_Address__c')){
                newSO.varcpq__Shipping_Street__c = addressMap.get(newSO.varcpq__Shipping_Address__c).varcpq__Street__c;
                newSO.Shipping_Additional_Street__c = addressMap.get(newSO.varcpq__Shipping_Address__c).varcpq__Additional_Street__c;
                newSO.varcpq__Shipping_City__c = addressMap.get(newSO.varcpq__Shipping_Address__c).varcpq__City__c;
                newSO.varcpq__Shipping_State__c = addressMap.get(newSO.varcpq__Shipping_Address__c).varcpq__State__c;
                newSO.Shipping_Country__c = addressMap.get(newSO.varcpq__Shipping_Address__c).Country__c;
                newSO.varcpq__Shipping_Zip__c = addressMap.get(newSO.varcpq__Shipping_Address__c).varcpq__Zipcode__c;
                newSO.Shipping_Company__c = addressMap.get(newSO.varcpq__Shipping_Address__c).Company_Name__c;
            }
            if(referenceMap.get(newSO.Id).containskey('varcpq__Billing_Address__c')){
                newSO.varcpq__Billing_Street__c = addressMap.get(newSO.varcpq__Billing_Address__c).varcpq__Street__c;
                newSO.Billing_Additional_Street__c = addressMap.get(newSO.varcpq__Billing_Address__c).varcpq__Additional_Street__c;
                newSO.varcpq__Billing_City__c = addressMap.get(newSO.varcpq__Billing_Address__c).varcpq__City__c;
                newSO.varcpq__Billing_State__c = addressMap.get(newSO.varcpq__Billing_Address__c).varcpq__State__c;
                newSO.Billing_Country__c = addressMap.get(newSO.varcpq__Billing_Address__c).Country__c;
                newSO.varcpq__Billing_Zip__c = addressMap.get(newSO.varcpq__Billing_Address__c).varcpq__Zipcode__c;
                newSO.Billing_Company__c = addressMap.get(newSO.varcpq__Billing_Address__c).Company_Name__c;
            }
            if(referenceMap.get(newSO.Id).containskey('varcpq__Shipping_Contact__c')){
                newSO.shipping_contact_name__c = conMap.get(newSO.varcpq__Shipping_Contact__c).name;
                newSO.Shipping_Email__c = conMap.get(newSO.varcpq__Shipping_Contact__c).email;
                newSO.Shipping_Phone__c = conMap.get(newSO.varcpq__Shipping_Contact__c).phone;
            }
            if(referenceMap.get(newSO.Id).containskey('varcpq__Billing_Contact__c')){
                newSO.Billing_contact_name__c = conMap.get(newSO.varcpq__Billing_Contact__c).name;
                newSO.Billing_Email__c = conMap.get(newSO.varcpq__Billing_Contact__c).email;
                newSO.Billing_Phone__c = conMap.get(newSO.varcpq__Billing_Contact__c).phone;
            }
            System.debug('newSO '+newSO);
        }
        
    }
}