@isTest
public class Trigger_AvalaraTaxRecalc_Test {
    @testVisible
    public static Avalara_Tax_Configuration__mdt avalaraTaxConfig{
        get{
            String objectApiName = 'varcpq__Sales_Order__c';
            if(avalaraTaxConfig == NULL){
                Avalara_Tax_Configuration__mdt config = [SELECT Id, Label, Parent_Object_API_Name__c, Line_Item_Object_API_Name__c, 
                                                         Line_Item_Parent_Field_API_Name__c, Tax_Calculator_Class_Name__c, 
                                                         Description__c, Active__c, Parent_Monitored_Fields__c, Line_Item_Monitored_Fields__c
                                                         FROM Avalara_Tax_Configuration__mdt
                                                         WHERE Parent_Object_API_Name__c = :objectApiName
                                                         LIMIT 1];
            }
            return avalaraTaxConfig;
        }
        set;
        
    }
    
    @TestSetup
    static void setupTestData() {
        
        
        Account acc = new Account(
            Name = 'Test Account'
        );	
        Insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD', AccountId = acc.Id);
        insert opp;
        varcpq__Customer_Address__c add = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Billing_Address__c = true,
            Country__c = 'US');
        insert add;
        
        varcpq__Customer_Address__c addship = new varcpq__Customer_Address__c(
            Name = 'Test Address 2',
            varcpq__Active__c = true,
            varcpq__City__c = 'Owens',
            varcpq__Customer__c = acc.Id,
            varcpq__State__c = 'NY',
            varcpq__Street__c = '122 Test Way',
            varcpq__Zipcode__c = '34343',
            Default_Shipping_Address__c = true,
            Country__c = 'US');
        insert addShip;
        varcpq__Sales_Order__c testSO = new varcpq__Sales_Order__c(
            Name = 'Test Sales Order USD', 
            varcpq__Opportunity__c = opp.Id, 
            CurrencyIsoCode = 'USD',
            varcpq__Client__c = acc.Id,
            varcpq__Shipping_Address__c = add.Id
            
        );
        
        insert testSO;
        varcpq__Sales_Order_Line_Item__c SOLI1 = new varcpq__Sales_Order_Line_Item__c(varcpq__Sales_Order__c = testSO.Id, varcpq__Line__c = 1, varcpq__Quantity__c = 4,varcpq__Unit_Cost__c = 1000);
        insert SOLI1;
        
    }
    @isTest
    static void changeInField(){
        
        varcpq__Sales_Order__c testSO = [SELECT Id, varcpq__Billing_City__c FROM varcpq__Sales_Order__c];
        
        testSO.varcpq__Billing_City__c = 'Test City';
        update testSO;
    }
    
    @isTest
    static void changeInPrent(){
        
        varcpq__Sales_Order__c testSO = [SELECT Id, varcpq__Shipping_Address__c FROM varcpq__Sales_Order__c];
        varcpq__Customer_Address__c add = [Select id from varcpq__Customer_Address__c where Default_Shipping_Address__c = false]; 
        testSO.varcpq__Shipping_Address__c = add.Id;
        update testSO;
    }
    
    @isTest
    static void noChangeSO(){
        AvalaraTaxHelper.isProcessing = true;
        varcpq__Sales_Order__c testSO = [SELECT Id, varcpq__Shipping_Address__c FROM varcpq__Sales_Order__c];
        testSO.Name = 'test new so';
        update testSO;
        
    }
    @isTest
    static void soliDel(){
        
        varcpq__Sales_Order_Line_Item__c testSOli = [SELECT Id FROM varcpq__Sales_Order_Line_Item__c];
       	delete testSOli;
        
    }
     @isTest
    static void soliUpd(){
        
        varcpq__Sales_Order_Line_Item__c testSOli = [SELECT Id,varcpq__Quantity__c FROM varcpq__Sales_Order_Line_Item__c];
        testSOli.varcpq__Quantity__c = 10;
       	update testSOli;
        
    }
    
}