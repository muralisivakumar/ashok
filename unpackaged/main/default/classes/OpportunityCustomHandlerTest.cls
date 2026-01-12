@isTest
public class OpportunityCustomHandlerTest {
    
    
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
            
            
        }
    }
    
     @isTest
    static void testGetAllUsers() {
        Test.startTest();
        List<User> users = OpportunityCustomHandler.getAllUsers();
        System.debug('users in testGetAllUsers-------------------------->'+users);
        Test.stopTest();
    }
    
     @isTest
    static void testcreateOpportunity() {
        Date todayDate = Date.today();
        Id AccId = [Select Id from Account].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User user =  [SELECT Id,Alias FROM User WHERE Alias = 'tuser'];
        
        System.runAs(thisUser) {
        Test.startTest();
        OpportunityCustomHandler.createOpportunity(
             'Test Opp', AccId,'Other', todayDate,10.00,1.00,'Yes','Yes',new List<Id>{user.Id});
        Test.stopTest();
        }

    }


}