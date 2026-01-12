trigger SetAccountFields on Account (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

        // Get all Account record types
        List<RecordType> recordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SobjectType = 'Account'
        ];
        
        // Map RecordTypeId to RecordType Name
        Map<Id, String> recTypeMap = new Map<Id, String>();
        for (RecordType rt : recordTypes) {
            recTypeMap.put(rt.Id, rt.Name);
        }

        // Get AvaTax company codes
        List<AVA_SFCLOUD__AvaTaxCompany__c> avaCompanyCodes = [
            SELECT Id, Name 
            FROM AVA_SFCLOUD__AvaTaxCompany__c
        ];
        
        // Map AvaTax company name to Id
        Map<String, Id> avaCCMap = new Map<String, Id>();
        for (AVA_SFCLOUD__AvaTaxCompany__c atc : avaCompanyCodes) {
            avaCCMap.put(atc.Name, atc.Id);
        }

        // Loop through each Account record
        for (Account acct : Trigger.new) {
            String recTypeName = recTypeMap.get(acct.RecordTypeId);

            // Set Record_Type__c based on RecordType
            acct.Record_Type__c = recTypeName;

            // Set AvaTax Company Code based on RecordType
            if (recTypeName == 'Canadian Account') {
                acct.AvaTax_Company_Code__c = avaCCMap.get('CLUTCH SOLUTIONS CA INC');
            } else if (recTypeName == 'US Account') {
                acct.AvaTax_Company_Code__c = avaCCMap.get('CLUTCH SOLUTIONS LLC');
            }
        }
    }
}