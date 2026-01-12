/***************************************************************************************************************************************************************************************
* @description       : Trigger Handler for getting default BillTo/ShipTo Address and Contacts. Additional, Controller for quoteFieldsDefaulter LWC.
* @author            : Aress Software - AS
* @Created date      : 26/12/2024
* @related class     : - 
* @test Class        : - 
* @last modified on  : - 07/01/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class quoteFieldsUpdate {
    public static void getBillShipDefault(List<Quote> quotelist){
        set<id> oppIds = new Set<Id>();
        for(Quote qt:quoteList){
            oppIds.add(qt.OpportunityId);
        }
        Set<Id> accIds = new Set<Id>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id,AccountId FROM Opportunity WHERE Id=:oppIds]);
        
        for(Id oppId:oppIds){
            accIds.add(oppMap.get(oppId).accountId);
        }
        //System.debug('accIds '+accIds);
        List<Contact> conList = [SELECT Id,Name,Email,AccountId,Default_Billing_Contact__c, Default_Shipping_Contact__c, Active__c,Phone FROM Contact
                                 WHERE AccountId =:accIds AND Active__c = true AND (Default_Shipping_Contact__c = true OR Default_Billing_Contact__c = true) ];
        List<varcpq__customer_address__c> addList =  [SELECT Id,varcpq__City__c, varcpq__Customer__c, varcpq__State__c, varcpq__Street__c, varcpq__Zipcode__c, varcpq__Full_Address__c, Default_Billing_Address__c, Default_Shipping_Address__c, Country__c, 
                                                      Name, varcpq__Additional_Street__c, varcpq__Active__c,Company_Name__c FROM varcpq__Customer_Address__c WHERE varcpq__Customer__c =: accIds AND varcpq__Active__c = true AND (Default_Billing_Address__c = true OR Default_Shipping_Address__c = true)];
        //System.debug('conlist '+conlist);
        //System.debug('addList '+addList);
        Map<Id,Contact> defShipConMap = new Map<Id,Contact>();
        Map<Id,Contact> defBillConMap = new Map<Id,Contact>();
        
        Map<Id,varcpq__customer_address__c> defShipAddMap = new Map<Id,varcpq__customer_address__c>();
        Map<Id,varcpq__customer_address__c> defBillAddMap = new Map<Id,varcpq__customer_address__c>();
        for(contact con:conList){
            if(!defShipConMap.containsKey(con.accountId) && con.Default_Shipping_Contact__c){
                defShipConMap.put(con.AccountId,con);
                
            }
            if(!defBillConMap.containsKey(con.accountId) && con.Default_Billing_Contact__c){
                defBillConMap.put(con.AccountId,con);    
            }            
        }
        for(varcpq__customer_address__c add: addList){
            if(!defShipAddMap.containsKey(add.varcpq__Customer__c) && add.Default_Shipping_Address__c){
                defShipAddMap.put(add.varcpq__Customer__c,add);
            }
            if(!defBillAddMap.containsKey(add.varcpq__Customer__c) && add.Default_Billing_Address__c){
                defBillAddMap.put(add.varcpq__Customer__c,add);
            }
        }
        
        List<Quote> newQuoteList = new List<Quote>();
        for(Quote quote :quoteList){
            
            if(defBillConMap.containsKey(oppMap.get(quote.OpportunityId).accountId) && defBillConMap.get(oppMap.get(quote.OpportunityId).accountId)!=null){
                quote.BillingName = defBillConMap.get(oppMap.get(quote.OpportunityId).accountId).Name;
                quote.Bill_to_email__c = defBillConMap.get(oppMap.get(quote.OpportunityId).accountId).email;
                quote.Bill_to_phone__c =defBillConMap.get(oppMap.get(quote.OpportunityId).accountId).Phone;
                System.debug('bill email'+quote.Bill_to_email__c);
                System.debug('bill phone'+quote.Bill_to_phone__c);
            }
            if(defShipConMap.containsKey(oppMap.get(quote.OpportunityId).accountId) && defShipConMap.get(oppMap.get(quote.OpportunityId).accountId)!=null){
                quote.ShippingName = defShipConMap.get(oppMap.get(quote.OpportunityId).accountId).Name;
                quote.Ship_to_email__c = defShipConMap.get(oppMap.get(quote.OpportunityId).accountId).email;
                quote.Ship_to_phone__c =defShipConMap.get(oppMap.get(quote.OpportunityId).accountId).Phone;
                //System.debug('Ship email'+quote.Ship_to_email__c);
            }
            if(defShipAddMap.containsKey(oppMap.get(quote.OpportunityId).accountId) && defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId)!=null){
                /*String additionalStreet = '';
                if (!String.isBlank(defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Additional_Street__c)) {
                    additionalStreet = ', '+defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Additional_Street__c;
                }*/
                quote.ShippingStreet = defShipAddMap.get(oppMap.get(quote.OpportunityId).AccountId).varcpq__Street__c;
                quote.ShippingAdditionalStreet__c = defShipAddMap.get(oppMap.get(quote.OpportunityId).AccountId).varcpq__Additional_Street__c;
                quote.ShippingCity = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__City__c;
                quote.ShippingState = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__State__c;
                quote.ShippingPostalCode = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Zipcode__c;
                quote.ShippingCountry = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).Country__c;
                quote.Ship_Customer_Address_Id__c = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).Id;
                quote.Ship_To_Company__c = defShipAddMap.get(oppMap.get(quote.OpportunityId).accountId).Company_Name__c;
            }
            if(defBillAddMap.containsKey(oppMap.get(quote.OpportunityId).accountId) && defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId)!=null){
                System.debug('defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId) '+defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId));
                /*String additionalStreet = '';
                if (!String.isBlank(defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Additional_Street__c)) {
                    additionalStreet = ', '+defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Additional_Street__c;
                }*/
                quote.BillingStreet = defBillAddMap.get(oppMap.get(quote.OpportunityId).AccountId).varcpq__Street__c;
                quote.BillingAdditionalStreet__c = defBillAddMap.get(oppMap.get(quote.OpportunityId).AccountId).varcpq__Additional_Street__c;
                quote.BillingCity = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__City__c;
                quote.BillingState = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__State__c;
                quote.BillingPostalCode = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).varcpq__Zipcode__c;
                quote.BillingCountry = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).Country__c;
                quote.Bill_Customer_Address_Id__c = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).Id;
                quote.Bill_To_Company__c = defBillAddMap.get(oppMap.get(quote.OpportunityId).accountId).Company_Name__c;
            }
            
            newQuoteList.add(quote);
        }
        System.debug('newQuoteList '+newQuoteList);
        //update newQuoteList;
        
    }
    
    @AuraEnabled 
    public static Quote getConAdds(Id quoteId){
        
        Quote quote = [SELECT Id, Name, BillingStreet,BillingAdditionalStreet__c, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                       ShippingStreet,ShippingAdditionalStreet__c, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, BillingName, ShippingName, 
                       Bill_to_email__c, Ship_to_email__c,Ship_to_company__c,bill_to_company__c,Bill_to_phone__c,Ship_to_phone__c FROM Quote WHERE Id=:quoteId];
        if(quote.Id!=null){
            return quote;
        }
        return null;
        
    }
    
    @AuraEnabled
    public static void updateConAdds(Id quoteId,String shipAdd, String shipCon, String billAdd, String billCon){
        conAddWrapper shipAddWrap = (conAddWrapper)JSON.deserialize(shipAdd,conAddWrapper.class);
        conAddWrapper shipConWrap = (conAddWrapper)JSON.deserialize(shipCon,conAddWrapper.class);
        conAddWrapper billAddWrap = (conAddWrapper)JSON.deserialize(billAdd,conAddWrapper.class);
        conAddWrapper billConWrap = (conAddWrapper)JSON.deserialize(billCon,conAddWrapper.class);
        System.debug('Id '+quoteId);
        System.debug('shipAddWrap '+shipAddWrap);
        System.debug('shipConWrap '+shipConWrap);
        System.debug('billAddWrap '+billAddWrap);
        System.debug('billConWrap '+billConWrap);
        
        Quote quote = new Quote();
        quote.Id = quoteId;
        
        if(shipAddWrap.recId !=null){
            varcpq__customer_address__c shipAddress =  [SELECT Id,varcpq__City__c, varcpq__Customer__c, varcpq__State__c, varcpq__Street__c, varcpq__Zipcode__c, varcpq__Full_Address__c, Default_Billing_Address__c, Default_Shipping_Address__c, Country__c, 
                                                        Name, varcpq__Additional_Street__c, varcpq__Active__c,Company_Name__c 
                                                        FROM varcpq__Customer_Address__c 
                                                        WHERE Id=:shipAddWrap.recId];
            /*String additionalStreet = '';
            if (!String.isBlank(shipAddress.varcpq__Additional_Street__c)) {
            additionalStreet = ', ' + shipAddress.varcpq__Additional_Street__c;
            }*/
            quote.ShippingStreet = shipAddress.varcpq__Street__c;
			quote.ShippingAdditionalStreet__c = shipAddress.varcpq__Additional_Street__c;
            //quote.ShippingStreet = shipAddress.varcpq__Street__c;
            quote.ShippingCity = shipAddress.varcpq__City__c;
            quote.ShippingState = shipAddress.varcpq__State__c;
            quote.ShippingPostalCode = shipAddress.varcpq__Zipcode__c;
            quote.ShippingCountry = shipAddress.Country__c;
            quote.Ship_Customer_Address_Id__c = shipAddress.Id;
            quote.Ship_To_Company__c = shipAddress.Company_Name__c;
            
        }
        if(billAddWrap.recId !=null){
            varcpq__customer_address__c billAddress =  [SELECT Id,varcpq__City__c, varcpq__Customer__c, varcpq__State__c, varcpq__Street__c, varcpq__Zipcode__c, varcpq__Full_Address__c, Default_Billing_Address__c, Default_Shipping_Address__c, Country__c, 
                                                        Name, varcpq__Additional_Street__c, varcpq__Active__c,Company_Name__c
                                                        FROM varcpq__Customer_Address__c 
                                                        WHERE Id=:billAddWrap.recId];
             /*String additionalStreet = '';
            if (!String.isBlank(billAddress.varcpq__Additional_Street__c)) {
            additionalStreet = ', ' + billAddress.varcpq__Additional_Street__c;
            }*/
            quote.BillingAdditionalStreet__c = billAddress.varcpq__Additional_Street__c;
            quote.BillingStreet = billAddress.varcpq__Street__c;
            //quote.BillingStreet = billAddress.varcpq__Street__c;
            quote.BillingCity = billAddress.varcpq__City__c;
            quote.BillingState = billAddress.varcpq__State__c;
            quote.BillingPostalCode = billAddress.varcpq__Zipcode__c;
            quote.BillingCountry = billAddress.Country__c;
            quote.Bill_To_Company__c = billAddress.Company_Name__c;
            quote.Bill_Customer_Address_Id__c = billAddress.Id;
            
        }
        if(shipConWrap.recId != null){
            Contact shipContact = [SELECT Id,Name,Email,Phone FROM Contact WHERE Id=:shipConWrap.recId];
            quote.ShippingName = shipContact.Name;
            quote.Ship_to_email__c = shipContact.Email;
            quote.Ship_to_phone__c = shipContact.Phone;
        }
        if(billConWrap.recId != null){
            Contact billContact = [SELECT Id,Name,Email,Phone FROM Contact WHERE Id=:billConWrap.recId];
            quote.BillingName = billContact.Name;
            quote.Bill_to_email__c = billContact.Email;
            quote.Bill_to_phone__c = billContact.Phone; 
        }
        
        update quote;
        
    }
    public class conAddWrapper{
        @AuraEnabled public String recId;
        @AuraEnabled public String Name;
        @AuraEnabled public String email;
        @AuraEnabled public Boolean DefaultShip;
        @AuraEnabled public Boolean DefaultBill;
        @AuraEnabled public String Phone;
    }
}