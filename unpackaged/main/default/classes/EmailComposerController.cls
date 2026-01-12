public with sharing class EmailComposerController {
    @TestVisible
    private static final String EMAIL_SENT_STATUS = '3';
    
    @AuraEnabled(cacheable=true)
    public static List<Object_Prefix_Mapping__mdt> getObjectPrefixMappings() {
        System.debug(LoggingLevel.ERROR, '>>> Fetching Object Prefix Mappings');
        return [
            SELECT Prefix__c, Object_API_Name__c
            FROM Object_Prefix_Mapping__mdt
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Email_Configuration__mdt getEmailConfiguration(
        String objectApiName
    ) {
        System.debug(
            LoggingLevel.ERROR,
            '>>> Getting email config for: ' + objectApiName
        );
        try {
            Email_Configuration__mdt config = [
                SELECT
                Object_API_Name__c,
                Template_Name__c,
                HTML_Template__c,
                Plain_Text_Template__c,
                CSS_Styles__c,
                Required_Fields__c,
                Default_Subject__c,
                Account_Relationship_Path__c,
                Save_Email_Message__c,
                Default_To_Field__c,
                File_Name_Prefix__c,
                Merge_Fields_Query__c,
                EmailMessage_Related_Field_API_Name__c,
                Status_Field_API_Name__c,
                Status_Value_after_Send__c,
                Status_Checkbox_Label__c,
                Attachment_Field_API_Name__c,
                Allow_Multiple_Attachment__c
                FROM Email_Configuration__mdt
                WHERE Object_API_Name__c = :objectApiName
                LIMIT 1
            ];
            System.debug(LoggingLevel.ERROR, '>>> Found config: ' + config);
            return config;
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                '>>> Error getting config: ' + e.getMessage()
            );
            throw new AuraHandledException(
                'No email configuration found for: ' + objectApiName
            );
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Email_Signature__mdt getEmailSignature() {
        System.debug(LoggingLevel.ERROR, '>>> Getting email signature');
        String userProfileName = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ]
            .Profile.Name;
        System.debug(LoggingLevel.ERROR, '>>> User Profile: ' + userProfileName);
        
        List<Email_Signature__mdt> signatures = [
            SELECT
            HTML_Signature__c,
            Plain_Text_Signature__c,
            CSS_Styles__c,
            Profile_Filter__c
            FROM Email_Signature__mdt
        ];
        
        for (Email_Signature__mdt sig : signatures) {
            if (
                String.isBlank(sig.Profile_Filter__c) ||
                sig.Profile_Filter__c.split(',').contains(userProfileName)
            ) {
                System.debug(LoggingLevel.ERROR, '>>> Found matching signature');
                return sig;
            }
        }
        System.debug(LoggingLevel.ERROR, '>>> No matching signature found');
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEmailContent(
        Id recordId,
        Id userId,
        String templateName
    ) {
        System.debug(
            LoggingLevel.ERROR,
            '>>> Getting email content for record: ' + recordId
        );
        
        try {
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            Email_Configuration__mdt config = getEmailConfiguration(objectApiName);
            
            String defaultToEmail;
            if (String.isNotBlank(config.Default_To_Field__c)) {
                // Improved field lookup logic
                if (config.Default_To_Field__c.contains('.')) {
                    // Handle relationship fields (e.g., "Contact.Email")
                    String query = 'SELECT ' + config.Default_To_Field__c + 
                        ' FROM ' + objectApiName + 
                        ' WHERE Id = :recordId';
                    
                    System.debug(LoggingLevel.ERROR, '>>> Default email query: ' + query);
                    SObject record = Database.query(query);
                    
                    // Traverse the relationship path
                    String[] fields = config.Default_To_Field__c.split('\\.');
                    SObject currentObj = record;
                    for (Integer i = 0; i < fields.size() - 1; i++) {
                        if (currentObj == null) break;
                        currentObj = currentObj.getSObject(fields[i]);
                    }
                    
                    // Get the final field value if the path exists
                    if (currentObj != null) {
                        defaultToEmail = (String) currentObj.get(fields[fields.size() - 1]);
                    }
                } else {
                    // Simple field reference (e.g., "Bill_to_email__c" or "Ship_to_email__c")
                    String query = 'SELECT ' + config.Default_To_Field__c + 
                        ' FROM ' + objectApiName + 
                        ' WHERE Id = :recordId';
                    
                    System.debug(LoggingLevel.ERROR, '>>> Default email query: ' + query);
                    SObject record = Database.query(query);
                    defaultToEmail = (String) record.get(config.Default_To_Field__c);
                }
                System.debug(LoggingLevel.ERROR, '>>> Default To Email: ' + defaultToEmail);
            }
            
            Map<String, Object> recordData = getRecordData(recordId, config);
            Map<String, Object> mergeData = new Map<String, Object>(recordData);
            
            User currentUser = [
                SELECT Name, Title, Phone, Email
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
            mergeData.put('User', currentUser);
            
            Organization org = [SELECT Name FROM Organization LIMIT 1];
            mergeData.put('Organization', org);
            
            List<Contact> contacts = getRelatedContacts(recordId, config);
            List<ContentDocumentLink> files = [
                SELECT
                ContentDocumentId,
                ContentDocument.Title,
                ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                ORDER BY ContentDocument.CreatedDate DESC
            ];
            
            String mergedHtmlBody = mergeTemplate(config.HTML_Template__c, mergeData);
            Email_Signature__mdt signature = getEmailSignature();
            if (signature != null) {
                mergedHtmlBody += mergeTemplate(signature.HTML_Signature__c, mergeData);
            }
            
            String mergedPlainText = mergeTemplate(
                config.Plain_Text_Template__c,
                mergeData
            );
            if (signature != null) {
                mergedPlainText +=
                    '\n\n' + mergeTemplate(signature.Plain_Text_Signature__c, mergeData);
            }
            
            String mergedSubject = mergeTemplate(
                config.Default_Subject__c,
                mergeData
            );
            
            Map<Id,Map<String, String>> formattedContacts = formatContactsForDisplay(
                contacts
            );
            Map<String, Object> latestPDF = getLatestPDFAttachment(recordId, config);
            System.debug('latestpdf '+latestpdf);
            return new Map<String, Object>{
                'ownerEmail' => UserInfo.getUserEmail(),
                    'subject' => mergedSubject,
                    'htmlBody' => mergedHtmlBody,
                    'plainTextBody' => mergedPlainText,
                    'contactList' => formattedContacts,
                    'files' => files,
                    'defaultToEmail' => defaultToEmail,
                    'latestPDF' => latestPDF
                    };
                        } catch (Exception e) {
                            System.debug(
                                LoggingLevel.ERROR,
                                '>>> Error in getEmailContent: ' + e.getMessage()
                            );
                            System.debug(
                                LoggingLevel.ERROR,
                                '>>> Stack trace: ' + e.getStackTraceString()
                            );
                            throw new AuraHandledException(e.getMessage());
                        }
    }
    
    private static Map<String, Object> getRecordData(
        Id recordId,
        Email_Configuration__mdt config
    ) {
        Set<String> queryFields = new Set<String>{ 'Id' };
            if (String.isNotBlank(config.Required_Fields__c)) {
                queryFields.addAll(config.Required_Fields__c.split(','));
            }
        if (String.isNotBlank(config.Merge_Fields_Query__c)) {
            queryFields.addAll(config.Merge_Fields_Query__c.split(','));
        }
        
        System.debug('Query Fields before processing: ' + queryFields);
        
        // Process fields to ensure proper relationship syntax
        Set<String> processedFields = new Set<String>();
        for (String field : queryFields) {
            if (field.contains('__c.')) {
                // Convert CustomObject__c.Field to CustomObject__r.Field for relationships
                processedFields.add(field.replaceFirst('__c\\.', '__r.'));
            } else {
                processedFields.add(field);
            }
        }
        
        String query =
            'SELECT ' +
            String.join(new List<String>(processedFields), ',') +
            ' FROM ' +
            recordId.getSObjectType().getDescribe().getName() +
            ' WHERE Id = :recordId';
        
        System.debug(LoggingLevel.ERROR, '>>> Record query: ' + query);
        
        try {
            SObject record = Database.query(query);
            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('Id', record.get('Id'));
            
            // Process all fields including relationship fields
            processRecordFields(record, resultMap);
            
            // Fixed: Now both sides of the ternary return a String
            System.debug(LoggingLevel.ERROR, '>>> Result Map (Sample): ' + 
                         (resultMap.size() > 5 ? 'Map too large to display' : String.valueOf(resultMap)));
            
            return resultMap;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '>>> Query Error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, '>>> Query: ' + query);
            throw new AuraHandledException(
                'Error querying record data: ' + e.getMessage()
            );
        }
    }
    
    // Method to process record fields and build a structured map
    private static void processRecordFields(SObject record, Map<String, Object> resultMap) {
        if (record == null) return;
        
        Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Object fieldValue = fieldMap.get(fieldName);
            
            // Store the direct field
            resultMap.put(fieldName, fieldValue);
            
            // Process relationship fields
            if (fieldValue instanceof SObject) {
                // For SObject relationship fields, create a nested map
                Map<String, Object> relationshipMap = new Map<String, Object>();
                processRecordFields((SObject)fieldValue, relationshipMap);
                
                // Add the relationship map to the result
                resultMap.put(fieldName, relationshipMap);
            }
        }
    }
    
    private static List<Contact> getRelatedContacts(
        Id recordId,
        Email_Configuration__mdt config
    ) {
        System.debug(LoggingLevel.ERROR, '>>> Getting related contacts');
        try {
            String relationshipPath = config.Account_Relationship_Path__c;
            if (String.isBlank(relationshipPath)) {
                return new List<Contact>();
            }
            
            String baseObjectType = recordId.getSObjectType().getDescribe().getName();
            String query =
                'SELECT ' +
                relationshipPath +
                ' FROM ' +
                baseObjectType +
                ' WHERE Id = :recordId';
            
            System.debug(LoggingLevel.ERROR, '>>> Contact query: ' + query);
            SObject record = Database.query(query);
            Id accountId = traverseRelationshipPath(record, relationshipPath);
            System.debug(LoggingLevel.ERROR, '>>> Account Id: ' + accountId);
            
            if (accountId != null) {
                List<Contact> contacts = [
                    SELECT Id, Name, Email, Title
                    FROM Contact
                    WHERE AccountId = :accountId AND Email != NULL
                    ORDER BY Name
                ];
                System.debug(
                    LoggingLevel.ERROR,
                    '>>> Found contacts: ' + contacts.size()
                );
                return contacts;
            }
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                '>>> Error getting contacts: ' + e.getMessage()
            );
        }
        return new List<Contact>();
    }
    
    private static Id traverseRelationshipPath(SObject record, String path) {
        if (record == null || String.isBlank(path))
            return null;
        
        List<String> pathParts = path.split('\\.');
        SObject currentRecord = record;
        
        for (Integer i = 0; i < pathParts.size() - 1; i++) {
            currentRecord = currentRecord.getSObject(pathParts[i]);
            if (currentRecord == null)
                return null;
        }
        
        return (Id) currentRecord.get(pathParts[pathParts.size() - 1]);
    }
    
    /*private static List<Map<String, String>> formatContactsForDisplay(
List<Contact> contacts
) {
List<Map<String, String>> formatted = new List<Map<String, String>>();

for (Contact contact : contacts) {
if (String.isNotBlank(contact.Email)) {
formatted.add(
new Map<String, String>{
'label' => contact.Name +
' • ' +
contact.Email,
'value' => contact.Email
}
);
}
}
formatted.add(new Map<String,String>{'label'=>UserInfo.getName()+' • '+UserInfo.getUserEmail(),'value'=>UserInfo.getUserEmail()});
return formatted;
}*/
    
    private static Map<Id,Map<String, String>> formatContactsForDisplay(List<Contact> contacts) {
        Map<Id,Map<String, String>> formatted = new Map<Id,Map<String, String>>();
        
        for (Contact contact : contacts) {
            if (String.isNotBlank(contact.Email)) {
                formatted.put(contact.Id,new Map<String, String>{'label' => contact.Name +' • ' +contact.Email,'value' => contact.Email});
            }
        }
        formatted.put(UserInfo.getUserId(), new Map<String,String>{'label'=>UserInfo.getName()+' • '+UserInfo.getUserEmail(),'value'=>UserInfo.getUserEmail()});
        return formatted;
    }
    // Updated mergeTemplate method with improved relationship field handling
    private static String mergeTemplate(
        String template,
        Map<String, Object> recordData
    ) {
        if (String.isBlank(template))
            return '';
        
        System.debug(LoggingLevel.ERROR, '>>> Merging template with data');
        
        Pattern pattern = Pattern.compile('\\{!(.*?)\\}');
        Matcher matcher = pattern.matcher(template);
        
        while (matcher.find()) {
            String fullMatch = matcher.group(0); // {!Field.Path}
            String fieldPath = matcher.group(1); // Field.Path
            
            // Navigate the relationship chain
            String value = navigateFieldPath(recordData, fieldPath);
            if (value != null) {
                template = template.replace(fullMatch, value);
            } else {
                System.debug(LoggingLevel.ERROR, '>>> Could not resolve merge field: ' + fieldPath);
            }
        }
        
        return template;
    }
    
    // New method to navigate through relationship fields
    private static String navigateFieldPath(Map<String, Object> data, String fieldPath) {
        List<String> parts = fieldPath.split('\\.');
        
        if (parts.size() == 1) {
            // Simple field
            Object value = data.get(parts[0]);
            return value != null ? String.valueOf(value) : null;
        }
        
        // Navigate through relationships
        Object current = data.get(parts[0]);
        
        // Debug the first level object
        System.debug(LoggingLevel.ERROR, '>>> First level object ' + parts[0] + ': ' + 
                     (current != null ? 
                      (current instanceof SObject ? 'SObject' : 
                       (current instanceof Map<String, Object> ? 'Map' : 'Other Type')) : 'null'));
        
        for (Integer i = 1; i < parts.size(); i++) {
            if (current == null) return null;
            
            if (current instanceof Map<String, Object>) {
                // If we have a map, get the next level
                current = ((Map<String, Object>)current).get(parts[i]);
                System.debug(LoggingLevel.ERROR, '>>> Map navigation level ' + i + ' (' + parts[i] + '): ' + 
                             (current != null ? 'Found' : 'Not found'));
            } else if (current instanceof SObject) {
                // If we have an SObject, get the field
                current = ((SObject)current).get(parts[i]);
                System.debug(LoggingLevel.ERROR, '>>> SObject navigation level ' + i + ' (' + parts[i] + '): ' + 
                             (current != null ? 'Found' : 'Not found'));
            } else {
                // Can't navigate further
                System.debug(LoggingLevel.ERROR, '>>> Cannot navigate: ' + parts[i] + ' from object type: ' + 
                             (current != null ? String.valueOf(current) : 'null'));
                return null;
            }
        }
        
        return current != null ? String.valueOf(current) : null;
    }
    
    private static void updateAttachmentField(
        String recordId,
        List<String> fileNames,
        Email_Configuration__mdt config
    ) {
        if (String.isBlank(config.Attachment_Field_API_Name__c)) {
            return;
        }
        
        try {
            // Get the current field value
            String query =
                'SELECT ' +
                config.Attachment_Field_API_Name__c +
                ' FROM ' +
                config.Object_API_Name__c +
                ' WHERE Id = :recordId';
            SObject record = Database.query(query);
            
            // Get existing value and append new filename
            String currentValue = (String) record.get(
                config.Attachment_Field_API_Name__c
            );
            
            /*String newValue = String.isBlank(currentValue)
? fileName + ';'
: currentValue + fileName + ';';*/
            
            String newValue = String.isBlank(currentValue) ? '' : currentValue;
            
            for (String fileName : fileNames) {
                newValue += fileName + ';';
            }
            
            // Update the record
            record.put(config.Attachment_Field_API_Name__c, newValue);
            update record;
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error updating attachment field: ' + e.getMessage()
            );
            throw new AuraHandledException(
                'Failed to update attachment field: ' + e.getMessage()
            );
        }
    }
    
    private static List<String> handleAttachments(
        Map<String, Object> emailData,
        Messaging.SingleEmailMessage email
    ) {
        System.debug(LoggingLevel.ERROR, '>>> Processing attachments');
        List<String> contentDocumentIds = new List<String>();
        
        if (
            emailData.containsKey('attachmentId') &&
            emailData.get('attachmentId') != null
        ) {
            System.debug('attachments '+emailData.get('attachmentId'));
            List<String> attachmentIds = (List<String>) JSON.deserialize(JSON.serialize(emailData.get('attachmentId')), List<String>.class);
            List<ContentVersion> cvs = [
                SELECT Id, Title, VersionData, FileType, ContentDocument.Title, FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId = :attachmentIds AND IsLatest = TRUE];
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            List<String> fileNames = new List<String>();
            for(ContentVersion cv : cvs){
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                String fileName = cv.Title;
                Integer lastDot = fileName.lastIndexof('.');
                if(lastDot == -1 || lastDot == 0 || lastDot == filename.length() - 1){
                    fileName += '.'+ cv.FileExtension;
                }
                System.debug('filename '+fileName);
                attachment.setFileName(fileName);
                attachment.setBody(cv.VersionData);
                attachment.setContentType(getContentTypeByFileExtension(cv.FileExtension));
                attachments.add(attachment);
                fileNames.add(fileName);
            }
            email.setFileAttachments(attachments);
            system.debug('Attachment--->' +attachments) ;
            contentDocumentIds = attachmentIds;
            // Get record ID and config from emailData
            String recordId = (String) emailData.get('recordId');
            String objectApiName = (String) emailData.get('objectApiName');
            Email_Configuration__mdt config = getEmailConfiguration(objectApiName);
            
            // Update attachment field if configured
            if (config.Attachment_Field_API_Name__c != null) {
                updateAttachmentField(recordId, fileNames, config);
            }
        }
        return contentDocumentIds;
        /*String attachmentId = (String) emailData.get('attachmentId');
ContentVersion cv = [
SELECT Id, Title, VersionData, FileType, ContentDocument.Title
FROM ContentVersion
WHERE ContentDocumentId = :attachmentId AND IsLatest = TRUE
LIMIT 1
];

Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
String fileName = cv.Title;
attachment.setFileName(fileName);
attachment.setBody(cv.VersionData);
email.setFileAttachments(
new List<Messaging.EmailFileAttachment>{ attachment }
);
contentDocumentIds.add(attachmentId);

// Get record ID and config from emailData
String recordId = (String) emailData.get('recordId');
String objectApiName = (String) emailData.get('objectApiName');
Email_Configuration__mdt config = getEmailConfiguration(objectApiName);

// Update attachment field if configured
if (config.Attachment_Field_API_Name__c != null) {
updateAttachmentField(recordId, fileName, config);
}
}
return contentDocumentIds;*/
    }
    
    @AuraEnabled
    public static void sendEmail(String emailContent) {
        System.debug(LoggingLevel.ERROR, '>>> Starting sendEmail');
        try {
            Map<String, Object> emailData = (Map<String, Object>) JSON.deserializeUntyped(
                emailContent
            );
            String recordId = (String) emailData.get('recordId');
            String objectApiName = (String) emailData.get('objectApiName');
            
            System.debug(LoggingLevel.ERROR, '>>> Record Id: ' + recordId);
            System.debug(LoggingLevel.ERROR, '>>> Object API Name: ' + objectApiName);
            
            Email_Configuration__mdt config = getEmailConfiguration(objectApiName);
            Messaging.SingleEmailMessage email = createEmailMessage(emailData);
            List<String> contentDocumentIds = handleAttachments(emailData, email);
            System.debug('EMAIL --->>'+email);
            System.debug(LoggingLevel.ERROR, '>>> Sending email');
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ email },
                false
            );
            
            if (!results[0].isSuccess()) {
                String errorMsg = String.join(results[0].getErrors(), ', ');
                System.debug(LoggingLevel.ERROR, '>>> Email send failed: ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
            //KD's development
            if (results[0].isSuccess()) {
                if (objectApiName == 'Quote') {
                    //getSODefaultFiles(contentDocumentIds,recordId);
                }
            }
            
            System.debug(LoggingLevel.ERROR, '>>> Email sent successfully');
            if (config.Save_Email_Message__c) {
                System.debug(LoggingLevel.ERROR, '>>> Saving email message');
                saveEmailMessage(recordId, email, contentDocumentIds, config);
            }
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                '>>> Error in sendEmail: ' + e.getMessage()
            );
            System.debug(
                LoggingLevel.ERROR,
                '>>> Stack trace: ' + e.getStackTraceString()
            );
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static Map<String, Object> getLatestPDFAttachment(
        Id recordId,
        Email_Configuration__mdt config
    ) {
        if (String.isBlank(config.File_Name_Prefix__c)) {
            return null;
        }
        
        List<Map<String, Object>> allPDFs = getPDFAttachments(recordId, config);
        return !allPDFs.isEmpty() ? allPDFs[0] : null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRelatedPDFs(Id recordId) {
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        Email_Configuration__mdt config = getEmailConfiguration(objectApiName);
        if(objectApiName == 'varcpq__Purchase_Order__c'){
            varcpq__Purchase_Order__c po = [SELECT Id, varcpq__Sales_Order__c FROM varcpq__Purchase_Order__c WHERE Id=: recordId];
            return getPDFAttachmentsforPO(new Set<Id>{recordId,po.varcpq__Sales_Order__c});
        }
        return getPDFAttachments(recordId, config);
    }
    
    private static List<Map<String, Object>> getPDFAttachments(
        Id recordId,
        Email_Configuration__mdt config
    ) {
        if (String.isBlank(config.File_Name_Prefix__c)) {
            return new List<Map<String, Object>>();
        }
        
        List<Map<String, Object>> files = new List<Map<String, Object>>();
        
        List<ContentDocumentLink> links = [
            SELECT
            ContentDocument.Id,
            ContentDocument.Title,
            ContentDocument.FileType,
            ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE
            LinkedEntityId = :recordId
            AND ContentDocument.FileType = 'PDF'
            AND ContentDocument.Title LIKE :(config.File_Name_Prefix__c + '%')
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        
        for (ContentDocumentLink link : links) {
            files.add(
                new Map<String, Object>{
                    'id' => link.ContentDocument.Id,
                        'title' => link.ContentDocument.Title,
                        'label' => link.ContentDocument.Title,
                        'value' => link.ContentDocument.Id
                        }
            );
        }
        
        return files;
    }
    private static List<Map<String, Object>> getPDFAttachmentsforPO(Set<Id> recordIds) {
        
        
        List<Map<String, Object>> files = new List<Map<String, Object>>();
        
        List<ContentDocumentLink> links = [
            SELECT
            ContentDocument.Id,
            ContentDocument.Title,
            ContentDocument.FileType,
            ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE
            LinkedEntityId = :recordIds
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        
        for (ContentDocumentLink link : links) {
            files.add(
                new Map<String, Object>{
                    'id' => link.ContentDocument.Id,
                        'title' => link.ContentDocument.Title,
                        'label' => link.ContentDocument.Title,
                        'value' => link.ContentDocument.Id
                        }
            );
        }
        
        return files;
    }
    
    private static Messaging.SingleEmailMessage createEmailMessage(
        Map<String, Object> emailData
    ) {
        System.debug(LoggingLevel.ERROR, '>>> Creating email message');
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        Object toEmailObj = emailData.get('toEmail');
        List<String> toAddresses = toEmailObj instanceof List<Object>
            ? convertToStringList((List<Object>) toEmailObj)
            : (List<String>) toEmailObj;
        email.setToAddresses(toAddresses);
        
        if (emailData.containsKey('ccEmail')) {
            Object ccEmailObj = emailData.get('ccEmail');
            List<String> ccAddresses = ccEmailObj instanceof List<Object>
                ? convertToStringList((List<Object>) ccEmailObj)
                : (List<String>) ccEmailObj;
            email.setCcAddresses(ccAddresses);
        }
        
        if (emailData.containsKey('bccEmail')) {
            Object bccEmailObj = emailData.get('bccEmail');
            List<String> bccAddresses = bccEmailObj instanceof List<Object>
                ? convertToStringList((List<Object>) bccEmailObj)
                : (List<String>) bccEmailObj;
            email.setBccAddresses(bccAddresses);
        }
        
        email.setSubject((String) emailData.get('subject'));
        email.setHtmlBody((String) emailData.get('htmlBody'));
        email.setPlainTextBody((String) emailData.get('plainTextBody'));
        
        return email;
    }
    
    private static void saveEmailMessage(
        Id recordId,
        Messaging.SingleEmailMessage email,
        List<String> contentDocumentIds,
        Email_Configuration__mdt config
    ) {
        try{
            System.debug(LoggingLevel.ERROR, '>>> Starting saveEmailMessage');
            
            Map<String, Schema.SObjectField> emailMessageFields = Schema.SObjectType.EmailMessage.fields.getMap();
            System.debug(
                LoggingLevel.ERROR,
                '>>> EmailMessage fields: ' + emailMessageFields.keySet()
            );
            
            EmailMessage emailMsg = new EmailMessage(
                Subject = email.getSubject(),
                HtmlBody = email.getHtmlBody(),
                TextBody = email.getPlainTextBody(),
                ToAddress = String.join(email.getToAddresses(), ';'),
                CcAddress = email.getCcAddresses() != null
                ? String.join(email.getCcAddresses(), ';')
                : null,
                BccAddress = email.getBccAddresses() != null
                ? String.join(email.getBccAddresses(), ';')
                : null,
                FromAddress = UserInfo.getUserEmail(),
                FromName = UserInfo.getName(),
                Status = EMAIL_SENT_STATUS,
                MessageDate = Datetime.now(),
                RelatedToId = recordId
            );
            System.debug('email message '+emailMsg);
            String relatedField = config.EmailMessage_Related_Field_API_Name__c;
            if (String.isNotBlank(relatedField)) {
                System.debug(
                    LoggingLevel.ERROR,
                    '>>> Setting related field: ' + relatedField + ' = ' + recordId
                );
                emailMsg.put(relatedField, recordId);
            }
            
            System.debug(LoggingLevel.ERROR, '>>> Inserting EmailMessage');
            insert emailMsg;
            System.debug('email msg id '+emailMsg.Id);
            if (!contentDocumentIds.isEmpty()) {
                System.debug('cdocs '+contentDocumentIds);
                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (String docId : contentDocumentIds) {
                    if(docId != null){
                        links.add(
                            new ContentDocumentLink(
                                LinkedEntityId = emailMsg.Id,
                                ContentDocumentId = docId,
                                ShareType = 'V',
                                Visibility = 'AllUsers'
                            )
                        );
                    }
                }
                System.debug('links '+links);
                if(!links.isEmpty()){
                    insert links;
                }
                
            }
        }
        catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                '>>> Error in saveEmailMessage: ' + e.getMessage()
            );
            System.debug(
                LoggingLevel.ERROR,
                '>>> Stack trace: ' + e.getStackTraceString()
            );
            throw new AuraHandledException('Error saving email: ' + e.getMessage());
        }
    }
    
    private static List<String> convertToStringList(List<Object> objList) {
        List<String> strList = new List<String>();
        for (Object obj : objList) {
            strList.add(String.valueOf(obj));
        }
        return strList;
    }
    
    @testVisible
    private static void getSODefaultFiles(
        List<Id> contentDocumentIds,
        String quoteId
    ) {
        Quote quote = [
            SELECT Id, Sales_Order_Default_Files__c
            FROM Quote
            WHERE Id = :quoteId
        ];
        System.debug('Quote ' + quote);
        List<ContentDocument> docInfo = [
            SELECT Id, Title
            FROM ContentDocument
            WHERE Id = :contentDocumentIds
        ];
        Set<String> docNames = new Set<String>();
        for (ContentDocument doc : docInfo) {
            docNames.add(doc.Title);
        }
        System.debug('docNames ' + docNames);
        String defaultFileName = '';
        for (String docName : docNames) {
            defaultFileName += docName + ';';
        }
        System.debug('defaultFileName ' + defaultFileName);
        System.debug(
            'quote.Sales_Order_Default_Files__c before ' +
            quote.Sales_Order_Default_Files__c
        );
        if (!String.isBlank(quote.Sales_Order_Default_Files__c)) {
            quote.Sales_Order_Default_Files__c += defaultFileName;
        } else {
            quote.Sales_Order_Default_Files__c = defaultFileName;
        }
        System.debug(
            'quote.Sales_Order_Default_Files__c after' +
            quote.Sales_Order_Default_Files__c
        );
        update quote;
    }
    public static String getContentTypeByFileExtension(String fileExtension) {
        // Default MIME type for unknown or unspecified extensions
        String contentType = 'application/octet-stream'; 

        // Normalize the extension: convert to lowercase and remove leading dot
        if (fileExtension != null) {
            String normalizedExtension = fileExtension.toLowerCase().trim();
            if (normalizedExtension.startsWith('.')) {
                normalizedExtension = normalizedExtension.substring(1); 
            }

            switch on normalizedExtension {
                when 'xls','csv'{
                    contentType = 'application/vnd.ms-excel';
                }
                when 'xlsx' {
                    contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
                }
                when 'doc' {
                    contentType = 'application/msword';
                }
                when 'docx' {
                    contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                }
                when 'pdf' {
                    contentType = 'application/pdf';
                }
                when 'gif' {
                    contentType = 'image/gif';
                }
                when 'png' {
                    contentType = 'image/png';
                }
                when 'html', 'htm' { // Handle multiple extensions for the same MIME type
                    contentType = 'text/html';
                }
                /*when 'csv' {
                    contentType = 'text/csv';
                }*/
                when else {
                    // Already set to default 'application/octet-stream'
                }
            }
        }
        return contentType;
    }
}