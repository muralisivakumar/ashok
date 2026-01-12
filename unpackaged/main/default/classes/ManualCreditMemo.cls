public class ManualCreditMemo {
	@AuraEnabled(cacheable=true)
    public static  Map<String, Object> getInvoiceDetails(Id recId){
         System.debug('record id:: ' + recId);
    
    Map<String, object> defaults = new Map<String, Object>();
    
    /*List<varcpq__Invoice__c> invList = [
        SELECT Id, varcpq__Client__c, Total_Credit_Amount__c, CurrencyIsoCode,
        (SELECT Id, Total_Amount__c FROM Return_Merchandise_Authorization__r LIMIT 1)
        FROM varcpq__Invoice__c 
        WHERE Id = :recId 
        LIMIT 1
    ];*/
    List<varcpq__Invoice__c> invList = [
        SELECT Id, varcpq__Client__c, CurrencyIsoCode,
        (SELECT Id, Total_Amount__c FROM Return_Merchandise_Authorization__r LIMIT 1)
        FROM varcpq__Invoice__c 
        WHERE Id = :recId 
        LIMIT 1
    ];
    
    if (!invList.isEmpty()) {
        varcpq__Invoice__c inv = invList[0];
        defaults.put('InvoiceId', inv.Id);
        defaults.put('AccountId', inv.varcpq__Client__c);
        //defaults.put('CreditAmount', inv.Total_Credit_Amount__c);
        defaults.put('currency', inv.CurrencyIsoCode);
        if (!inv.Return_Merchandise_Authorization__r.isEmpty()) {
            defaults.put('RmaId', inv.Return_Merchandise_Authorization__r[0].Id);
            defaults.put('TotalCreditAmount', inv.Return_Merchandise_Authorization__r[0].Total_Amount__c);
        }
        
    } else {
        System.debug('No invoice found for Id: ' + recId);
    }
    
    return defaults;
    }
    
    @AuraEnabled
    public static Id createCreditMemoWithFiles(Map<String, Object> creditMemoData, List<Id> fileIds) {
        System.debug('creditMemoData: '+ creditMemoData);
        System.debug('fileIds: ' + fileIds);
        Manual_Credit_Memo__c memo = new Manual_Credit_Memo__c();
        memo.Account__c = (Id)creditMemoData.get('Account__c');
        memo.Invoice_Reference__c = (Id)creditMemoData.get('Invoice_Reference__c');
        memo.Justification__c = (String)creditMemoData.get('Justification__c');
        memo.Bill_Only_Indicator__c = (Boolean)creditMemoData.get('Bill_Only_Indicator__c');
        memo.Reason_Code__c = (String)creditMemoData.get('Reason_Code__c');
        memo.Credit_Amount__c = (Decimal)creditMemoData.get('Credit_Amount__c');
        memo.Status__c = 'Draft';
        memo.Credit_Memo_Type__c = 'Customer';
        memo.Return_Merchandise_Authorization__c = (Id)creditMemoData.get('Return_Merchandise_Authorization__c');
        
        system.debug('memo: ' + memo);
        insert memo;

        if (fileIds != null && !fileIds.isEmpty()) {
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id fileId : fileIds) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = fileId,
                    LinkedEntityId = memo.Id,
                    ShareType = 'V'
                ));
            }
            insert links;
        }
        return memo.Id;
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getCreditAmountByRma(String RMAId) {
        System.debug('RMA Id: ' + rmaId);
        List<Return_Merchandise_Authorization__c> rmaList = [
        SELECT Id, Total_Amount__c 
        FROM Return_Merchandise_Authorization__c 
        WHERE Id = :RMAId
        LIMIT 1
    ];
    
        if (!rmaList.isEmpty()) {
            return rmaList[0].Total_Amount__c != null ? rmaList[0].Total_Amount__c : 0;
        }
        return 0; 

    }
    
    @AuraEnabled
    public static Id createCreditMemoAccount(Map<String, Object> creditMemoData, List<Id> fileIds){
        System.debug('creditMemoData: ' + creditMemoData);
        Id accId = (Id)creditMemoData.get('Account__c');
        Account acc = [Select Id,CurrencyIsoCode, (Select id , Email, Name from Contacts where Default_Billing_Contact__c = true) From Account where id =: accId];
        System.debug('Account Id: ' + acc);
        System.debug('Account Id: ' + accId);
        Manual_Credit_Memo__c memo = new Manual_Credit_Memo__c();
        memo.Account__c = (Id)creditMemoData.get('Account__c');
         Object creditAmountVal = creditMemoData.get('Credit_Amount__c');
        if (creditAmountVal != null) {
            memo.Credit_Amount__c = Decimal.valueOf(String.valueOf(creditAmountVal));
        }
        memo.Reason_Code__c = (String)creditMemoData.get('Reason_Code__c');
        if(acc.CurrencyIsoCode == 'CAD'){
            memo.CurrencyIsoCode = 'CAD';
        }
        memo.Credit_Memo_Type__c = 'Customer';
        System.debug('memo:: '+ memo);
        insert memo;
        
        if (fileIds != null && !fileIds.isEmpty()) {
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id fileId : fileIds) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = fileId,
                    LinkedEntityId = memo.Id,
                    ShareType = 'V'
                ));
            }
            insert links;
        }
        
        memo = [
            SELECT Id, Name, Reason_Code__c, Credit_Amount__c, CurrencyIsoCode, Account__c,Account__r.Name, Invoice_Reference__c
            FROM Manual_Credit_Memo__c 
            WHERE Id = :memo.Id
        ];
            
        // Get the default billing contact (if any)
        Contact billingContact = 
            (acc.Contacts != null && !acc.Contacts.isEmpty()) ? acc.Contacts[0] : null;
        
        if (billingContact != null && String.isNotBlank(billingContact.Email)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { billingContact.Email });
            mail.setSubject('Credit Memo Created - ' + memo.Name);
        	String reasonLine = '';
            if (memo.Reason_Code__c != null && memo.Reason_Code__c.trim() != '') {
                reasonLine = '<p><b>Reason for Credit:</b> ' + memo.Reason_Code__c + '</p>';
            }
            String htmlBody =
        '<p>Dear ' + billingContact.Name + ',</p>' +

        '<p>We hope this message finds you well.</p>' +

        '<p>This email is to inform you that a credit memo (Ref: <b>' + memo.Name + '</b>) ' +
        'has been issued to your account with <b>Clutch Solutions</b> on ' + 
        String.valueOf(Date.today()) + '.</p>' +

        '<p>The credit has been applied in the amount of <b>' + memo.Credit_Amount__c + ' ' + memo.CurrencyIsoCode + '</b>, related to:</p>' +
		
       reasonLine +  

        '<p><b>Summary:</b><br/>' +
        'Customer Name: ' + (memo.Account__c != null ? memo.Account__r.Name : '') + '<br/>' +
        'Credit Memo Number: ' + memo.Name + '<br/>' +
        'Credit Amount: ' + memo.Credit_Amount__c + ' ' + memo.CurrencyIsoCode + '<br/>' +
        'Date Issued: ' + String.valueOf(Date.today()) + '<br/>' +
        (memo.Invoice_Reference__c != null ? 'Original Invoice: ' + memo.Invoice_Reference__c + '<br/>' : '') +
        '</p>' +

        '<p>You may apply this credit toward future invoices or request a refund, depending on your preference.</p>' +

        '<p>Thank you for your continued business.</p>' +

        '<p>Warm regards,<br/>' +
        'Clutch Solutions<br/>' ;        
        	mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            System.debug('No Default Billing Contact found with an Email, skipping email.');
        }
        
        return memo.Id;
    }
}