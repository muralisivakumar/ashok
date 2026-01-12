trigger EmailToCaseReopen on EmailMessage (after insert) {
    Set<Id> caseIds = new Set<Id>();
    
    for(EmailMessage email : Trigger.new) {
        if(email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType) {
            caseIds.add(email.ParentId);
        }
    }
    
    if(!caseIds.isEmpty()) {
        List<Case> casesToUpdate = [SELECT Id, Status FROM Case 
                                  WHERE Id IN :caseIds 
                                  AND IsClosed = true];
        
        for(Case c : casesToUpdate) {
            c.Status = 'Reopened';  // Adjust status as needed
        }
        
        update casesToUpdate;
    }
}