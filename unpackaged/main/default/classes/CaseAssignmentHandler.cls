public class CaseAssignmentHandler {

    // Inner class to represent assignment rules
    private class AssignmentRule {
        public String assignmentType;
        public Id assignedToId;
        public String emailDomain;
        public String excludeDomain;
        public String queue;
        public String category;

        public AssignmentRule(Case_Assignment_Rule__mdt rule) {
            this.assignmentType = rule.Assignment_Type__c;
            this.assignedToId = rule.Assigned_To_Id__c;
            this.emailDomain = rule.Email_Domain__c;
            this.excludeDomain = rule.Exclude_Domain__c;
            this.queue = rule.Queue__c;
            this.category = rule.Category__c;
        }
    }

    // Main assignment logic called from trigger
    public static void handleAssignments(List<Case> newCases, Map<Id, Case> oldMap) {
        List<Case> casesToProcess = new List<Case>();
        List<Case> casesToUpdate = new List<Case>();

        for (Case newCase : newCases) {
            Case oldCase = oldMap.get(newCase.Id);
            if (isRelevantFieldChanged(newCase, oldCase) && newCase.Status != 'Escalated') {
                casesToProcess.add(newCase);
            }
        }

        if (casesToProcess.isEmpty()) {
            return;
        }

        // Load active assignment rules
        List<Case_Assignment_Rule__mdt> assignmentRules = [
            SELECT Queue__c, Category__c, Assignment_Type__c, 
                   Assigned_To_Id__c, Email_Domain__c, Exclude_Domain__c
            FROM Case_Assignment_Rule__mdt 
            WHERE Active__c = true
            AND Assignment_Type__c IN ('User', 'Queue')
        ];

        List<AssignmentRule> rules = new List<AssignmentRule>();
        for (Case_Assignment_Rule__mdt rule : assignmentRules) {
            rules.add(new AssignmentRule(rule));
        }

        // Query Customer Billings Queue
        Group customerBillingsQueue;
        try {
            customerBillingsQueue = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = 'Customer_Billings' 
                AND Type = 'Queue' 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error querying Customer Billings Queue: ' + e.getMessage());
            return;
        }

        for (Case newCase : casesToProcess) {
            Case oldCase = oldMap.get(newCase.Id);

            // Assign to Customer Billings queue if Invoice posted to QuickBooks just became true
            if (customerBillingsQueue != null && 
                newCase.Invoice_Posted_to_QuickBooks__c == true &&
                (oldCase == null || oldCase.Invoice_Posted_to_QuickBooks__c == false)) {
                casesToUpdate.add(new Case(Id = newCase.Id, OwnerId = customerBillingsQueue.Id));
                continue;
            }

            // Find matching assignment rule
            AssignmentRule matchedRule = findMatchingRule(rules, newCase);
            if (matchedRule != null) {
                casesToUpdate.add(new Case(Id = newCase.Id, OwnerId = matchedRule.assignedToId));
            }
        }

        // Update case owner assignments
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Case owners: ' + e.getMessage());
            }
        }
    }

    // Check if relevant fields changed
    private static Boolean isRelevantFieldChanged(Case newCase, Case oldCase) {
        return (newCase.Queue__c != oldCase.Queue__c ||
                newCase.Category__c != oldCase.Category__c ||
                newCase.Type != oldCase.Type ||
                newCase.Invoice_Posted_to_QuickBooks__c != oldCase.Invoice_Posted_to_QuickBooks__c);
    }

    // Find matching assignment rule
    public static AssignmentRule findMatchingRule(List<AssignmentRule> rules, Case newCase) {
        // 1. Match on queue, category, and email domain
        for (AssignmentRule rule : rules) {
            if (rule.queue == newCase.Queue__c &&
                rule.category == newCase.Category__c &&
                rule.emailDomain != null &&
                newCase.Email_From__c != null &&
                newCase.Email_From__c.toLowerCase().contains(rule.emailDomain.toLowerCase())) {
                return rule;
            }
        }

        // 2. Match on queue, category, and exclude domain (email must NOT contain exclude domain)
        for (AssignmentRule rule : rules) {
            if (rule.queue == newCase.Queue__c &&
                rule.category == newCase.Category__c &&
                rule.excludeDomain != null &&
                newCase.Email_From__c != null &&
                !newCase.Email_From__c.toLowerCase().contains(rule.excludeDomain.toLowerCase())) {
                return rule;
            }
        }

        // 3. Default rule for queue and category (emailDomain and excludeDomain null)
        for (AssignmentRule rule : rules) {
            if (rule.queue == newCase.Queue__c &&
                rule.category == newCase.Category__c &&
                rule.emailDomain == null &&
                rule.excludeDomain == null) {
                return rule;
            }
        }

        // 4. Match Email Domain only (queue and category null)
        for (AssignmentRule rule : rules) {
            if (rule.emailDomain != null &&
                newCase.Email_From__c != null &&
                newCase.Email_From__c.toLowerCase().contains(rule.emailDomain.toLowerCase()) &&
                rule.queue == null &&
                rule.category == null) {
                return rule;
            }
        }

        // No match found
        return null;
    }
}