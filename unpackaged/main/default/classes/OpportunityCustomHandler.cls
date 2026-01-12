//Apex class for LWC Component for Opportunity Creation From Account Record Page
public without sharing class OpportunityCustomHandler {
    
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {
        return [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND UserRole.Name IN ('Solutions Architect', 'Sales Engineer') ORDER BY Name];
    }
    
    // Create a new Opportunity record
    @AuraEnabled
    public static Id createOpportunity(String name, Id accountId, String leadSource, Date closeDate, Decimal amount, Decimal margin,
                                       String dealRegistered, String supplierId, String isSE,List<Id> userIds) {

                                           Opportunity opp = new Opportunity();
                                           opp.Name = name;
                                           opp.AccountId = accountId;
                                           opp.LeadSource = leadSource;
                                           opp.CloseDate = closeDate;
                                           opp.Amount = amount;
                                           opp.varcpq__Margin__c = margin;
                                           if (dealRegistered == 'Yes') {
                                               opp.varcpq__Registered__c = true;
                                           } 
                                           else {
                                               opp.varcpq__Registered__c = false;
                                           }
                                           if (!String.isBlank(supplierId)) {
                                            opp.Supplier_Name__c = supplierId; 
                                            }
                                           if(!userIds.isEmpty()){ 
                                               opp.SE_Assigned__c = userIds[0]; 
                                           }                               
                                           
                                           try{
                                               insert opp;
                                           }
                                           // Apexify -- Surya -- Ticket #51 -- Modified the catch block to throw correct message to lwc  
                                           catch (Exception ex) {
                                               System.debug('exception ' + ex);
                                               String cleanMsg = '';
                                               if(String.isNotBlank(ex.getMessage())){
                                                   cleanMsg = ex.getMessage();
                                               }
                                               
                                               // Extract text before the colon
                                               if (cleanMsg.contains(',')) {
                                                   cleanMsg = cleanMsg.substringAfter(',');
                                               }
                                               
                                               throw new AuraHandledException(cleanMsg.trim());
                                           }
                                           
                                           // Handle Opportunity Team Members
                                           if (isSE == 'Yes' && userIds != null && !userIds.isEmpty()) {
                                               List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
                                               
                                               List<User> userList = [ SELECT Id FROM User WHERE Id IN :userIds AND UserRoleId != null];
                                               
                                               for (User usr : userList) {
                                                   OpportunityTeamMember member = new OpportunityTeamMember();
                                                   member.OpportunityId = opp.Id;
                                                   member.UserId = usr.Id;
                                                   member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                                                   member.TeamMemberRole = 'Sales Engineer';
                                                   oppTeamList.add(member);
                                               }
                                               
                                               if (!oppTeamList.isEmpty()) {
                                                   insert oppTeamList;
                                               }
                                           }
                                           
                                           Account acc = [ SELECT OwnerId FROM Account WHERE Id = :accountId LIMIT 1]; 
                                           Opportunity Opportunity = [SELECT Id, CreatedById, OwnerId FROM Opportunity WHERE Id = :opp.Id LIMIT 1];  
                                           
                                           //Logic to update Opportunity Original Creator TeamMemberRole To its UserRole with Edit Access                                           
                                           try {
                                               
                                               if(acc.OwnerId != Opportunity.CreatedById){
                                                   
                                                   
                                                   // Change Opportunity Owner  
                                                   /*Opportunity.OwnerId = acc.OwnerId;
update Opportunity;*/
                                                   
                                                   System.debug('Opportunity.CreatedById------------>'+Opportunity.CreatedById);
                                                   System.debug('Opportunity Account OwnerId---------------->'+acc.OwnerId);
                                                   
                                                   User creatorUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :Opportunity.CreatedById LIMIT 1];
                                                   User accOwner = [SELECT Id, UserRole.Name FROM User WHERE Id = :acc.OwnerId LIMIT 1];
                                                   
                                                   System.debug('creatorUser---------------------->'+creatorUser);
                                                   System.debug('creatorUser Role Name---------------------->'+creatorUser.UserRole.Name);
                                                   System.debug('accOwner---------------------->'+accOwner);
                                                   System.debug('accOwner Role Name---------------------->'+accOwner.UserRole.Name);
                                                   
                                                   // Check if the creator is already on the opportunity team
                                                   List<OpportunityTeamMember> existingCreatorMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :Opportunity.Id  AND UserId = :Opportunity.CreatedById LIMIT 1];
                                                   
                                                   if (existingCreatorMember.isEmpty()) {
                                                       System.debug('existingCreatorMember-------------->'+existingCreatorMember);
                                                       // Update existing member
                                                          // Apexify -- Surya -- Ticket #51 -- commenting below code that updates the member and added logic to inset member.
                                                       /*  OpportunityTeamMember member = existingCreatorMember[0];
member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
member.OpportunityAccessLevel = 'Edit';
update member;*/                                     
                                                        // Apexify -- Surya -- Ticket #51 -- inserting new member only if the created user is not part of the default opportunity team for the owner.
                                                       OpportunityTeamMember member = new OpportunityTeamMember();
                                                       member.OpportunityId = opp.Id;
                                                       member.UserId = Opportunity.CreatedById;
                                                       member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                                                       member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                                                       insert member;
                                                       //Delete member;
                                                       System.debug('Original creator member after updation of member role and access------>'+member);
                                                   }          
                                               }
                                               
                                           } catch (Exception e) {
                                               System.debug('Error adding/updating creator on team: ' + e.getMessage());
                                           } 
                                           
                                           return Opportunity.Id;                                           
                                       }
    
    //Method for bill only opportunity creation 
    @AuraEnabled
    public static Id createBillOnlyOpportunity(String name, Id accountId){
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.AccountId = accountId;
        opp.LeadSource = 'Bill-Only Order';
        opp.CloseDate = System.Today();
        insert opp;
        
        Opportunity opportunity = [SELECT Id, CreatedById, OwnerId FROM Opportunity WHERE Id = :opp.Id LIMIT 1]; 
        Account acc = [SELECT OwnerId FROM Account WHERE Id = :accountId  LIMIT 1];
        
        if(opportunity.CreatedById != acc.OwnerId){
            opportunity.OwnerId = acc.OwnerId;
            update opportunity;
            
            User creatorUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :opportunity.CreatedById LIMIT 1];
            User accOwner = [SELECT Id, UserRole.Name FROM User WHERE Id = :acc.OwnerId LIMIT 1];
            
            //now change access of creator to edit in opp team
            List<OpportunityTeamMember> existingCreatorMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :opportunity.Id  AND UserId = :opportunity.CreatedById LIMIT 1];
            if (!existingCreatorMember.isEmpty()) {
                System.debug('existingCreatorMember-------------->'+existingCreatorMember);
                // Update existing member
                OpportunityTeamMember member = existingCreatorMember[0];
                member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                member.OpportunityAccessLevel = 'Edit';
                update member;
                System.debug('Original creator member after updation of member role and access------>'+member);
            }      
            
        } 
        Return opportunity.Id;
        
    }
      @AuraEnabled(cacheable=true)
    public static List<Account> searchSuppliers(String searchText) {
        
        if (String.isBlank(searchText)) {
            searchText = '';
        }
        
        String filter = '%' + searchText + '%';
        
        System.debug('SEARCH TEXT RECEIVED ---> ' + searchText);
        
        return [
            SELECT Id, Name
            FROM Account
            WHERE Type = 'Supplier'
            AND Name LIKE :filter
            ORDER BY Name
            LIMIT 20
        ];
    }
    
    
}