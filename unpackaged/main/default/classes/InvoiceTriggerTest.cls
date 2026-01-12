/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : InvoiceTriggerTest
* Created By                       : Quotely App Exchange Engineering Team
* Created Date                     : 08-10-2024
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                 Modification ID        Description 
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Quotely App Exchange Engineering 
* Team
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Note: This class/trigger was written by the Quotely Engineering team. Please do not update any instance of the code without consulting the Quotely App Exchange team.
******************************************************************************************************************************************************************************/

@isTest
public class InvoiceTriggerTest {
    
    @testSetup
    static void setupTestData() {
        
        Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c=true);
        insert newAccount;
        
        Contact newContact = new Contact(LastName = 'lastName', AccountId = newAccount.Id);
        insert newContact;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        insert opp;
        
        varcpq__Sales_Order__c salesOrderUSD = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = newAccount.Id, 
            varcpq__Billing_Contact__c = newContact.Id
        );
        insert salesOrderUSD;
        
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000);
        insert SOLI1;
        
        varcpq__Sales_Order_Line_Item__c SOLI2 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = salesOrderUSD.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4, varcpq__Unit_Cost__c = 1000);
        insert SOLI2;
        
        Asset[] Asset_List = new Asset[]{};
            for(integer i =0; i< 2; i++) {
                Asset newAsset = new Asset(Name='Test Asset',AccountId = newAccount.Id,varcpq__Sales_Order__c = salesOrderUSD.Id,Quantity  = 10);
                Asset_List.add(newAsset);
            }
        insert Asset_List; 
    }
    
    @isTest
    static void testBeforeInsert() {
        
        varcpq__Sales_Order__c soUSD = [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE CurrencyIsoCode = 'USD' LIMIT 1];
        
        varcpq__Invoice__c invoice = new varcpq__Invoice__c(
            varcpq__Sales_Order__c = soUSD.Id
        );
        
        Test.startTest();
        insert invoice;
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdate() {
        varcpq__Sales_Order__c soUSD = [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE CurrencyIsoCode = 'USD' LIMIT 1];
        List<varcpq__Sales_Order_Line_Item__c> SOLI1 = [SELECT Id, Name, varcpq__Sales_Order__c FROM varcpq__Sales_Order_Line_Item__c WHERE varcpq__Sales_Order__c =: soUSD.Id];
        
        varcpq__Invoice__c invoice = new varcpq__Invoice__c(
            varcpq__Sales_Order__c = soUSD.Id,
            CurrencyIsoCode = 'USD'
        );
        insert invoice;
        
        varcpq__Invoice_Line_Item__c lineItem = new varcpq__Invoice_Line_Item__c(
            varcpq__Invoice__c = invoice.Id,
            varcpq__Sales_Order_Line_Item__c = SOLI1[0].Id,
            varcpq__Total_Cost__c = 100,
            varcpq__Unit_Price__c = 50,
            varcpq__Contract_Fees__c = 20
        );
        insert lineItem;
        
        invoice.CurrencyIsoCode = 'CAD';
        
        Test.startTest();
        update invoice;
        Test.stopTest();
        
    }
    
}