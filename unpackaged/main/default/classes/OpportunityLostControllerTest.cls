@isTest
public class OpportunityLostControllerTest {
    
    @isTest
    static void testUpdateLostReason_Success() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        String reasonNote = 'Lost due to pricing.';
        Test.startTest();
        OpportunityLostController.updateLostReason(opp.Id, reasonNote);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, StageName, Lost_Reason_Note__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Lost', updatedOpp.StageName);
        System.assertEquals(reasonNote, updatedOpp.Lost_Reason_Note__c);
    }

    @isTest
    static void testUpdateLostReason_BlankNote() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Test.startTest();
        try {
            OpportunityLostController.updateLostReason(opp.Id, '');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}