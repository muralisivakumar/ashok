/***************************************************************************************************************************************************************************************
* @description       : Controller Class for ApiToPoLineTrigger and APayLineToPoLineTrigger To Make POLI Available again to add ON API After APLI and API deletion.
* @author            : Aress Software - AS
* @Created date      : 06/5/2025
* @related class     : -
* @test Class        : - APLIHandlerTest
* @last modified on  : - 03/05/2025
* @last modified by  : - 
****************************************************************************************************************************************************************************************/

public class APLIHandler { 

    public static void updateQuantity(List<varcpq__Account_Payable_Invoice_Line_Item__c>ApliList){
        SET<ID>poliSet = new SET<ID>();
        for(varcpq__Account_Payable_Invoice_Line_Item__c APLI : ApliList){
            poliSet.add(APLI.varcpq__Purchase_Order_Line_Item__c);
        }
        system.debug('poliSet======>'+poliSet);
        
        //Get All the API Line Items Related To POli Except the Triggering API Line Item
        List<varcpq__Account_Payable_Invoice_Line_Item__c> extApliList = [SELECT ID,varcpq__Purchase_Order_Line_Item__c,varcpq__Quantity_Invoiced__c,varcpq__Ext_Unit_Cost__c,
                                                                         varcpq__Purchase_Order_Line_Item__r.varcpq__AP_Line_Total_Quantity__c,
                                                                         varcpq__Purchase_Order_Line_Item__r.varcpq__AP_Line_Total_Amount__c
                                                                         FROM varcpq__Account_Payable_Invoice_Line_Item__c WHERE varcpq__Purchase_Order_Line_Item__c
                                                                         IN : poliSet]; 
        System.debug('extApliList======>'+extApliList);
        Map<Id,Decimal> poliAplineQuantity = new Map<Id,Decimal>();
        Map<Id,Decimal> poliAplineAmount = new Map<Id,Decimal>();

        if(!extApliList.isEmpty()){
        for(varcpq__Account_Payable_Invoice_Line_Item__c apli : extApliList){
            //Map of POLI Vs Sum of All the related APLI Vendor invoice Quantity
            if(!poliAplineQuantity.containsKey(apli.varcpq__Purchase_Order_Line_Item__c ) ||!poliAplineAmount.containsKey(apli.varcpq__Purchase_Order_Line_Item__c)){ 
               poliAplineQuantity.put(apli.varcpq__Purchase_Order_Line_Item__c,apli.varcpq__Quantity_Invoiced__c);
               poliAplineAmount.put(apli.varcpq__Purchase_Order_Line_Item__c, apli.varcpq__Ext_Unit_Cost__c);
            }
            else{
                //if Map Contains POLI then gets its existing Sum and add to current quantity to it
               poliAplineQuantity.put(apli.varcpq__Purchase_Order_Line_Item__c,poliAplineQuantity.get(apli.varcpq__Purchase_Order_Line_Item__c)+apli.varcpq__Quantity_Invoiced__c);
               poliAplineAmount.put(apli.varcpq__Purchase_Order_Line_Item__c,poliAplineAmount.get(apli.varcpq__Purchase_Order_Line_Item__c)+apli.varcpq__Ext_Unit_Cost__c);
            }
        }
        }
        
        System.debug('poliAplineQuantity Map ==========>'+poliAplineQuantity);
        List<varcpq__Purchase_Order_Line_Item__c> poliList = [SELECT ID,varcpq__AP_Line_Total_Quantity__c,varcpq__AP_Line_Total_Amount__c FROM varcpq__Purchase_Order_Line_Item__c
                                                             WHERE ID IN : poliSet];
        List<varcpq__Purchase_Order_Line_Item__c>  poListToUpdate = new List<varcpq__Purchase_Order_Line_Item__c>();
        for(varcpq__Purchase_Order_Line_Item__c poli : poliList ){
            if(poliAplineQuantity.containsKey(poli.Id)){
               poli.varcpq__AP_Line_Total_Quantity__c = poliAplineQuantity.get(poli.Id); 
               poli.varcpq__AP_Line_Total_Amount__c = poliAplineAmount.get(poli.Id); 
               poListToUpdate.add(poli);
            }
            else{
               poli.varcpq__AP_Line_Total_Quantity__c = 0;// POLI for which extApliList was empty does not get added to map so Update Those POLI To 0
               poli.varcpq__AP_Line_Total_Amount__c = 0;// POLI for which extApliList was empty does not get added to map so Update Those POLI To 0
                 poListToUpdate.add(poli);
            }
        }
        if(!poListToUpdate.isEmpty()){
            System.debug('poListToUpdate==========>'+poListToUpdate);
           Update poListToUpdate; 
        }
        
    }
    Public static void updateQuantityOnUpdate(List<varcpq__Account_Payable_Invoice_Line_Item__c>ApliList,Map<Id,varcpq__Account_Payable_Invoice_Line_Item__c>ApliOldMap){
      
           SET<ID>poliSet = new SET<ID>();
        for(varcpq__Account_Payable_Invoice_Line_Item__c APLI : ApliList){
            if(APLI.varcpq__Quantity_Invoiced__c != ApliOldMap.get(APLI.Id).varcpq__Quantity_Invoiced__c ||APLI.varcpq__Ext_Unit_Cost__c != ApliOldMap.get(APLI.Id).varcpq__Ext_Unit_Cost__c){
             poliSet.add(APLI.varcpq__Purchase_Order_Line_Item__c);
            }
          
        }
        system.debug('poliSet======>'+poliSet);
        
        //Get All the API Line Items Related To POli Except the Triggering API Line Item
        List<varcpq__Account_Payable_Invoice_Line_Item__c> extApliList = [SELECT ID,varcpq__Purchase_Order_Line_Item__c,varcpq__Quantity_Invoiced__c,varcpq__Ext_Unit_Cost__c,
                                                                         varcpq__Purchase_Order_Line_Item__r.varcpq__AP_Line_Total_Quantity__c,
                                                                         varcpq__Purchase_Order_Line_Item__r.varcpq__AP_Line_Total_Amount__c
                                                                         FROM varcpq__Account_Payable_Invoice_Line_Item__c WHERE varcpq__Purchase_Order_Line_Item__c
                                                                         IN : poliSet]; 
        System.debug('extApliList======>'+extApliList);
        Map<Id,Decimal> poliAplineQuantity = new Map<Id,Decimal>();
        Map<Id,Decimal> poliAplineAmount = new Map<Id,Decimal>();
        if(!extApliList.isEmpty()){
        for(varcpq__Account_Payable_Invoice_Line_Item__c apli : extApliList){
            //Map of POLI Vs Sum of All the related APLI Vendor invoice Quantity
            if(!poliAplineQuantity.containsKey(apli.varcpq__Purchase_Order_Line_Item__c) ||!poliAplineAmount.containsKey(apli.varcpq__Purchase_Order_Line_Item__c)){ 
               poliAplineQuantity.put(apli.varcpq__Purchase_Order_Line_Item__c,apli.varcpq__Quantity_Invoiced__c);
               poliAplineAmount.put(apli.varcpq__Purchase_Order_Line_Item__c, apli.varcpq__Ext_Unit_Cost__c);

            }
            else{
                //if Map Contains POLI then gets its existing Sum and add to current quantity to it
               poliAplineQuantity.put(apli.varcpq__Purchase_Order_Line_Item__c,poliAplineQuantity.get(apli.varcpq__Purchase_Order_Line_Item__c)+apli.varcpq__Quantity_Invoiced__c);
               poliAplineAmount.put(apli.varcpq__Purchase_Order_Line_Item__c,poliAplineAmount.get(apli.varcpq__Purchase_Order_Line_Item__c)+apli.varcpq__Ext_Unit_Cost__c);

            }
        }
        }
        
        System.debug('poliAplineQuantity Map ==========>'+poliAplineQuantity);
        List<varcpq__Purchase_Order_Line_Item__c> poliList = [SELECT ID,varcpq__AP_Line_Total_Quantity__c,varcpq__AP_Line_Total_Amount__c FROM varcpq__Purchase_Order_Line_Item__c
                                                             WHERE ID IN : poliSet];
        List<varcpq__Purchase_Order_Line_Item__c>  poListToUpdate = new List<varcpq__Purchase_Order_Line_Item__c>();
        for(varcpq__Purchase_Order_Line_Item__c poli : poliList ){
            if(poliAplineQuantity.containsKey(poli.Id)){
               poli.varcpq__AP_Line_Total_Quantity__c = poliAplineQuantity.get(poli.Id);
                poli.varcpq__AP_Line_Total_Amount__c = poliAplineAmount.get(poli.Id); 
               poListToUpdate.add(poli);
            }
            else{
               poli.varcpq__AP_Line_Total_Quantity__c = 0;// POLI for which extApliList was empty does not get added to map so Update Those POLI To 0
                poli.varcpq__AP_Line_Total_Amount__c = 0;// POLI for which extApliList was empty does not get added to map so Update Those POLI To 0
                 poListToUpdate.add(poli);
            }
        }
        if(!poListToUpdate.isEmpty()){
            System.debug('poListToUpdate==========>'+poListToUpdate);
           Update poListToUpdate; 
        }  
        
        
        
        
    }
}