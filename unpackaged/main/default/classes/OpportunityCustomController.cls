//Apex class for Opportunity List View Aura Component for Opportunity Creation
public without sharing class OpportunityCustomController {
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {
        return [SELECT Id, Name, UserRole.Name 
                FROM User 
                WHERE IsActive = true 
                AND UserRole.Name IN ('Solutions Architect', 'Sales Engineer')
                ORDER BY Name];
    }
    
    @AuraEnabled
    public static void saveCustomFields(Id oppId, String dealRegistered, String isSE, List<Id> userIds , Id supplierId) {
        system.debug('oppId----------------->'+oppId);
        system.debug('dealRegistered----------------->'+dealRegistered);
        system.debug('isSE----------------->'+isSE);
        system.debug('userIds----------------->'+userIds);
        
        Opportunity opp = [SELECT Id,AccountId,Account.OwnerId ,SE_Assigned__c,varcpq__Registered__c FROM Opportunity WHERE Id = :oppId];
        
        if(dealRegistered == 'Yes'){
            opp.varcpq__Registered__c = true;
        }
        if (dealRegistered == 'No' && supplierId != null) {
            opp.Supplier_Name__c = supplierId;
        }
        if(!userIds.isEmpty()){ 
            opp.SE_Assigned__c = userIds[0]; 
        } 
        Update opp;
        // Optionally relate multiple users (custom junction object)
        if (isSE == 'Yes' && userIds != null && !userIds.isEmpty()) {
            List<OpportunityTeamMember> oppTeam = new List<OpportunityTeamMember>();
            List<OpportunityShare> oppShares = new List<OpportunityShare>();
            
            List<User>userList = [Select Id,UserRole.Name, UserRole.Id FROM User Where ID IN : userIds AND UserRole.Id != null];
            Map<Id,String>userIdVSroleId = new Map<ID,String>();
            
            if(!userList.isEmpty()){
                for(User usr : userList){
                    if(usr.UserRole.Id != null){
                        //userIdVSroleId.put(usr.Id,usr.UserRole.Id); 
                        userIdVSroleId.put(usr.Id,'Sales Engineer'); 
                    }
                }
            }
            for (Id uid : userIds) {
                
                
                OpportunityShare share = new OpportunityShare();
                share.OpportunityId = opp.Id;
                share.UserOrGroupId = uid;
                share.OpportunityAccessLevel = 'Edit'; // or 'Read'
                share.RowCause = Schema.OpportunityShare.RowCause.Manual; 
                oppShares.add(share);
                
                if(!userIdVSroleId.isEmpty()){
                    if(userIdVSroleId.containsKey(uid)){
                        OpportunityTeamMember OppMember =  new OpportunityTeamMember();
                        OppMember.OpportunityId = oppId;
                        OppMember.UserId = uid;
                        OppMember.OpportunityAccessLevel = 'Edit';
                        OppMember.TeamMemberRole = userIdVSroleId.get(uid);
                        oppTeam.add(OppMember);  
                    }
                }
                
            }
            if(!oppTeam.isEmpty()){
                Insert oppTeam;
                
            }
            if (!oppShares.isEmpty()) {
                //insert oppShares;
            }
            
        }
        
        
        
        //Logic to update Opportunity Original Creator TeamMemberRole To its UserRole with Edit Access   
        
        Opportunity Opportunity = [SELECT Id,SE_Assigned__c,Account.OwnerId, CreatedById, OwnerId FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Id accountOwnerId  = Opportunity.Account.OwnerId;
        try {
            
            if(accountOwnerId != Opportunity.CreatedById){   
                System.debug('Opportunity.CreatedById------------>'+Opportunity.CreatedById);
                System.debug('Opportunity Account OwnerId---------------->'+accountOwnerId);
                // Apexify -- Surya -- Ticket #51 -- commented below code because the ownerId assignment is moved to oppCurrencyChangeTrigger before insert.
                /* Opportunity.OwnerId = accountOwnerId;
UPDATE Opportunity;*/
                
                User creatorUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :Opportunity.CreatedById LIMIT 1];
                User accOwner = [SELECT Id, UserRole.Name FROM User WHERE Id = :accountOwnerId LIMIT 1];
                
                System.debug('creatorUser---------------------->'+creatorUser);
                System.debug('creatorUser Role Name---------------------->'+creatorUser.UserRole.Name);
                System.debug('Opportunity Account Owner---------------------->'+accOwner);
                System.debug('newOppOwner Role Name---------------------->'+accOwner.UserRole.Name);
                
                // Check if the creator is already on the opportunity team
                List<OpportunityTeamMember> existingCreatorMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :Opportunity.Id  AND UserId = :Opportunity.CreatedById LIMIT 1];
                
                if (existingCreatorMember.isEmpty()) { // Apexify -- Surya -- Ticket #51 -- modified the if condition to check isEmpty
                    System.debug('existingCreatorMember-------------->'+existingCreatorMember);
                    // Update existing member
                    // Apexify -- Surya -- Ticket #51 -- commenting below code that updates the member and added logic to inset member.
                    /* OpportunityTeamMember member = existingCreatorMember[0];
member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
member.OpportunityAccessLevel = 'Edit';
update member;*/
                    OpportunityTeamMember member = new OpportunityTeamMember();
                    member.OpportunityId = opp.Id;
                    member.UserId = Opportunity.CreatedById;
                    member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                    member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                    insert member;
                    System.debug('Original creator member after updation of member role and access------>'+member);
                }          
            }
            
        } catch (Exception e) {
            System.debug('Error adding/updating creator on team: ' + e.getMessage());
        }
        
    }
    
    
    //For Creation Bill only Opportunities return if user has custom permission or not
    @AuraEnabled
    public static Boolean hasBillOnlyPermission() {
        return FeatureManagement.checkPermission('Bill_Only_Opportunity_Creation');
    }
    
    //Update Owner And Lead Source for Bill Only Opportunity 
    @AuraEnabled
    public static Void updateOppOwner(Id oppId) {
        Opportunity  opportunity = [ SELECT Account.OwnerId,OwnerId,LeadSource,CreatedById FROM Opportunity WHERE Id = : oppId LIMIT 1];
        opportunity.LeadSource = 'Bill-Only Order';
        if(opportunity.CreatedById != opportunity.Account.OwnerId ){
            opportunity.OwnerId = opportunity.Account.OwnerId;
        }
        update opportunity;
        
        if(opportunity.CreatedById != opportunity.Account.OwnerId ){
            User creatorUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :opportunity.CreatedById LIMIT 1];
            User accOwner = [SELECT Id, UserRole.Name FROM User WHERE Id = : opportunity.Account.OwnerId LIMIT 1];
            List<OpportunityTeamMember> existingCreatorMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :opportunity.Id  AND UserId = :opportunity.CreatedById LIMIT 1];
            
            if (existingCreatorMember.isEmpty()) { // Apexify -- Surya -- Ticket #51 -- modified the if condition to check isEmpty
                System.debug('existingCreatorMember-------------->'+existingCreatorMember);
                // Update existing member
                // Apexify -- Surya -- Ticket #51 -- commenting below code that updates the member.
                /* OpportunityTeamMember member = existingCreatorMember[0];
member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
member.OpportunityAccessLevel = 'Edit';
update member;*/
                OpportunityTeamMember member = new OpportunityTeamMember();
                member.OpportunityId = oppId;
                member.UserId = Opportunity.CreatedById;
                member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                insert member;
                System.debug('Original creator member after updation of member role and access------>'+member);
            }     
            
        }
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
    
    @AuraEnabled
    public static Boolean requiresCROApproval(Id quoteId) {
        
        Quote q = [
            SELECT Id, Status, OpportunityId
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        
        // Quote must NOT be Draft
        if (q.Status == 'Draft') return false;
        
        // Check Deal Registered on parent Opportunity
        Opportunity opp = [
            SELECT varcpq__Registered__c
            FROM Opportunity
            WHERE Id = :q.OpportunityId
            LIMIT 1
        ];
        
        // If Deal Registered = Yes → no CRO approval needed
        if (opp.varcpq__Registered__c == true) return false;
        
        // Fetch Quote Line Items
        for (QuoteLineItem item : [
            SELECT Quantity, Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ]) {
            
            String name = item.Product2.Name != null ? item.Product2.Name.toLowerCase() : '';
            
            if (name.contains('mac') && item.Quantity >= 25) return true;
            if (name.contains('ipad') && item.Quantity >= 50) return true;
            if (name.contains('iphone') && item.Quantity >= 100) return true;
        }
        
        return false;
    }
    
    public static Boolean alreadySubmitted(Id quoteId) {
        return [
            SELECT Id 
            FROM ProcessInstance 
            WHERE TargetObjectId = :quoteId
            LIMIT 1
        ].size() > 0;
    }
    
    
    
    
    
    
}