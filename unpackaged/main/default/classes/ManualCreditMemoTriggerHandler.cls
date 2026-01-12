public class ManualCreditMemoTriggerHandler {
    
    public static void createCreditMemoHistoryRecords(Map<Id, Manual_Credit_Memo__c> oldMap,List<Manual_Credit_Memo__c> newList)
    {
        
        List<Manual_Credit_Memo_Field_History__c> historyRecords = new List<Manual_Credit_Memo_Field_History__c>();
        
        for (Manual_Credit_Memo__c newRec : newList) 
        {
            Manual_Credit_Memo__c oldRec = oldMap.get(newRec.Id);
            
            
            compareValues(historyRecords, newRec.Id, 'Account__c', oldRec.Account__c, newRec.Account__c);
            compareValues(historyRecords, newRec.Id, 'Bill_Only_Indicator__c', oldRec.Bill_Only_Indicator__c, newRec.Bill_Only_Indicator__c);
            compareValues(historyRecords, newRec.Id, 'CreatedById', oldRec.CreatedById, newRec.CreatedById);
            compareValues(historyRecords, newRec.Id, 'Credit_Amount__c', oldRec.Credit_Amount__c, newRec.Credit_Amount__c);
            compareValues(historyRecords, newRec.Id, 'CurrencyIsoCode', oldRec.CurrencyIsoCode, newRec.CurrencyIsoCode);
            compareValues(historyRecords, newRec.Id, 'Invoice_Reference__c', oldRec.Invoice_Reference__c, newRec.Invoice_Reference__c);
            compareValues(historyRecords, newRec.Id, 'Justification__c', oldRec.Justification__c, newRec.Justification__c);
            compareValues(historyRecords, newRec.Id, 'LastModifiedById', oldRec.LastModifiedById, newRec.LastModifiedById);
            compareValues(historyRecords, newRec.Id, 'Original_Owner__c', oldRec.Original_Owner__c, newRec.Original_Owner__c);
            compareValues(historyRecords, newRec.Id, 'OwnerId', oldRec.OwnerId, newRec.OwnerId);
            compareValues(historyRecords, newRec.Id, 'Reason_Code__c', oldRec.Reason_Code__c, newRec.Reason_Code__c);
            compareValues(historyRecords, newRec.Id, 'Status__c', oldRec.Status__c, newRec.Status__c);
            
          
        }
        
        if (!historyRecords.isEmpty()) {
            insert historyRecords;
              System.debug('Insert completed successfully for ' + historyRecords.size() +historyRecords);
        }
         else {
            System.debug('No changes detected, no history records to insert.');
        }
    }
    
    private static void compareValues(List<Manual_Credit_Memo_Field_History__c> historyRecords,
                                      Id parentId, String fieldName,
                                      Object oldVal, Object newVal) 
    {
        if (oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) 
        {
             System.debug(' Change detected for field: ' + fieldName + ' | Old Value: ' + oldVal +' | New Value: ' + newVal);
            
            historyRecords.add(new Manual_Credit_Memo_Field_History__c(
                Manual_Credit_Memo__c = parentId,
                Field_Name__c = fieldName,
                Old_Value__c = String.valueOf(oldVal),
                New_Value__c = String.valueOf(newVal),
                Changed_By__c = UserInfo.getUserId(),
                Change_Timestamp__c = System.now()
            ));
        }
        
    }
    
    public static void createRMALineItem(List<Manual_Credit_Memo__c> manualCreditMemo){
        System.debug('manualCreditMemo: ' + manualCreditMemo);
        //List<Return_Merchandise_Authorization_Line_It__c> insertRMALineItem = new List<Return_Merchandise_Authorization_Line_It__c>();
        
        // Collect all RMA Ids from incoming Credit Memos
        Set<Id> rmaIds = new Set<Id>();
        for (Manual_Credit_Memo__c mcc : manualCreditMemo) {
            if (mcc.Return_Merchandise_Authorization__c != null) {
                rmaIds.add(mcc.Return_Merchandise_Authorization__c);
            }
        }
    
        if (rmaIds.isEmpty()) {
            System.debug('No RMAs found on Credit Memos');
            return;
        }
    
        // Query existing RMA Line Items for those RMAs
        List<Return_Merchandise_Authorization_Line_It__c> rmaLineItems = [
            SELECT Id, Return_Merchandise_Authorization__c, Credit_Memo_Applied__c
            FROM Return_Merchandise_Authorization_Line_It__c
            WHERE Return_Merchandise_Authorization__c IN :rmaIds
        ];
    
        System.debug('Fetched RMA Line Items: ' + rmaLineItems);
    
        // Build a map of RMA Id -> Credit Memo Id (assumes 1:1)
        Map<Id, Id> rmaToCreditMemoMap = new Map<Id, Id>();
        for (Manual_Credit_Memo__c mcc : manualCreditMemo) {
            if (mcc.Return_Merchandise_Authorization__c != null) {
                rmaToCreditMemoMap.put(mcc.Return_Merchandise_Authorization__c, mcc.Id);
            }
        }
    
        // Update each RMA Line Item to reference its Credit Memo
        List<Return_Merchandise_Authorization_Line_It__c> updates = new List<Return_Merchandise_Authorization_Line_It__c>();
        for (Return_Merchandise_Authorization_Line_It__c lineItem : rmaLineItems) {
            Id creditMemoId = rmaToCreditMemoMap.get(lineItem.Return_Merchandise_Authorization__c);
            if (creditMemoId != null) {
                lineItem.Credit_Memo_Applied__c = creditMemoId;
                updates.add(lineItem);
            }
        }
    
        if (!updates.isEmpty()) {
            update updates;
            System.debug('Updated RMA Line Items with Credit Memo: ' + updates);
        }
        /*for(Manual_Credit_Memo__c mcc: manualCreditMemo){
            Return_Merchandise_Authorization_Line_It__c RMALineItem = new Return_Merchandise_Authorization_Line_It__c();
            
            RMALineItem.Credit_Memo_Applied__c = mcc.Id;
            RMALineItem.Return_Merchandise_Authorization__c = mcc.Return_Merchandise_Authorization__c;
            
            System.debug('RMALineItem: ' + RMALineItem);
            
            //insert RMALineItem;
        }*/
    }
}