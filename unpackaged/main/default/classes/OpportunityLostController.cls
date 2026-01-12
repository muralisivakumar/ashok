public without sharing class OpportunityLostController {
    @AuraEnabled
    public static void updateLostReason(Id opportunityId, String reasonNote) {
        if (String.isBlank(reasonNote)) {
            throw new AuraHandledException('Lost reason note cannot be blank.');
        }

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        opp.Lost_Reason_Note__c = reasonNote;
        opp.StageName = 'Closed Lost';
        update opp;
    }
}