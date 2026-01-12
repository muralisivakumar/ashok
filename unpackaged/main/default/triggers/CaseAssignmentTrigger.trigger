trigger CaseAssignmentTrigger on Case (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseAssignmentHandler.handleAssignments(Trigger.new, Trigger.oldMap);
    }
}