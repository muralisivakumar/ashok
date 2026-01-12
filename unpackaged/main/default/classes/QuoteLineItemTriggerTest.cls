@isTest
public class QuoteLineItemTriggerTest {

    public static Id longDescQLIId;

    @testSetup
    static void setupData() {
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c = true);
        insert prosetting; 

        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;

        Account distributorAcc = new Account(
            Name = 'Test Distributor',
            Type = 'Supplier',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Canadian Account').getRecordTypeId(),
            varcpq__Net_terms__c = 'NET45',
            varcpq__available_for_po__c = true
        );
        insert distributorAcc;

        Account nonMatchingDistributorAcc = new Account(
            Name = 'Different Distributor',
            Type = 'Supplier',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId(),
            varcpq__Net_terms__c = 'NET30',
            varcpq__available_for_po__c = true
        );
        insert nonMatchingDistributorAcc;

        Id PricebookId = Test.getStandardPricebookId();
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);
        update standardPricebook;

        Pricebook2 customPricebook = new Pricebook2(Name = 'Integration Price Book', CurrencyIsoCode = 'CAD', IsActive = true);
        insert customPricebook;

        Product2 product = new Product2(
            Name = 'Test Product',
            varcpq__LISTPRICE__c = 100,
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product',
            varcpq__Distributor_Account__c = nonMatchingDistributorAcc.Id
        );
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

        QuoteLineItem longDescQLI = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = product.Id,
            Quantity = 2,
            UnitPrice = 200,
            Description = 'X'.repeat(100),
            Description__c = null
        );
        insert longDescQLI;

        longDescQLIId = longDescQLI.Id;
    }

    @isTest
    static void testMultipleQuoteLineItems() {
        QuoteLineItem qli = [SELECT Id, CurrencyIsoCode, Quantity FROM QuoteLineItem LIMIT 1];

        Test.startTest();
        qli.Quantity = 2;
        delete qli;
        Test.stopTest();
    }

    @isTest
    static void testDistributorAccountValidationOnQuote() {
        Quote quote = [SELECT Id, Account.RecordTypeId, QLI_from_different_country__c,
                       (SELECT Id, Product2Id, Product2.varcpq__Distributor_Account__r.RecordTypeId FROM QuoteLineItems)
                       FROM Quote LIMIT 1];

        List<Quote> quoteList = new List<Quote>{quote};

        Test.startTest();
        distributorAccountValidationOnQuote.accValidation(quoteList);
        Test.stopTest();

        Quote updatedQuote = [SELECT Id, QLI_from_different_country__c FROM Quote WHERE Id = :quote.Id];

        System.assertEquals(false, distributorAccountValidationOnQuote.flag, 'Flag should be false');
        System.assertEquals(true, updatedQuote.QLI_from_different_country__c, 'QLI_from_different_country__c should be true if distributor does not match');
    }

/*@isTest
static void testLongDescriptionLogic() {
    // Query for the QuoteLineItem using known properties
    QuoteLineItem qli = [
        SELECT Id, Description, Description__c, Product2.Description
        FROM QuoteLineItem
        WHERE Description LIKE :('X%') AND Quantity = 2
        LIMIT 1
    ];

    System.assertNotEquals(null, qli, 'Expected QuoteLineItem with long description');

    // Validate trigger behavior on insert
    System.assertNotEquals(null, qli.Description__c, 'Description__c should be populated by trigger');
    System.assert(qli.Description__c.length() > 0, 'Description__c should not be empty');

    // Simulate update
    Test.startTest();
    qli.Description = qli.Description + ' Updated';
    update qli;
    Test.stopTest();

    // Re-fetch and assert post-update values
    QuoteLineItem updatedQLI = [
        SELECT Description, Description__c
        FROM QuoteLineItem
        WHERE Id = :qli.Id
    ];
    System.assert(updatedQLI.Description.length() <= 255, 'Description should be truncated to 255 if needed');
    System.assertNotEquals(null, updatedQLI.Description__c, 'Description__c should remain populated after update');
}


       // QuoteLineItem updatedQLI = [SELECT Description, Description__c FROM QuoteLineItem WHERE Id = :qli.Id];
      //  System.assertNotEquals(null, updatedQLI.Description__c, 'Description__c should be populated from Product2.Description by trigger');
      //  System.assert(updatedQLI.Description.length() <= 255, 'Description should be truncated if needed');
   // }
*/
    @isTest
    static void testInsertQuoteLineItemWithShortDescription() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100,
            Description = 'Short desc'
        );

        Test.startTest();
        insert qli;
        Test.stopTest();

        QuoteLineItem insertedQLI = [SELECT Description, Description__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assert(insertedQLI.Description == 'Short desc', 'Description should remain unchanged for short descriptions');
    }

  @isTest
static void testUpdateDescriptionCOnQuoteLineItem() {
    QuoteLineItem qli = [SELECT Id, Description__c, Product2Id FROM QuoteLineItem LIMIT 1];

    Test.startTest();
    qli.Description__c = 'New Description from Test';
    update qli;
    Test.stopTest();

    Product2 prod = [SELECT Description FROM Product2 WHERE Id = :qli.Product2Id];
    System.assertEquals('New Description from Test', prod.Description, 'Product2.Description should update when Description__c changes');
}


    @isTest
    static void testTriggerCallsTaxDetailsHandler() {
        QuoteLineItem qli = [SELECT Id, Description, Product2Id FROM QuoteLineItem LIMIT 1];

        Test.startTest();
        qli.Description = 'Testing TaxDetailsHandler call';
        update qli;
        Test.stopTest();
        // Just making sure no exceptions, coverage of TaxDetailsHandler.processTaxDetails occurs
    }
}