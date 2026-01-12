trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (
    after insert,
    before update
) {
   /* OpportunityMultipleISRHandler.validateISRUnique(
        Trigger.new, 
        Trigger.oldMap, 
        Trigger.isInsert
    );*/
     for(OpportunityTeamMember oppTeam:trigger.new){
        system.debug('check execution');
        oppTeam.adderror('Cannot create/update');
         
    }
}