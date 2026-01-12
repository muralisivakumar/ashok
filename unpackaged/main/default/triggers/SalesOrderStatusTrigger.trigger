trigger SalesOrderStatusTrigger on varcpq__Sales_Order__c (before update) {
    /*TriggerActivation__mdt triggerconfig = [SELECT ID,MasterLabel,IsActive__c FROM TriggerActivation__mdt WHERE MasterLabel = 'SalesOrderStatusTrigger' 
                                    ];
   */ if(trigger.isBefore && trigger.isUpdate){
         new SalesOrderStatusTriggerHandler().run(); 
    }
  
}