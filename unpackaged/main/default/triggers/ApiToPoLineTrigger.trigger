trigger ApiToPoLineTrigger on varcpq__Accounts_Payable_Invoice__c (After Delete) {
    if(trigger.isAfter && trigger.isDelete){
        SET<Id> POSet = new SET<ID>();
        for(varcpq__Accounts_Payable_Invoice__c API : trigger.old){
            POSet.add(API.varcpq__Purchase_Order__c); // Get PO Related to SO
        }
        System.debug('POSet=======>'+POSet);
        
        //Get POLI which has APILI
        List<varcpq__Purchase_Order_Line_Item__c> POLINEList = [SELECT ID,varcpq__AP_Line_Total_Quantity__c,varcpq__AP_Line_Total_Amount__c,varcpq__Purchase_Order__c FROM varcpq__Purchase_Order_Line_Item__c
                                                                WHERE varcpq__Purchase_Order__c IN : POSet AND Id IN  
                                                                (SELECT varcpq__Purchase_Order_Line_Item__c FROM varcpq__Account_Payable_Invoice_Line_Item__c)];
        System.debug('POLINEList=======>'+POLINEList);
        
        SET<ID>polineSET = new SET<ID>();
        for(varcpq__Purchase_Order_Line_Item__c poli : POLINEList){
            polineSET.add(poli.Id);  
        }
        System.debug('polineSET=======>'+polineSET);
        List<varcpq__Account_Payable_Invoice_Line_Item__c> ApilineList =[SELECT ID,varcpq__Quantity_Invoiced__c,varcpq__Ext_Unit_Cost__c,varcpq__Purchase_Order_Line_Item__c
                                                                         FROM varcpq__Account_Payable_Invoice_Line_Item__c WHERE varcpq__Purchase_Order_Line_Item__c
                                                                         IN : polineSET ];
        System.debug('ApilineList====>'+ApilineList);
        //Get All POLI who dont have any related API Line Items
        List<varcpq__Purchase_Order_Line_Item__c> poliList = [SELECT Id,varcpq__AP_Line_Total_Quantity__c,varcpq__Purchase_Order__c,varcpq__AP_Line_Total_Amount__c FROM varcpq__Purchase_Order_Line_Item__c WHERE Id NOT IN
                                                              (SELECT varcpq__Purchase_Order_Line_Item__c FROM varcpq__Account_Payable_Invoice_Line_Item__c) AND varcpq__Purchase_Order__c IN :POSet]; 
        
        LIST<varcpq__Purchase_Order_Line_Item__c> poliListToUpdate = new  LIST<varcpq__Purchase_Order_Line_Item__c>(); 
        if(!ApilineList.isEmpty()){
            APLIHandler.updateQuantity(ApilineList);
        }
        
        //update POLI AP Line Total Quantity To zero When API Gets Deleted
        if(!poliList.isEmpty()){
        for(varcpq__Purchase_Order_Line_Item__c poliItem : poliList ){
                poliItem.varcpq__AP_Line_Total_Quantity__c = 0;
            	poliItem.varcpq__AP_Line_Total_Amount__c = 0;
             
                poliListToUpdate.add(poliItem);
            }            
        }
        UPDATE poliListToUpdate;      
        
    }
}