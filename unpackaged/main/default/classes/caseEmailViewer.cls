public class caseEmailViewer {
	@AuraEnabled
    public static emailContentWrap getEmailBody(Id CaseId){
        String htmlBody = '';
        emailContentWrap wrap = new emailContentWrap();
        List<EmailMessage> email = [SELECT Id, ParentId, HtmlBody, TextBody, Subject,CreatedDate FROM EmailMessage WHERE ParentId =: caseId ORDER BY CreatedDate DESC limit 1];
        System.debug('email '+email);
        if(!email.isEmpty()){
            wrap.htmlBody = email[0].HtmlBody;
            wrap.emaildate = email[0].CreatedDate;
            
            return wrap;
        }
        return null;
    }
    
    public class emailContentWrap{
        @AuraEnabled public string htmlBody;
        @AuraEnabled public DateTime emaildate;
        
    }
}