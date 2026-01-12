public class SupplierCreditMemo {

	@AuraEnabled(cacheable=true)
    public static  Map<String, Object> getAPInvoiceDetails(Id recId){
         System.debug('record id:: ' + recId);
    
    Map<String, Object> defaults = new Map<String, Object>();
    
    List<varcpq__Accounts_Payable_Invoice__c> apinvList = [
        SELECT Id, varcpq__Supplier__c, CurrencyIsoCode, Invoice__r.Total_Credit_Amount__c
        FROM varcpq__Accounts_Payable_Invoice__c 
        WHERE Id = :recId 
        LIMIT 1
    ];
    
    if (!apinvList.isEmpty()) {
        varcpq__Accounts_Payable_Invoice__c inv = apinvList[0];
        defaults.put('InvoiceId', inv.Id);
        defaults.put('AccountId', inv.varcpq__Supplier__c);
        //defaults.put('AccountId', inv.varcpq__Supplier__c);
        defaults.put('CreditAmount', inv.Invoice__r.Total_Credit_Amount__c);
        defaults.put('currency', inv.CurrencyIsoCode);
        defaults.put('RelatedInvoiceId', inv.Invoice__c);
        
        if (inv.Invoice__c != null) {
            List<Return_Merchandise_Authorization__c> rmas = [
                SELECT Id, Total_Amount__c
                FROM Return_Merchandise_Authorization__c
                WHERE Related_Invoice__c = :inv.Invoice__c
            ];
            if (!rmas.isEmpty()) {
                defaults.put('RMAId', rmas[0].Id);
                defaults.put('TotalCreditAmount', rmas[0].Total_Amount__c);
            }
        }
    } else {
        System.debug('No invoice found for Id: ' + recId);
    }
    
    return defaults;
    }
    
    @AuraEnabled
    public static Id createAPCreditMemoWithFiles(Map<String, Object> creditMemoData, List<Id> fileIds) {
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
         memo.Credit_Memo_Type__c = 'Supplier';
        memo.Accounts_Payable_Invoice__c = (Id)creditMemoData.get('Accounts_Payable_Invoice__c');
         memo.Return_Merchandise_Authorization__c = (Id)creditMemoData.get('Return_Merchandise_Authorization__c');
        memo.Credit_Memo__c = (String)creditMemoData.get('Credit_Memo__c');
        String currencyCode = (String)creditMemoData.get('Currency_Code');
        memo.CurrencyIsoCode = currencyCode;
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
}