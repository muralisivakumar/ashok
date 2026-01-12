public with sharing class AccountTermsApprovalController {
    @AuraEnabled
    public static String submitForApproval(Id recordId, String requestedNetTerms, Decimal requestedCreditLimit) {
        
            // First check if record is already in an approval process
            if (isInApprovalProcess(recordId)) {
                throw new AuraHandledException('This Account already has a pending approval request. Please wait for the current approval process to complete.');
            }
            try{
            // Get current Account values before update
            Account currentAccount = [
                SELECT Id, varcpq__NET_TERMS__c, Credit_Limit__c 
                FROM Account 
                WHERE Id = :recordId
            ];

            // Update the account with the new values
            Account acc = new Account(
                Id = recordId,
                Requested_Net_Terms__c = requestedNetTerms,
                Requested_Credit_Limit__c = requestedCreditLimit,
                Net_Terms_Change_Requested__c = String.isNotBlank(requestedNetTerms),
                Credit_Limit_Change_Requested__c = (requestedCreditLimit != null && requestedCreditLimit > 0)
            );
            
            update acc;
            
            // Create the approval request
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            
            // Build detailed comments
            String comments = 'Terms Change Request\n';
            comments += '------------------------\n';
            
            if (String.isNotBlank(requestedNetTerms)) {
                comments += '\nNET TERMS CHANGE:';
                comments += '\n• Current Value: ' + (currentAccount.varcpq__NET_TERMS__c != null ? currentAccount.varcpq__NET_TERMS__c : 'None');
                comments += '\n• Requested Value: ' + requestedNetTerms;
            }
            
            if (requestedCreditLimit != null) {
                comments += '\n\nCREDIT LIMIT CHANGE:';
                comments += '\n• Current Value: ' + (currentAccount.Credit_Limit__c != null ? currentAccount.Credit_Limit__c.format() : 'None');
                comments += '\n• Requested Value: ' + requestedCreditLimit.format();
            }

            req.setComments(comments);
            req.setObjectId(recordId);
            req.setProcessDefinitionNameOrId('Request_Terms_Change_Approval');
            
            // Submit the approval request
            Approval.ProcessResult result = Approval.process(req);
            
            return 'Success';
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @testVisible
    private static Boolean isInApprovalProcess(Id recordId) {
        try{
        List<ProcessInstance> processes = [
            SELECT Id 
            FROM ProcessInstance 
            WHERE TargetObjectId = :recordId 
            AND Status = 'Pending'
            LIMIT 1
        ];
         return !processes.isEmpty();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}