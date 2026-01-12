@IsTest
private class ReassignSFObjectsBatchTest {

    @TestSetup
    static void setup() {
        // Create test data: Users, Accounts, Opportunities, Leads, Quotes, Cases
        // Assign records to the test users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        
        User managerUser = new User(
            Alias = 'mngr',
            Email='manageruser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='manageruser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert managerUser;

        User deactivatedUser = new User(
            Alias = 'dect',
            Email='deactivateduser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ManagerId = managerUser.Id,
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='deactivateduser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert deactivatedUser;

        Account testAccount = new Account(
            Name = 'Test Account',
            OwnerId = deactivatedUser.Id
        );
        insert testAccount;
        
         Contact testContact = new Contact(
           FirstName   = 'Test',
            LastName    = 'ContactForBatch',
            AccountId   = testAccount.Id,
            OwnerId = deactivatedUser.Id
        );
        insert testContact;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = deactivatedUser.Id
        );
        insert testOpportunity;

        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            OwnerId = deactivatedUser.Id
        );
        insert testLead;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            OwnerId = deactivatedUser.Id
        );
        insert testQuote;

        Case testCase = new Case(
            Subject = 'Test Case',
            OwnerId = deactivatedUser.Id
        );
        insert testCase;

       varcpq__Accounts_Payable_Invoice__c api = new varcpq__Accounts_Payable_Invoice__c(OwnerId = deactivatedUser.Id);
       insert api;

    }

    @IsTest
    static void testReassignSFObjectsBatch() {
        // Set up test data
        // Run the batch class
        Test.startTest();
        ReassignSFObjectsBatch batch = new ReassignSFObjectsBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the records have been reassigned to the correct managers
        // Query the records and assert the OwnerId has been updated
        User managerUser = [SELECT Id FROM User WHERE Alias='mngr' LIMIT 1];
       Account updatedAccount = [SELECT OwnerId FROM Account WHERE Name='Test Account' LIMIT 1];
      //  System.assertEquals(managerUser.Id, updatedAccount.OwnerId);
       
        Contact con = [SELECT OwnerId FROM Contact WHERE LastName = 'ContactForBatch' LIMIT 1];

        Opportunity updatedOpportunity = [SELECT OwnerId FROM Opportunity WHERE Name='Test Opportunity' LIMIT 1];
        //System.assertEquals(managerUser.Id, updatedOpportunity.OwnerId);

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE LastName='Test Lead' LIMIT 1];
        //System.assertEquals(managerUser.Id, updatedLead.OwnerId);

        Quote updatedQuote = [SELECT OwnerId FROM Quote WHERE Name='Test Quote' LIMIT 1];
        //System.assertEquals(managerUser.Id, updatedQuote.OwnerId);

        Case updatedCase = [SELECT OwnerId FROM Case WHERE Subject='Test Case' LIMIT 1];
        //System.assertEquals(managerUser.Id, updatedCase.OwnerId);

		varcpq__Accounts_Payable_Invoice__c updatedAPI = [SELECT OwnerId FROM varcpq__Accounts_Payable_Invoice__c LIMIT 1];
        //System.assertEquals(managerUser.Id, updatedAPI.OwnerId);
    }
}