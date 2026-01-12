public class OpportunityMultipleISRHandler {

    public static void validateISR(List<Opportunity> oppList) {

        // Collect owner IDs
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : oppList) {
            if (opp.OwnerId != null) {
                ownerIds.add(opp.OwnerId);
            }
        }

        if (ownerIds.isEmpty()) return;

        // Query Default Opportunity Team settings for these owners
        List<UserTeamMember> defaultTeamList = [
            SELECT Id, OwnerId, UserId, TeamMemberRole
            FROM UserTeamMember
            WHERE OwnerId IN :ownerIds
              AND (TeamMemberRole = 'ISR' OR User.UserRole.name LIKE '%CSR%')
        ];
        if (defaultTeamList.isEmpty()) return;
        // Count ISR per Owner
        Map<Id, Integer> ownerToISRCount = new Map<Id, Integer>();

        for (UserTeamMember utm : defaultTeamList) {
            Integer count = ownerToISRCount.get(utm.OwnerId);
            ownerToISRCount.put(utm.OwnerId, (count == null ? 1 : count + 1));
        }

        // Validate per Opportunity
        for (Opportunity opp : oppList) {
            Integer isrCount = ownerToISRCount.get(opp.OwnerId);

            if (isrCount != null && isrCount > 1) {
                String validationMessage = System.Label.Opportunity_Team_Member_Validation;
                opp.addError(validationMessage);
            }
        }
    }
}