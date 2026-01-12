public class InvoiceWizardController {
    
    @AuraEnabled
    public static List<soliWrapper> returnSOItems(Id soId){
        String siteUrl = URL.getOrgDomainURL().toExternalForm();
        List<soliWrapper>wrapList = new List<soliWrapper>();
        List<varcpq__Sales_Order_Line_Item__c> SOLineItemList = [SELECT ID,varcpq__Sales_Order__c ,varcpq__Quantity__c,varcpq__Product__c,
                                                                 varcpq__Product__r.ProductCode,
                                                                 varcpq__Product__r.Name,varcpq__Product__r.varcpq__PARTNUMBER__c,
                                                                 varcpq__Product__r.varcpq__Manufacturer__r.Name,
                                                                 varcpq__Units_Available_for_Invoice__c,
                                                                 varcpq__Units_Available_for_Shipment__c,varcpq__Units_Vouchered__c,Units_Available_after_vendor_Invoiced__c
                                                                 FROM varcpq__Sales_Order_Line_Item__c
                                                                 WHERE varcpq__Sales_Order__c =: soId]; 
        String soliUrl = '';
        for(varcpq__Sales_Order_Line_Item__c invLine : SOLineItemList){
            soliUrl = siteUrl+'/'+ invLine.Id;
            wrapList.add(new soliWrapper(invLine.Id,invLine.varcpq__Product__r.Name,soliUrl,invLine.varcpq__Product__r.varcpq__Manufacturer__r.Name
                                         ,invLine.varcpq__Quantity__c,invLine.varcpq__Units_Vouchered__c,
                                         invLine.varcpq__Units_Available_for_Shipment__c,invLine.Units_Available_after_vendor_Invoiced__c));  
        }
        
        if(!wrapList.isEmpty()){
            RETURN wrapList; 
        }
        else{
            RETURN NULL;
        }   
        
    }
    
    
    /* Create Invoice */    
    @AuraEnabled
    public static Id createInvoice(ID soId, List<soliWrapper> soItems){
        Savepoint sp;
        try{
            sp = Database.setSavePoint();
            varcpq__Sales_Order__c SO =[SELECT ID,varcpq__Client__c,CurrencyIsoCode,varcpq__Billing_Contact__c,Additional_Ship_To_Header__c,
                                        Contract__r.ContractNumber,varcpq__Notes__c,SO_Net_Terms__c,
                                        varcpq__Shipping_and_Handling__c, Total_Shipping_Amt_Invoiced__c, varcpq__Customer_PO__c FROM varcpq__Sales_Order__c WHERE
                                        ID =:soId];
            
            
            varcpq__Invoice__c Inv = new varcpq__Invoice__c();
            Inv.varcpq__Sales_Order__c = SO.Id;
            Inv.varcpq__Client__c = SO.varcpq__Client__c;
            Inv.varcpq__Billing_Contact__c = SO.varcpq__Billing_Contact__c;
            if(SO.varcpq__Shipping_and_Handling__c == null){
                Inv.varcpq__Shipping_and_Handling__c = 0;
            }else{
                Inv.varcpq__Shipping_and_Handling__c = SO.varcpq__Shipping_and_Handling__c - SO.Total_Shipping_Amt_Invoiced__c;
            }           
             Inv.varcpq__PO_Number__c = SO.varcpq__Customer_PO__c;
            Inv.varcpq__Status__c = 'Not Issued';
            Inv.Additional_Ship_To_Header__c= SO.Additional_Ship_To_Header__c;
            Inv.Contract_Number__c = SO.Contract__r.ContractNumber;
            Inv.Notes__c = SO.varcpq__Notes__c;
            Inv.varcpq__Terms__c = SO.SO_Net_Terms__c;
            Inv.CurrencyIsoCode = SO.CurrencyIsoCode;
            if(Inv!=null){
                INSERT Inv;  
            }
            
            /* Fetch Sales Order Line Item IDs from  Wrapper*/
            Map<Id,soliWrapper> wrapperMap = new Map<Id,soliWrapper>(); 
            List<Id> soliIds = new List<Id>();
            for (soliWrapper sw : soItems) {
                if (sw.SOLineId != null) {
                    soliIds.add(sw.SOLineId);
                    wrapperMap.put(sw.SOLineId,sw);
                } 
            }
            List<Invoice_group__c> invGroups = new List<Invoice_Group__c>();
            
            
            /*Fetch only Sales Order Line Item whose IDs are passed in from the soliWrapper wrapper*/
            List<varcpq__Sales_Order_Line_Item__c> SOLineItems = [SELECT ID, CurrencyIsoCode, varcpq__Unit_Price__c,varcpq__Contract_Fee__c,varcpq__Quantity__c,varcpq__Unit_Cost__c,varcpq__Line__c,varcpq__Asset__c,varcpq__Product__c ,varcpq__Distributor__c,Sales_Order_Group__c 
                                                                  FROM varcpq__Sales_Order_Line_Item__c WHERE ID IN :soliIds];
            Set<Id> soGrpids = new Set<Id>();
            for (varcpq__Sales_Order_Line_Item__c soli : SOLineItems){
                soGrpIds.add(soli.Sales_Order_Group__c);               
            }
            map<id,Sales_Order_Group__c> soGroups = new Map<Id,Sales_order_Group__c>( [SELECT Id, Name, Margin_Sub_Total__c, Sales_Order__c, Sequence__c, Sub_Total__c,currencyIsoCode 
                                                                                       FROM Sales_Order_Group__c WHERE Id=:soGrpIds]);
            System.debug('soGroups '+soGroups);
            if(!soGroups.isEmpty()){
                for(sales_order_group__c grp: soGroups.values()){
                    Invoice_Group__c invGrp = new Invoice_Group__c();
                    invGrp.Name = grp.Name;
                    invGrp.Invoice__c = inv.Id;
                    invGrp.SO_Group_Id__c = grp.Id;
                    invGrp.CurrencyIsoCode = grp.CurrencyIsoCode;
                    invGroups.add(invGrp);
                }
                if(!invGroups.isEmpty()){
                	insert invGroups;
                }
            }
            System.debug('invGroups '+invGroups);
            Map<String,Id> grpsMap = new Map<String,id>(); // salesordergroup id vs inv group id
            
            Map<Id,Decimal> invGrpST = new Map<Id,Decimal>(); // inv group is vs sub total
            
            for(Invoice_Group__c ig: invGroups){
                grpsMap.put(ig.SO_Group_Id__c,ig.Id);
                invGrpST.put(ig.Id,0);
            }
            System.debug('invGrpST '+invGrpST);
            /*Create Invoice Line Items*/
            List<varcpq__Invoice_Line_Item__c> invoiceLineItems = new List<varcpq__Invoice_Line_Item__c>();
            for (varcpq__Sales_Order_Line_Item__c soli : SOLineItems) {
                varcpq__Invoice_Line_Item__c invoLi = new varcpq__Invoice_Line_Item__c();
                invoLi.varcpq__Sales_Order_Line_Item__c = soli.Id;
                invoLi.varcpq__Invoice__c = Inv.Id;
                invoLi.varcpq__Unit_Price__c= soli.varcpq__Unit_Price__c;
                invoLi.varcpq__Quantity__c= wrapperMap.get(soli.Id).NeedsInvoiced;
                invoLi.varcpq__Total_Cost__c = wrapperMap.get(soli.Id).NeedsInvoiced * soli.varcpq__Unit_Cost__c;
                invoLi.varcpq__DH_Line__c = soli.varcpq__Line__c;
                invoLi.CurrencyIsoCode = soli.CurrencyIsoCode;
                invoLi.varcpq__Asset__c = soli.varcpq__Asset__c;
                invoLi.Distributor__c = soli.varcpq__Distributor__c;
                invoLi.Product__c = soli.varcpq__Product__c;
                if(grpsMap.containsKey(soli.Sales_Order_Group__c)){
                	invoLi.Invoice_Group__c = grpsMap.get(soli.Sales_Order_Group__c);               
                	Decimal ST = invGrpST.get(invoLi.Invoice_Group__c) +(invoLi.varcpq__Quantity__c * invoLi.varcpq__Unit_Price__c);
                	invGrpST.put(invoLi.Invoice_Group__c,ST);
                }
                if(soli.varcpq__Contract_Fee__c > 0){
                    invoLi.varcpq__Contract_Fees__c = soli.varcpq__Contract_Fee__c/wrapperMap.get(soli.Id).NeedsInvoiced; 
                }
                invoiceLineItems.add(invoLi);
            }
            
            if (!invoiceLineItems.isEmpty()) {
                insert invoiceLineItems;
                //return true;
            }
            Integer count = 1;
            for(Invoice_Group__c invGrp : invGroups){
                invGrp.Sequence__c = count;
                invGrp.Sub_Total__c = invGrpST.get(invGrp.Id);
                count++;
            }
            if(!invGroups.isEmpty()){
                update invGroups;
            }
            
            return Inv.Id;
        }catch(exception ex){
            Database.rollBack(sp);
            System.debug(ex);
            return null;
        }
    }
    
    public Class soliWrapper{
        @AuraEnabled public Id SOLineId{get;set;}      
        @AuraEnabled public String partNo{get;set;}
        @AuraEnabled public String soliUrl{get;set;}
        @AuraEnabled public String ManufactureName{get;set;} 
        @AuraEnabled public Decimal quantity{get;set;}
        @AuraEnabled public Decimal vendorInvoiced{get;set;}
        @AuraEnabled public Decimal NeedsShiped{get;set;}
        @AuraEnabled public Decimal NeedsInvoiced{get;set;}
        
        public soliWrapper(){
            
        }
        
        public soliWrapper(Id SoLineItemId, String partNumber,String soliUrl,String ManuFactName,Decimal quantityOfProducts,
                           Decimal VenInv,Decimal NeedsToShiped,Decimal NeedsToInvoiced){
                               
                               this.SOLineId= SoLineItemId;                 
                               this.partNo =partNumber;
                               this.soliUrl = soliUrl;
                               this.ManufactureName=ManuFactName;
                               this.quantity=quantityOfProducts;
                               this.vendorInvoiced=VenInv;
                               this.NeedsShiped=NeedsToShiped;
                               this.NeedsInvoiced=NeedsToInvoiced;
                               
                           }
        
    }
    
}