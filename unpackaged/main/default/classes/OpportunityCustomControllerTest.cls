@isTest
public class OpportunityCustomControllerTest {

    @testSetup
    static void setupTestData() {
      
        UserRole seRole = new UserRole(Name = 'Solutions Architect');
        insert seRole;
        System.debug('seRole-------------------->'+seRole);
        
        // Create User (setup object)
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'aressuser@gmail.com',
            Alias = 'tuser',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = seRole.Id
        );
        insert testUser;
        System.debug('testUser-------------------->'+testUser);
    
         User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            
            Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c=true);
            insert newAccount;
            
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = newAccount.Id, 
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );
            insert opp;
        }
    }

    @isTest
    static void testGetAllUsers() {
        Test.startTest();
        List<User> users = OpportunityCustomController.getAllUsers();
        System.debug('users in testGetAllUsers-------------------------->'+users);
        Test.stopTest();
    }

    @isTest
    static void testSaveCustomFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User user =  [SELECT Id,Alias FROM User WHERE Alias = 'tuser'];
    	System.runAs(thisUser) {
        Test.startTest();
        OpportunityCustomController.saveCustomFields(
            opp.Id,
            'Yes',       
            'Yes',       
            new List<Id>{user.Id}
        );
        Test.stopTest();
        }
        Opportunity updatedOpp = [SELECT varcpq__Registered__c FROM Opportunity WHERE Id = :opp.Id];
       
        List<OpportunityTeamMember> teamMembers = [
            SELECT Id, TeamMemberRole, UserId 
            FROM OpportunityTeamMember 
            WHERE OpportunityId = :opp.Id AND TeamMemberRole != 'Opportunity Owner'
        ];
    	
    }
    
    
}