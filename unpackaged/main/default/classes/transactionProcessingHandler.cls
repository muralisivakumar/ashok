public class transactionProcessingHandler {
    public static void updateSOAuthLink(List<bt_stripe__Transaction__c> tranList, Map<Id,bt_stripe__Transaction__c> oldTranmap){
        List<varcpq__Sales_Order__c> soList = new List<varcpq__Sales_Order__c>();
        List<varcpq__Sales_Order__c> salesorderList = new List<varcpq__Sales_Order__c>();
        List<varcpq__Sales_Order__c> salesorderList2 = new List<varcpq__Sales_Order__c>();
        List<varcpq__Invoice__c> invList = new List<varcpq__Invoice__c>();
        Map<Id,Decimal> invIdVsTranAmount = new Map<Id,Decimal>();
        Map<Id,Integer> soIdVSCount = new Map<Id,Integer>();
        Map<Id,Integer> soIdVSCount2 = new Map<Id,Integer>();
        Map<Id,Date>  invIdVSDate = new Map<Id,Date> ();
        Set<Id> soIds = new Set<Id>();
        List<bt_stripe__Transaction__c> tranListToUpdate = new List<bt_stripe__Transaction__c>();
        List<bt_stripe__Transaction__c> transactionList = new List<bt_stripe__Transaction__c>();
        List<bt_stripe__Transaction__c> transactionList2 = new List<bt_stripe__Transaction__c>();
        List<bt_stripe__Transaction__c> transactionListForInv = new List<bt_stripe__Transaction__c>();
        Set<ID> sOIdSet = new Set<ID>();
        Set<ID> salesorderIds = new Set<ID>();
        Set<ID> sOrderIds = new Set<ID>();
        Set<ID> InvIds = new Set<ID>();
        

        for(bt_stripe__Transaction__c tran : tranList){
            // Logic to Update Pending_Credit_Card_Preauthorization__c and Transaction to PreAuthorized
            if(tran.Sales_Order__c != null && !String.isBlank(tran.bt_stripe__Payment_Status__c)){
                if(oldTranmap.get(tran.Id).bt_stripe__Transaction_Status__c == 'Open' && 
                   tran.bt_stripe__Transaction_Status__c == 'Completed' && tran.bt_stripe__Payment_Status__c == 'Authorized'){
                    sOIdSet.add(tran.Sales_Order__c);
                    // Mark Transaction to PreAuthorized
                    bt_stripe__Transaction__c tra = new bt_stripe__Transaction__c();
                    tra.Id = tran.Id;
                    tra.Status_Of_Transaction__c = 'Preauthorized';
                    tranListToUpdate.add(tra);    
                }
            }
            
            // Logic to update count of Authorized_Transactions__c on salesorder
            if(tran.Sales_Order__c != null && !String.isBlank(tran.bt_stripe__Payment_Status__c)){
                if(tran.bt_stripe__Payment_Status__c == 'Authorized'){
                    salesorderIds.add(tran.Sales_Order__c); 
                }
            }
            
            // Logic to populate captured Amount on Invoice
            if(tran.Sales_Order__c != null && !String.isBlank(tran.bt_stripe__Payment_Status__c) && tran.Invoice__c != null){
                if(tran.bt_stripe__Transaction_Status__c == 'Completed' && tran.bt_stripe__Payment_Status__c == 'Captured'){
                    InvIds.add(tran.Invoice__c);
                }  
            }
            
            // Logic to count authorized transactions after releasing transactions
            if(tran.Sales_Order__c != null && !String.isBlank(tran.bt_stripe__Payment_Status__c)){
                
                if(oldTranmap.get(tran.Id).bt_stripe__Payment_Status__c == 'Authorized' && 
                   tran.bt_stripe__Transaction_Status__c == 'Completed' && 
                   tran.bt_stripe__Payment_Status__c == 'Uncaptured'){
                    sOrderIds.add(tran.Sales_Order__c);
                     System.debug('sOrderIds After Uncapturing------------------>'+sOrderIds);
                }
            }
        } //For Loop End

        if(!sOIdSet.isEmpty()){
            soList = [SELECT ID, Pending_Credit_Card_Preauthorization__c FROM varcpq__Sales_Order__c WHERE ID IN :sOIdSet];
            if(!soList.isEmpty()){
                for(varcpq__Sales_Order__c so : soList){
                    so.Pending_Credit_Card_Preauthorization__c = false;
                }
                UPDATE soList;
            }
        }
        
        // Update Transactions
        if(!tranListToUpdate.isEmpty()){
            UPDATE tranListToUpdate;  
        }
        
        if(!InvIds.isEmpty()){
            invList = [SELECT ID, Grand_Total__c, Captured_Charges__c, varcpq__Status__c, varcpq__Date_Paid__c, Capture_Complete__c 
                      FROM varcpq__Invoice__c WHERE ID IN :InvIds];
            transactionListForInv = [SELECT Id, Invoice__c, CreatedDate, bt_stripe__Payment_Status__c, bt_stripe__Amount__c 
                                   FROM bt_stripe__Transaction__c WHERE bt_stripe__Payment_Status__c = 'Captured' AND Invoice__c IN :InvIds
                                    ORDER BY CreatedDate ASC];
            
            if(!transactionListForInv.isEmpty()){
                for(bt_stripe__Transaction__c tran : transactionListForInv){
                    if(!invIdVsTranAmount.containsKey(tran.Invoice__c) && !invIdVSDate.containsKey(tran.Invoice__c)){
                        invIdVsTranAmount.put(tran.Invoice__c, tran.bt_stripe__Amount__c); 
                        invIdVSDate.Put(tran.Invoice__c,tran.CreatedDate.date());
                        
                    } else {
                        invIdVsTranAmount.put(tran.Invoice__c, invIdVsTranAmount.get(tran.Invoice__c) + tran.bt_stripe__Amount__c);
                        invIdVSDate.Put(tran.Invoice__c,tran.CreatedDate.date());
                    }
                }
            }
            System.debug('Date Paid-------------------------->'+invIdVSDate.Values());
            
            if(!invList.isEmpty()){
                for(varcpq__Invoice__c inv : invList){
                    if(invIdVsTranAmount.containsKey(inv.Id) && invIdVSDate.containsKey(inv.Id)){ 
                        inv.Captured_Charges__c = invIdVsTranAmount.get(inv.Id);
                        System.debug('inv.Captured_Charges__c in transactionProcessingHandler---------------------->' +inv.Captured_Charges__c);
                        if(inv.Captured_Charges__c == inv.Grand_Total__c){
                            inv.varcpq__Status__c = 'Paid'; 
                            inv.Capture_Complete__c = true;
                            inv.varcpq__Date_Paid__c = invIdVSDate.get(inv.Id);
                        }
                    }
                }
                System.debug('invList------------------------->'+invList);
                UPDATE invList;   
            }
        }
        
        // Update authorized transaction count
        if(!salesorderIds.isEmpty()){
            transactionList = [SELECT Id, Sales_Order__c, bt_stripe__Payment_Status__c FROM bt_stripe__Transaction__c 
                             WHERE bt_stripe__Payment_Status__c = 'Authorized' AND Sales_Order__c IN :salesorderIds];
            
            if(!transactionList.isEmpty()){
                for(bt_stripe__Transaction__c trx : transactionList){
                    if(!soIdVSCount.containsKey(trx.Sales_Order__c)){
                        soIdVSCount.put(trx.Sales_Order__c, 1);  
                    } else {
                        soIdVSCount.put(trx.Sales_Order__c, soIdVSCount.get(trx.Sales_Order__c) + 1);  
                    }
                }
            }
            System.debug('salesorderIds------------------->'+salesorderIds);
            salesorderList = [SELECT Id, Authorized_Transactions__c FROM varcpq__Sales_Order__c WHERE ID IN :salesorderIds];
            if(!salesorderList.isEmpty()){
               for(varcpq__Sales_Order__c so : salesorderList){                
                    if(soIdVSCount.containsKey(so.Id)){
                        so.Authorized_Transactions__c = soIdVSCount.get(so.Id); 
                    }
                }
                UPDATE salesorderList;  
            }     
        }
        
        // Update count after releasing transactions 
        if(!sOrderIds.isEmpty()){
            transactionList2 = [SELECT Id, Sales_Order__c, bt_stripe__Payment_Status__c FROM bt_stripe__Transaction__c 
                              WHERE bt_stripe__Payment_Status__c = 'Authorized' AND Sales_Order__c IN :sOrderIds];
            
            if(!transactionList2.isEmpty()){
                System.debug('transactionList2 Size------------>'+transactionList2.size());
                for(bt_stripe__Transaction__c trx : transactionList2){
                    if(!soIdVSCount2.containsKey(trx.Sales_Order__c)){
                        soIdVSCount2.put(trx.Sales_Order__c, 1);  
                    } else {
                        soIdVSCount2.put(trx.Sales_Order__c, soIdVSCount2.get(trx.Sales_Order__c) + 1);  
                    }
                }
            }
            
            System.debug('soIdVSCount2 Map in after uncapturing-------->'+soIdVSCount2);
            salesorderList2 = [SELECT Id, Authorized_Transactions__c FROM varcpq__Sales_Order__c WHERE ID IN :sOrderIds];
            if(!salesorderList2.isEmpty()){
                for(varcpq__Sales_Order__c so : salesorderList2){
                   
                    if(soIdVSCount2.containsKey(so.Id)){
                        so.Authorized_Transactions__c = soIdVSCount2.get(so.Id); 
                        }
                    else{
                        system.debug('inside else of soIdVSCount2 null check');
                        so.Authorized_Transactions__c = 0;
                   }
               }
                UPDATE salesorderList2;
                System.debug('salesorderList2 After Update Statement---->'+salesorderList2);
            } 
        }
    }
}