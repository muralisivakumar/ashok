public class defaultPmHandler {

    public static void paymentMethodDefault(List<bt_stripe__Payment_Method__c> payList){
        SET<ID>accSet = new SET<ID>();
        SET<ID>pmSet = new SET<ID>();
        SET<ID>accIdSet = new SET<ID>();
        SET<ID>pmIdSet = new SET<ID>();
        for(bt_stripe__Payment_Method__c PM : payList){
            
            if(PM.bt_stripe__Default_Payment_Method__c == true){
                if(PM.bt_stripe__Account__c != null){
                  pmSet.add(PM.Id);  
                  accSet.add(PM.bt_stripe__Account__c);  
                }
               
            }
            else if(PM.bt_stripe__Default_Payment_Method__c == false){
                 if(PM.bt_stripe__Account__c != null){
                  pmIdSet.add(PM.Id);  
                  accIdSet.add(PM.bt_stripe__Account__c);
                 }
            }
            
        }
        
         List<bt_stripe__Payment_Method__c> extPMToUpdate = new  List<bt_stripe__Payment_Method__c>();
        List<bt_stripe__Payment_Method__c> extPMList = new  List<bt_stripe__Payment_Method__c>();
        
        if(pmSet!= null && accSet != null){
         extPMList = [SELECT ID,bt_stripe__Account__c,bt_stripe__Default_Payment_Method__c FROM
                                                       bt_stripe__Payment_Method__c WHERE ID NOT IN :pmSet AND bt_stripe__Account__c IN :accSet AND
                                                       bt_stripe__Default_Payment_Method__c = true];
        }
        
        
        
        if(!extPMList.isEmpty()){
            for(bt_stripe__Payment_Method__c extPM : extPMList){
                if(extPM.bt_stripe__Default_Payment_Method__c == true){
                  extPM.bt_stripe__Default_Payment_Method__c = false;  
                  extPMToUpdate.add(extPM);  
                }
            }
        }
        
        if(!extPMToUpdate.isEmpty()){
           Update extPMToUpdate;
        }
        
        //if Account has no ext PM then newly created should be default set to true
        
        
        
        
    }
}