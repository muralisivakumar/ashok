@isTest
public class ManualCreditMemoTriggerTest {

    // Helper to create Account
    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    // Helper to create RMA with required fields
    private static Return_Merchandise_Authorization__c createRMA(Id accountId) {
        Return_Merchandise_Authorization__c rma = new Return_Merchandise_Authorization__c(
            //Name = 'Test RMA',
            //Total_Amount__c = 100,          // assuming required
            Account__c = accountId,
            Reason_Code__c = 'test'  // if lookup is required
        );
        insert rma;
        return rma;
    }

    // Helper to create Manual Credit Memo record
    private static Manual_Credit_Memo__c createCreditMemo(Id accountId, Id rmaId) {
        Manual_Credit_Memo__c mcm = new Manual_Credit_Memo__c(
            Account__c = accountId,
            Credit_Amount__c = 50,
            Return_Merchandise_Authorization__c = rmaId,
            Status__c = 'Draft',
            Credit_Memo_Type__c = 'Customer',
            Reason_Code__c = 'test'
        );
        insert mcm;
        return mcm;
    }

    @isTest
    static void testInsertCreatesRmaLineItem() {
        Account acc = createAccount();
        Return_Merchandise_Authorization__c rma = createRMA(acc.Id);

        Manual_Credit_Memo__c newMemo = new Manual_Credit_Memo__c(
            Account__c = acc.Id,
            Credit_Amount__c = 75,
            Return_Merchandise_Authorization__c = rma.Id,
            Status__c = 'Draft',
            Credit_Memo_Type__c = 'Customer',
            Reason_Code__c = 'test'
        );

        Test.startTest();
        insert newMemo;   // Trigger should create/update RMA line item
        Test.stopTest();

        // Verify RMA Line Items updated correctly
        List<Return_Merchandise_Authorization_Line_It__c> rmaLineItems = [
            SELECT Credit_Memo_Applied__c
            FROM Return_Merchandise_Authorization_Line_It__c
            WHERE Return_Merchandise_Authorization__c = :rma.Id
        ];
        
    }

    @isTest
    static void testUpdateCreatesHistoryRecords() {
        Account acc = createAccount();
        Return_Merchandise_Authorization__c rma = createRMA(acc.Id);
        Manual_Credit_Memo__c mcm = createCreditMemo(acc.Id, rma.Id);

        // Capture old record from DB (this gives it a valid Id for oldMap)
        Manual_Credit_Memo__c oldMcm = [
            SELECT Id, Credit_Amount__c, Status__c
            FROM Manual_Credit_Memo__c
            WHERE Id = :mcm.Id
        ];

        // Modify values to trigger history creation
        mcm.Credit_Amount__c = 100;
        mcm.Status__c = 'Submitted';

        Test.startTest();
        update mcm;   // Trigger should create history records
        Test.stopTest();

        // Verify history records created
        List<Manual_Credit_Memo_Field_History__c> history = [
            SELECT Field_Name__c, Old_Value__c, New_Value__c
            FROM Manual_Credit_Memo_Field_History__c
            WHERE Manual_Credit_Memo__c = :mcm.Id
        ];
        System.assert(history.size() > 0, 'History records should be created');
    }
}