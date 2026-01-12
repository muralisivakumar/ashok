/***************************************************************************************************************************************************************************** 
* Apex trigger / Apex Class Name   : AccountPayableTriggerTest
* Created By                       : Quotely App Exchange Engineering Team
* Created Date                     : 14-04-2025
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                          Date                 Modification ID        Description 
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Quotely App Exchange Engineering 
* Team
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Note: This class/trigger was written by the Quotely Engineering team. Please do not update any instance of the code without consulting the Quotely App Exchange team.
******************************************************************************************************************************************************************************/

@isTest
public class AccountPayableTriggerTest {

    @testSetup
    static void setupTestData() {
        
        Account newAccount = new Account(Name='Test Account', varcpq__Available_for_PO__c = true);
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
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = [SELECT Id, LastName FROM Contact LIMIT 1];
        
        varcpq__Sales_Order__c soUSD = [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE CurrencyIsoCode = 'USD' LIMIT 1];
        
        varcpq__Purchase_Order__c newPoRec = new varcpq__Purchase_Order__c(varcpq__Distributor_Name__c = acc.Id, varcpq__Sales_Order__c = soUSD.Id, varcpq__PO_Date__c=Date.today(), varcpq__PO_Status__c = 'PO Created', CurrencyIsoCode = 'USD');
        
        List<varcpq__Sales_Order_Line_Item__c> SOLI1 = [SELECT Id, Name, varcpq__Sales_Order__c FROM varcpq__Sales_Order_Line_Item__c WHERE varcpq__Sales_Order__c =: soUSD.Id];
        
        List<Asset> Asset_List = [SELECT Id From Asset WHERE varcpq__Sales_Order__c =: soUSD.Id];
        
        Test.startTest();
        insert newPoRec;
        
        List<varcpq__Purchase_Order_Line_Item__c> lstItmes = new List<varcpq__Purchase_Order_Line_Item__c>();
        
        varcpq__Purchase_Order_Line_Item__c newLItmes;
        newLItmes = new varcpq__Purchase_Order_Line_Item__c(varcpq__Sales_Order_Line_Item__c = SOLI1[0].Id,varcpq__Purchase_Order__c = newPoRec.Id,varcpq__Asset__c = Asset_List[0].ID,varcpq__Quantity__c=4,varcpq__Unit_Cost__c = 1000,  CurrencyIsoCode = 'USD');
        lstItmes.add(newLItmes);
        
        newLItmes = new varcpq__Purchase_Order_Line_Item__c(varcpq__Sales_Order_Line_Item__c = SOLI1[1].Id,varcpq__Purchase_Order__c = newPoRec.Id,varcpq__Asset__c = Asset_List[1].ID,varcpq__Quantity__c=4,varcpq__Unit_Cost__c = 1000,  CurrencyIsoCode = 'USD');
        lstItmes.add(newLItmes);
        insert lstItmes;  

        varcpq__Accounts_Payable_Invoice__c API = new varcpq__Accounts_Payable_Invoice__c();
        API.varcpq__Due_Date__c = System.Today();
        API.varcpq__Invoice_Date__c = System.Today();
        API.varcpq__Purchase_Order__c = newPoRec.Id;
		insert API;	

		varcpq__Account_Payable_Invoice_Line_Item__c APILI = new varcpq__Account_Payable_Invoice_Line_Item__c();
		APILI.varcpq__Accounts_Payable_Invoice__c = API.Id;
        APILI.varcpq__PO_Unit_Cost__c = lstItmes[0].varcpq__Unit_Cost__c;
        APILI.varcpq__Purchase_Order_Line_Item__c = lstItmes[0].Id;
        APILI.varcpq__Quantity_Invoiced__c = 2;
        APILI.varcpq__Unit_Cost__c = lstItmes[0].varcpq__Unit_Cost__c; 
        insert APILI;
        Test.stopTest();
        
    }
    
    @isTest
    static void testAfterUpdate() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = [SELECT Id, LastName FROM Contact LIMIT 1];
        
        varcpq__Sales_Order__c soUSD = [SELECT Id, CurrencyIsoCode FROM varcpq__Sales_Order__c WHERE CurrencyIsoCode = 'USD' LIMIT 1];
        
                
        List<varcpq__Sales_Order_Line_Item__c> SOLI1 = [SELECT Id, Name, varcpq__Sales_Order__c FROM varcpq__Sales_Order_Line_Item__c WHERE varcpq__Sales_Order__c =: soUSD.Id];
        
        List<Asset> Asset_List = [SELECT Id From Asset WHERE varcpq__Sales_Order__c =: soUSD.Id];
        
        varcpq__Purchase_Order__c newPoRec = new varcpq__Purchase_Order__c(varcpq__Distributor_Name__c = acc.Id, varcpq__Sales_Order__c = soUSD.Id, varcpq__PO_Date__c=Date.today(), varcpq__PO_Status__c = 'PO Created', CurrencyIsoCode = 'USD');
        insert newPoRec;
        
        List<varcpq__Purchase_Order_Line_Item__c> lstItmes = new List<varcpq__Purchase_Order_Line_Item__c>();
        
        varcpq__Purchase_Order_Line_Item__c newLItmes;
        newLItmes = new varcpq__Purchase_Order_Line_Item__c(varcpq__Sales_Order_Line_Item__c = SOLI1[0].Id, varcpq__Purchase_Order__c = newPoRec.Id,varcpq__Asset__c = Asset_List[0].ID,varcpq__Quantity__c=4,varcpq__Unit_Cost__c = 1000,  CurrencyIsoCode = 'USD');
        lstItmes.add(newLItmes);
        
        newLItmes = new varcpq__Purchase_Order_Line_Item__c(varcpq__Sales_Order_Line_Item__c = SOLI1[1].Id, varcpq__Purchase_Order__c = newPoRec.Id,varcpq__Asset__c = Asset_List[1].ID,varcpq__Quantity__c=4,varcpq__Unit_Cost__c = 1000,  CurrencyIsoCode = 'USD');
        lstItmes.add(newLItmes);
        insert lstItmes;  

        varcpq__Accounts_Payable_Invoice__c API = new varcpq__Accounts_Payable_Invoice__c();
        API.varcpq__Due_Date__c = System.Today();
        API.varcpq__Invoice_Date__c = System.Today();
        API.varcpq__Purchase_Order__c = newPoRec.Id;
		insert API;	

		varcpq__Account_Payable_Invoice_Line_Item__c APILI = new varcpq__Account_Payable_Invoice_Line_Item__c();
		APILI.varcpq__Accounts_Payable_Invoice__c = API.Id;
        APILI.varcpq__PO_Unit_Cost__c = lstItmes[0].varcpq__Unit_Cost__c;
        APILI.varcpq__Purchase_Order_Line_Item__c = lstItmes[0].Id;
        APILI.varcpq__Quantity_Invoiced__c = 2;
        APILI.varcpq__Unit_Cost__c = lstItmes[0].varcpq__Unit_Cost__c; 
        insert APILI;
        
        API.CurrencyIsoCode = 'CAD';
        
        Test.startTest();
        update API;
        Test.stopTest();
    }
    
}