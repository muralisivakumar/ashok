trigger APPreventBackdating on varcpq__Accounts_Payable_Invoice__c (before insert,before update) {
    List<Accounting_Configuration__c> accountingConfig = [SELECT Id, Name, Days_AR_Issue_Date_Remain_Open__c, AP_Closed_Books_Date__c FROM Accounting_Configuration__c WHERE Is_Active__c = true LIMIT 1];
    
    if(!accountingConfig.isEmpty() && Trigger.isInsert){
        Date APcloseDate = accountingConfig[0].AP_Closed_Books_Date__c;
        for(varcpq__Accounts_Payable_Invoice__c api : Trigger.new){
        
            if(api.varcpq__Invoice_Date__c != null && !api.Invoice_Date_Override__c){
                
                if(api.varcpq__Invoice_Date__c <= APcloseDate){
                    api.addError('Backdated Invoice Date is not allowed');
                }
            }
        }
    }
    
    if(!accountingConfig.isEmpty() && Trigger.isUpdate){
        Date APcloseDate = accountingConfig[0].AP_Closed_Books_Date__c;
        for(varcpq__Accounts_Payable_Invoice__c api : Trigger.new){
        System.debug('aaappppiii '+Trigger.oldmap.get(api.Id).varcpq__Invoice_Date__c);
            if(Trigger.oldmap.get(api.Id).varcpq__Invoice_Date__c != api.varcpq__Invoice_Date__c && !api.Invoice_Date_Override__c){
                
                if(api.varcpq__Invoice_Date__c <= APcloseDate){
                    api.addError('Backdating Invoice Date is not allowed');
                }
            }
        }
    }
}