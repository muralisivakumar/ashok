/***************************************************************************************************************************************************************************************
* @description       : Email Quote Custom is an LWC for Sending quote email. This Apex class is the controller for getting quote email Template to lwc and send email with 
						required parameters and updates email message to with quote Id to show history of emails in related list of Quote.
* @author            : Aress Software - AS
* @Created date      : 23/10/2024
* @related class     : - 
* @test Class        : - emailQuoteCustom_Test
* @last modified on  : - 5/11/2024
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class emailQuoteCustom {
    
    @AuraEnabled
    public static emailWrapper getEmailContent(Id quoteId ,Id userId){
        User user = [SELECT Id,name, Email FROM User where id=:userId];
        Quote qt = [SELECT Id, QuoteNumber,createdBy.Name,accountId FROM Quote where Id=:quoteId];
        List<Contact> conlist = [SELECT Id,Name,Email from Contact WHERE accountId=:qt.AccountId];
        String qtNumber = qt.QuoteNumber;
        String createdBy = qt.CreatedBy.Name;
        emailWrapper eWrap = new emailWrapper();
        eWrap.ownerName = user.Name;
        eWrap.ownerEmail = user.Email;
        eWrap.conlist = conlist;
        
        EmailTemplate emailTemp = [SELECT Id, DeveloperName, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName ='Clutch_Quote_Email_Template'];
        String emailbody = emailTemp.HtmlValue;
        String emailSubject = emailTemp.Subject;
        
        if(emailSubject.containsIgnoreCase('{!Quote.QuoteNumber}')){
            emailSubject = emailSubject.replace('{!Quote.QuoteNumber}',qtNumber);
        }
        eWrap.emailSubject = emailSubject;
        
        string tableTag = '<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" >\n<tr valign="top" height="400" >\n<td tEditID="c1r1" style=" background-color:#FFFFFF; bEditID:r3st1; color:#000000; bLabel:main; font-size:12pt; font-family:arial;" aEditID="c1r1" locked="0" >';
        String tableEndTag = '</td>\n</tr>\n</table>';
        if(emailBody.containsAny(tableTag)){
            emailBody = emailBody.replace(tableTag,'');
            System.debug('inif 1');
        }
        if(emailBody.containsAny(tableEndTag)){
            emailBody = emailBody.replace(tableEndTag,'');
            System.debug('inif 2');
        }    
        if(emailBody.containsIgnoreCase('<![CDATA[') && emailBody.containsIgnoreCase(']]>')){
            emailBody = emailBody.replace(']]>','');
            emailBody = emailBody.replace('<![CDATA[','');
        }
        if(emailBody.containsIgnoreCase('{!Quote.QuoteNumber}')){
            emailBody = emailBody.replace('{!Quote.QuoteNumber}',qtNumber);
            System.debug('In if 1');
        }
        if(emailBody.containsIgnoreCase('{!Quote.CreatedBy}')){
            emailBody = emailBody.replace('{!Quote.CreatedBy}',createdBy);
            System.debug('In if 2 '+createdBy);
        }
        eWrap.emailBody = emailBody;
        
        List<ContentDocumentLink> cdl = [SELECT Id,ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink 
                                         WHERE LinkedEntityId =:quoteId 
                                         AND (ContentDocument.Title LIKE 'ClutchQuote%' AND ContentDocument.Title LIKE '%.pdf')
                                         order by SystemModStamp desc];
        System.debug('cdl list'+cdl);
        eWrap.files = cdl;
        System.debug(eWrap);
        return eWrap;
    }
    
    
    @AuraEnabled
    public static void sendEmail(String sendContent){
        
        emailSendWrapper sendWrap = (emailSendWrapper)JSON.deserialize(sendContent,emailSendWrapper.class);
        System.debug('Sendwrap '+sendWrap);
        ContentVersion contentVersion = [SELECT Id, Title, VersionData, ContentDocumentId 
                                         FROM ContentVersion 
                                         WHERE ContentDocumentId = :sendWrap.attachmentId
                                         ORDER BY CreatedDate DESC 
                                         LIMIT 1];
        System.debug('content version '+contentVersion);
        String FinalHtmlBody = '<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" >\n<tr valign="top" height="400" >\n<td tEditID="c1r1" style=" background-color:#FFFFFF; bEditID:r3st1; color:#000000; bLabel:main; font-size:12pt; font-family:arial;" aEditID="c1r1" locked="0" >';
        FinalHtmlBody += sendWrap.htmlBody+'</td>\n</tr>\n</table>';
        
        //Single email message 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(sendWrap.toEmail);
        email.setCcAddresses(sendWrap.ccEmail);
        email.setBccAddresses(sendWrap.bccEmail);
        email.setSubject(sendWrap.subject);
        email.setHtmlBody(FinalHtmlBody);
        
        //Add Attachment to the email
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(contentVersion.Title);  
        attachment.setBody(contentVersion.VersionData);  
        attachment.setContentType('application/pdf'); 
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment});
        System.debug(email);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        String toAdressString = '';
        for(Integer i = 0;i<sendWrap.toEmail.size();i++){
            if( i != sendWrap.toEmail.size()-1){
                toAdressString += sendWrap.toEmail[i] +'; ';
            }else{
                toAdressString += sendWrap.toEmail[i];
            }
        }
        System.debug('toAdressString '+toAdressString);
        //Update EmailMessage related 
        EmailMessage sentEmail = [SELECT Id,quote__c FROM EmailMessage 
                                  WHERE Subject = : sendWrap.subject
                                  AND ToAddress = :	toAdressString
                                  AND CreatedDate = TODAY 
                                  ORDER BY CreatedDate DESC LIMIT 1];
        if(sentEmail != null){
            sentEmail.Quote__c = sendWrap.quoteId;
            update sentEmail;
        }
        if(sendWrap.isPresented){
            Quote qt = [SELECT Id, Status,Sales_Order_Default_Files__c FROM Quote WHERE Id=:sendWrap.quoteId];
            if(qt != null){
                qt.Status = 'Presented';
                if(String.ISBLANK(qt.Sales_Order_Default_Files__c)){
                	qt.Sales_Order_Default_Files__c = contentVersion.Title+';';
                }else{
                    qt.Sales_Order_Default_Files__c = qt.Sales_Order_Default_Files__c + contentVersion.Title+';';
                }
                update qt;
            }
        }
        
    }
    
    public class emailSendWrapper{
        @AuraEnabled public String quoteId;
        @AuraEnabled public String fromEmail;
        @AuraEnabled public String[] toEmail;
        @AuraEnabled public String[] ccEmail;
        @AuraEnabled public String[] bccEmail;
        @AuraEnabled public String subject;
        @AuraEnabled public String htmlBody;
        @AuraEnabled public String attachmentId;
        @AuraEnabled public Boolean isPresented;
    }
    public class emailWrapper{
        @AuraEnabled public List<Contact> conlist;
        @AuraEnabled public List<ContentDocumentLink> files;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String ownerEmail;
        @AuraEnabled public String emailBody;
        @AuraEnabled public String emailSubject;
        //@AuraEnabled public String attachmentTitle;
        //@AuraEnabled public String attachmentId;
    }
    
}