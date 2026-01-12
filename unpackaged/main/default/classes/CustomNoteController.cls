public with sharing class CustomNoteController {

    public class RecordContextWrapper {
        @AuraEnabled public Id recordId { get; set; }

        public String getSObjectType() {
            if (recordId != null) {
                try {
                    return recordId.getSObjectType().getDescribe().getName();
                } catch (Exception e) {
                    // In case the Id is invalid or cannot be resolved
                    return null;
                }
            }
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getSuppliersByCurrency(Id recordId) {
        if (recordId == null) {
            System.debug(' No recordId provided');
            return new List<Account>();
        }

        String sObjectTypeName;
        String currencyIsoCode;
        Set<Id> distributorIds = new Set<Id>();
        List<Account> finalSuppliers = new List<Account>();

        try {
            sObjectTypeName = recordId.getSObjectType().getDescribe().getName();
            System.debug(' SObject Type: ' + sObjectTypeName);

            String queryCurrency = 'SELECT CurrencyIsoCode FROM ' + sObjectTypeName + ' WHERE Id = :recordId LIMIT 1';
            SObject record = Database.query(queryCurrency);

            if (record.getSObjectType().getDescribe().fields.getMap().containsKey('CurrencyIsoCode')) {
                currencyIsoCode = (String)record.get('CurrencyIsoCode');
            } else {
                System.debug(' CurrencyIsoCode not found on record');
                return new List<Account>();
            }
        } catch (Exception e) {
            System.debug(' Error determining record type or currency: ' + e.getMessage());
            return new List<Account>();
        }

        //  If the record is a Quote, fetch distributor accounts from related products
        if (sObjectTypeName == 'Quote') {
            try {
                List<QuoteLineItem> qlis = [
                    SELECT Id, Product2Id,
                        Product2.varcpq__Distributor_Account__c
                    FROM QuoteLineItem
                    WHERE QuoteId = :recordId
                    AND Product2.varcpq__Distributor_Account__c != NULL
                ];

                for (QuoteLineItem qli : qlis) {
                    distributorIds.add(qli.Product2.varcpq__Distributor_Account__c);
                }

                if (!distributorIds.isEmpty()) {
                    List<Account> distributors = [
                        SELECT Id, Name
                        FROM Account
                        WHERE Id IN :distributorIds
                        ORDER BY Name
                    ];
                    finalSuppliers.addAll(distributors);
                    System.debug(' Distributors from products: ' + distributors.size());
                } else {
                    System.debug(' No distributors found on quote line products');
                }

            } catch (Exception e) {
                System.debug(' Error fetching product distributors: ' + e.getMessage());
            }
        }
        else if (sObjectTypeName == 'varcpq__Sales_Order__c') {
            try {
                List<varcpq__Sales_Order_Line_Item__c> solis = [
                    SELECT Id, varcpq__Product__c,
                         varcpq__Product__r.varcpq__Distributor_Account__c
                    FROM varcpq__Sales_Order_Line_Item__c
                    WHERE varcpq__Sales_Order__c = :recordId
                    AND varcpq__Product__r.varcpq__Distributor_Account__c != NULL
                ];

                for (varcpq__Sales_Order_Line_Item__c sli : solis) {
                    distributorIds.add(sli.varcpq__Product__r.varcpq__Distributor_Account__c);
                }

                if (!distributorIds.isEmpty()) {
                    List<Account> distributors = [
                        SELECT Id, Name
                        FROM Account
                        WHERE Id IN :distributorIds
                        ORDER BY Name
                    ];
                    finalSuppliers.addAll(distributors);
                    System.debug(' Distributors from products: ' + distributors.size());
                } else {
                    System.debug(' No distributors found on quote line products');
                }

            } catch (Exception e) {
                System.debug(' Error fetching product distributors: ' + e.getMessage());
            }
        }
        else if (sObjectTypeName == 'varcpq__Purchase_Order__c') {
            try {
                List<varcpq__Purchase_Order_Line_Item__c> polis = [
                    SELECT Id,varcpq__Sales_Order_Line_Item__r.varcpq__Product__r.varcpq__Distributor_Account__c, varcpq__Part_No__c 
                    FROM varcpq__Purchase_Order_Line_Item__c 
                    where varcpq__Purchase_Order__c = :recordId
                    AND varcpq__Sales_Order_Line_Item__r.varcpq__Product__r.varcpq__Distributor_Account__c != NULL
                ];

                for (varcpq__Purchase_Order_Line_Item__c pli : polis) {
                    distributorIds.add(pli.varcpq__Sales_Order_Line_Item__r.varcpq__Product__r.varcpq__Distributor_Account__c);
                }

                if (!distributorIds.isEmpty()) {
                    List<Account> distributors = [
                        SELECT Id, Name
                        FROM Account
                        WHERE Id IN :distributorIds
                        ORDER BY Name
                    ];
                    finalSuppliers.addAll(distributors);
                    System.debug(' Distributors from products: ' + distributors.size());
                } else {
                    System.debug(' No distributors found on quote line products');
                }

            } catch (Exception e) {
                System.debug(' Error fetching product distributors: ' + e.getMessage());
            }
        }

        //  Fetch other suppliers with same currency, excluding above
        try {
            List<Account> otherSuppliers = [
                SELECT Id, Name
                FROM Account
                WHERE Type = 'Supplier'
                AND CurrencyIsoCode = :currencyIsoCode
                AND Id NOT IN :distributorIds
                ORDER BY Name
            ];
            finalSuppliers.addAll(otherSuppliers);
            System.debug(' Additional suppliers: ' + otherSuppliers.size());
        } catch (Exception e) {
            System.debug('Error fetching other suppliers: ' + e.getMessage());
        }

        return finalSuppliers;
    }


    @AuraEnabled
    public static void saveNoteRecord(String title, String body, String notetype, String supplier, RecordContextWrapper context) {
        if (String.isBlank(body)) {
            throw new AuraHandledException('Title and Body are required.');
        }
        if (context == null || context.recordId == null) {
            throw new AuraHandledException('Invalid parent record context.');
        }

        Custom_Note__c note = new Custom_Note__c();
        note.Title__c = title;
        note.Compose_Text__c = body;
        note.Note_Type__c = notetype;
        note.Supplier__c = supplier;

        String parentSObjectName = context.getSObjectType();

        if (String.isBlank(parentSObjectName)) {
            throw new AuraHandledException('Could not determine SObject type from parent record Id.');
        }

        Schema.DescribeSObjectResult noteDescribe = Custom_Note__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = noteDescribe.fields.getMap();

        Boolean foundMatch = false;
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();

            if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
                List<Schema.SObjectType> referenceToTypes = fieldDescribe.getReferenceTo();

                for (Schema.SObjectType refType : referenceToTypes) {
                    if (refType.getDescribe().getName() == parentSObjectName) {
                        note.put(fieldName, context.recordId);
                        foundMatch = true;
                        break;
                    }
                }
                if (foundMatch) break;
            }
        }

        if (!foundMatch) {
            throw new AuraHandledException('No matching lookup field found on Custom_Note__c for parent object: ' + parentSObjectName);
        }

        insert note;
    }


    @AuraEnabled(cacheable=true)
    public static List<String> getNoteTypePicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Custom_Note__c.Note_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getLabel());
        }
        return values;
    }


    @AuraEnabled(cacheable=true)
    public static List<Custom_Note__c> getNotesForRecord(Id parentId) {
        return [
            SELECT Id, Title__c, Compose_Text__c, Note_Type__c, CreatedDate
            FROM Custom_Note__c
            WHERE Sales_Order__c = :parentId
            ORDER BY CreatedDate DESC
        ];
    }
    
     @TestVisible
    public static String exposeGetSObjectTypeFromId(Id recordId) {
        return getSObjectTypeFromId(recordId);
    }


    // Helper method to determine SObject type from record Id safely
    private static String getSObjectTypeFromId(Id recordId) {
        if (recordId == null) return null;

        String prefix = String.valueOf(recordId).substring(0, 3);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (Schema.SObjectType sObjType : globalDescribe.values()) {
            Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
            if (describeResult.getKeyPrefix() == prefix) {
                return describeResult.getName();
            }
        }

        return null;
    }


}