public with sharing class CreateAccountController {
    
    @AuraEnabled
    public static Boolean getUserProfileName() {
        String profName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profName == 'Clutch Default User') return true;
        return false;
    }
    
    @AuraEnabled
    public static List<RecordType> getAccountRecordTypes() {
        return [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND IsActive = true];
    }
    
    @AuraEnabled
    public static getPicklistValues getPickListValues() {
        List<String> netTerms = new List<String>();
        List<String> accTypes = new List<String>();
        Schema.DescribeFieldResult fieldResult = Account.varcpq__NET_TERMS__c .getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            netTerms.add(entry.getLabel());
        }
        Schema.DescribeFieldResult accTypeSchema = Account.Type.getDescribe();
        for (Schema.PicklistEntry entry : accTypeSchema.getPicklistValues()) {
            accTypes.add(entry.getLabel());
        }
        getPickListValues valList = new getPickListValues();
        valList.netTerms = netTerms;
        valList.accTypes = accTypes;
        
        return valList;
    }
    
    @AuraEnabled
    public static Id createAccountRecord(Account acc) {
        insert acc;
        return acc.Id;
    }
    
    public class getPicklistValues{
        @AuraEnabled public List<String> netTerms;
        @AuraEnabled public List<String> accTypes;
    }    
}