global class ReassignSFObjectsBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, ManagerId 
            FROM User 
            WHERE IsActive = FALSE 
            AND ManagerId != NULL
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<Id, Id> userToManagerMap = new Map<Id, Id>();
        for (SObject s : scope) {
            User u = (User)s;
            userToManagerMap.put(u.Id, u.ManagerId);
        }

        if (userToManagerMap.isEmpty()) return;

        Set<Id> deactivatedUserIds = userToManagerMap.keySet();

        // --- Get distributor-linked account IDs from metadata ---
        Set<Id> distributorLinkedAccountIds = new Set<Id>();
        for (varcpq__Distributor_Detail__mdt distMeta : [
            SELECT varcpq__Distributor_Account_Id__c
            FROM varcpq__Distributor_Detail__mdt
        ]) {
            if (distMeta.varcpq__Distributor_Account_Id__c != null) {
                distributorLinkedAccountIds.add(distMeta.varcpq__Distributor_Account_Id__c);
            }
        }

        // --- Reassign Accounts (exclude distributor-linked ones) ---
        List<Account> accsToUpdate = new List<Account>();
        for (Account acc : [
            SELECT Id, OwnerId,varcpq__Available_for_PO__c
            FROM Account 
            WHERE OwnerId IN :deactivatedUserIds
        ]) {
            if (!distributorLinkedAccountIds.contains(acc.Id) && acc.varcpq__Available_for_PO__c == true) {
                acc.OwnerId = userToManagerMap.get(acc.OwnerId);
                accsToUpdate.add(acc);
            }
        }
        
         // --- Reassign Contacts ---
        List<Contact> contToUpdate = [
            SELECT Id, OwnerId 
            FROM Contact 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (Contact con : contToUpdate) {
            con.OwnerId = userToManagerMap.get(con.OwnerId);
        }

        // --- Reassign Opportunities ---
        List<Opportunity> oppsToUpdate = [
            SELECT Id, OwnerId 
            FROM Opportunity 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (Opportunity opp : oppsToUpdate) {
            opp.OwnerId = userToManagerMap.get(opp.OwnerId);
        }

        // --- Reassign Leads ---
        List<Lead> leadsToUpdate = [
            SELECT Id, OwnerId 
            FROM Lead 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (Lead l : leadsToUpdate) {
            l.OwnerId = userToManagerMap.get(l.OwnerId);
        }

        // --- Reassign Quotes ---
        List<Quote> quotesToUpdate = [
            SELECT Id, OwnerId 
            FROM Quote 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (Quote q : quotesToUpdate) {
            q.OwnerId = userToManagerMap.get(q.OwnerId);
        }

        // --- Reassign Cases ---
        List<Case> casesToUpdate = [
            SELECT Id, OwnerId 
            FROM Case 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (Case c : casesToUpdate) {
            c.OwnerId = userToManagerMap.get(c.OwnerId);
        }

        
        // --- Reassign Account Payabale Invoice ---
        List<varcpq__Accounts_Payable_Invoice__c> apisToUpdate = [
            SELECT Id, OwnerId 
            FROM varcpq__Accounts_Payable_Invoice__c 
            WHERE OwnerId IN :deactivatedUserIds
        ];
        for (varcpq__Accounts_Payable_Invoice__c api : apisToUpdate) {
            api.OwnerId = userToManagerMap.get(api.OwnerId);
        }
        
        
        // --- DML Updates ---
        if (!accsToUpdate.isEmpty()) update accsToUpdate;
        if (!contToUpdate.isEmpty()) update contToUpdate;
        if (!oppsToUpdate.isEmpty()) update oppsToUpdate;
        if (!leadsToUpdate.isEmpty()) update leadsToUpdate;
        if (!quotesToUpdate.isEmpty()) update quotesToUpdate;
        if (!casesToUpdate.isEmpty()) update casesToUpdate;
        if (!apisToUpdate.isEmpty()) update apisToUpdate;

    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Reassignment of records from deactivated users to their managers is complete.');
    }
}