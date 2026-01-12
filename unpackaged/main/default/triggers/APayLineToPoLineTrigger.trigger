trigger APayLineToPoLineTrigger on varcpq__Account_Payable_Invoice_Line_Item__c (After Update,After delete) {
    
     /*TriggerActivation__mdt triggerconfig = [SELECT ID,MasterLabel,IsActive__c FROM TriggerActivation__mdt WHERE MasterLabel = 'APayLineToPoLineTrigger' 
                                            ];*/    
     
    if(trigger.isAfter && trigger.isUpdate){      
        APLIHandler.updateQuantityOnUpdate(trigger.new,trigger.oldMap); 
    }
    if(trigger.isAfter && trigger.isDelete){      
        APLIHandler.updateQuantity(trigger.old); 
    }
    
}