trigger QuoteTrigger on Quote (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    // Context Variables
    Boolean isBefore = Trigger.isBefore;
    Boolean isAfter = Trigger.isAfter;
    Boolean isInsert = Trigger.isInsert;
    Boolean isUpdate = Trigger.isUpdate;
    Boolean isDelete = Trigger.isDelete;
    Boolean isUndelete = Trigger.isUndelete;
    List<Quote> newList = Trigger.new;
    List<Quote> oldList = Trigger.old;
    Map<Id, Quote> newMap = Trigger.newMap;
    Map<Id, Quote> oldMap = Trigger.oldMap;
    Integer size = Trigger.size;
    
    // Skip main logic if FALSE
    if (!TriggerControl.isActive('QuoteTrigger')) {
        return; 
    }
    
    // Use switch for Trigger Operation
    switch on Trigger.operationType {
        
        when BEFORE_INSERT {
            // Future use
        }
        
        when BEFORE_UPDATE {
            QuoteTriggerHandler.beforeUpdate(newList, oldMap);
        }
        
        when BEFORE_DELETE {
            // Future use
        }
        
        when AFTER_INSERT {
            // Future use
        }
        
        when AFTER_UPDATE {
            //QuoteTriggerHandler.afterUpdate(newList, oldMap);
        }
        
        when AFTER_DELETE {
            // Future use
        }
        
        when AFTER_UNDELETE {
            // Future use
        }
    }
}