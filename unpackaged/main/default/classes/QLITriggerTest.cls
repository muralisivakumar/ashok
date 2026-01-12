@isTest
public class QLITriggerTest {
	 @testSetup
    static void setupData() {
        
       
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c = true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        
        Account distributorAcc = new Account(Name = 'Test Distributor', Type = 'Supplier',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId(),
                                             varcpq__Net_terms__c = 'NET45', varcpq__available_for_po__c = true);
        insert distributorAcc;
        
        Account nonMatchingDistributorAcc = new Account(Name = 'Different Distributor', Type = 'Supplier',
                                                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId(),
                                                        varcpq__Net_terms__c = 'NET30', varcpq__available_for_po__c = true);
        insert nonMatchingDistributorAcc;
        
       
        Id PricebookId = Test.getStandardPricebookId();
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;
        
        
        Product2 product = new Product2(Name = 'Test Product', varcpq__LISTPRICE__c = 100, IsActive = true, 
                                        varcpq__PARTNUMBER__c = 'Test Product', varcpq__ITEMDESC__c = 'Test Product',
                                        varcpq__Distributor_Account__c = nonMatchingDistributorAcc.Id);
        insert product;
        
     
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert standardPricebookEntry;
        
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert customPricebookEntry;
        
      
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'CAD',
            AccountId = distributorAcc.Id
        );
        insert opp;
        
       
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            CurrencyIsoCode = 'CAD',
          
            QLI_from_different_country__c = false 
        );
        insert quote;
        
       
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert qli;
    }    
    
    @isTest
    public static void testQli(){
        QuoteLineItem qli = [SELECT Id From Quotelineitem];
        qli.AVA_SFCLOUD__SalesTax_Line__c = 10;
        qli.AVA_SFCLOUD__Sales_Tax_Rate__c = '10.0000%';
        update qli;
    }
    @isTest
    public static void testQliwithAmt0(){
        QuoteLineItem qli = [SELECT Id From Quotelineitem];
        qli.AVA_SFCLOUD__SalesTax_Line__c = 0;
        qli.AVA_SFCLOUD__Sales_Tax_Rate__c = '10.0000%';
        update qli;
    }
}