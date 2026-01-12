/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : SalesOrderTriggerTest
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
public class SalesOrderTriggerTest {
    
    @testSetup
    static void setupTestData() {
        
        Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c = true);
        insert newAccount;
        
        Contact newContact = new Contact(LastName = 'lastName', AccountId = newAccount.Id);
        insert newContact;
        
        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = newAccount.Id);
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'CAD', AccountId = newAccount.Id);
        insert new List<Opportunity>{opp1, opp2};
    }

    @isTest
    static void testBeforeInsert() {
        
        Opportunity opp = [SELECT Id, CurrencyIsoCode, AccountId FROM Opportunity WHERE CurrencyIsoCode = 'USD' LIMIT 1];
        
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = [SELECT Id, LastName FROM Contact LIMIT 1];
        
        varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order', 
            varcpq__Opportunity__c = opp.Id,
            varcpq__Client__c = acc.Id, 
            varcpq__Billing_Contact__c = con.Id
        );
        
        Test.startTest();
        insert salesOrder;
        Test.stopTest();
        
        varcpq__Sales_Order__c insertedSO = [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE Id = :salesOrder.Id];
        System.assertEquals('USD', insertedSO.CurrencyIsoCode, 'CurrencyIsoCode should be set to USD');
    }
    
    // @isTest
    // static void testAfterUpdate() {
    //     Opportunity opp1 = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE CurrencyIsoCode = 'USD' LIMIT 1];
    //     Account acc = [SELECT Id, Name FROM Account LIMIT 1];
    //     Contact con = [SELECT Id, LastName FROM Contact LIMIT 1];
        
    //     varcpq__Sales_Order__c salesOrder = new varcpq__Sales_Order__c(
    //         Name = 'Test Sales Order', 
    //         varcpq__Opportunity__c = opp1.Id, 
    //         CurrencyIsoCode = 'USD',
    //         varcpq__Client__c = acc.Id, 
    //         varcpq__Billing_Contact__c = con.Id
    //     );
    //     insert salesOrder;
        
    //     varcpq__Sales_Order_Line_Item__c lineItem = new varcpq__Sales_Order_Line_Item__c(
    //         varcpq__Sales_Order__c = salesOrder.Id,
    //         varcpq__Quantity__c = 10,
    //         varcpq__Unit_Cost__c = 100,
    //         varcpq__Unit_Price__c = 150
    //     );
    //     insert lineItem;
        
    //     Opportunity opp2 = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE CurrencyIsoCode = 'CAD' LIMIT 1];
    //     salesOrder.CurrencyIsoCode = 'CAD';
        
    //     Test.startTest();
    //     update salesOrder;
    //     Test.stopTest();
        
    //     varcpq__Sales_Order_Line_Item__c updatedLineItem = [SELECT Id, varcpq__Unit_Cost__c, varcpq__Unit_Price__c, CurrencyIsoCode FROM varcpq__Sales_Order_Line_Item__c WHERE Id = :lineItem.Id];
        
    //     Decimal expectedCost = (100 / 1) * 0.85;
    //     Decimal expectedPrice = (150 / 1) * 0.85;
    // }
    
}