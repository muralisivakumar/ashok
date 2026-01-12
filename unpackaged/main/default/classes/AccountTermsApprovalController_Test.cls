@isTest
public class AccountTermsApprovalController_Test {
	@isTest
    static void testAccountTermsApproval(){
        Account acc = new Account(
        	Name = 'Test Acc',
            varcpq__NET_TERMS__c = 'NET30',
            Credit_Limit__c = 1000,
            Type = 'Customer'
        );
        Insert acc;
        
        /*ProcessInstance approvalTest = new ProcessInstance(
        	TargetObjectId = acc.Id,
            Status = 'Pending'
        );
        Insert approvalTest;*/
        
        AccountTermsApprovalController.isInApprovalProcess(acc.Id);
        AccountTermsApprovalController.submitForApproval(acc.Id, 'NET15', 100000.00);
    }
     
}