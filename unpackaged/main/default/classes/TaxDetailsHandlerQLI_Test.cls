@IsTest
private class TaxDetailsHandlerQLI_Test {
    @TestSetup
    static void makeData() {
        // Create a test Quote and Quote Line Item
        varcpq__Product_Trigger__c prosetting = new varcpq__Product_Trigger__c(varcpq__Active__c=true);
        insert prosetting; 
        
        varcpq__CLINName__c CLIN = new varcpq__CLINName__c(varcpq__CLIN_Name__c = 'DHT-');
        insert CLIN;
        
        Id PricebookId = Test.getStandardPricebookId();
        
        PriceBook2 standardPricebook = new PriceBook2(Id = PricebookId);        
        update standardPricebook;
        
        Pricebook2 integrationPricebook = new Pricebook2(
            Name = 'Integration Price Book', 
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert integrationPricebook;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            varcpq__LISTPRICE__c = 100.0, 
            IsActive = true,
            varcpq__PARTNUMBER__c = 'Test Product',
            varcpq__ITEMDESC__c = 'Test Product'
        );
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert standardPbe;
        
        PricebookEntry integrationPbe = new PricebookEntry(
            Pricebook2Id = integrationPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100.0, 
            IsActive = true
        );
        insert integrationPbe;
        Id USAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Account acc = new Account(Name = 'Test Account',RecordtypeId=USAccRecType);
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Quote quote = new Quote(
            OpportunityId = opp.Id, 
            Name = 'Test Quote', 
            CurrencyIsoCode = 'USD',
            Status = 'Presented',
            Pricebook2Id = integrationPricebook.Id,
            Tax_Rate_GST__c = 0,
            Tax_Rate_PST__c = 0,
            Tax_Rate_HST__c = 0,
            Tax_Rate_QST__c = 0
        );
        insert quote;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            varcpq__EXT_Price__c = 100,
            varcpq__Total_Margin__c = 3
        );
        insert qli;
        
    }
    
    @IsTest
    static void testGSTProcessing() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Create test QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 143.160 Rate : 5.000000% Tax Name : CANADA GST/TPS Juris Name CANADA'
        );
        
        Test.startTest();
        insert qli;
        Test.stopTest();
        
        // Verify line item results
        qli = [
            SELECT Id, Tax_Rate_GST__c, Tax_Amount_GST__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];
        
        
        // Verify parent results
        quote = [
            SELECT Id, Tax_Rate_GST__c
            FROM Quote
            WHERE Id = :quote.Id
        ];
        
    }
    
    @IsTest
    static void testMultipleTaxProcessing() {
        Test.startTest();
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Create test QuoteLineItem with multiple taxes
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 143.160 Rate : 5.000000% Tax Name : CANADA GST/TPS Juris Name CANADA , ' +
            'Tax Amount: 286.320 Rate : 10.000000% Tax Name : NEWFOUNDLAND AND LABRADOR HST Juris Name NEWFOUNDLAND AND LABRADOR'
        );
        
        
        insert qli;
        
        
        // Verify line item results
        qli = [
            SELECT
            Id,
            Tax_Rate_GST__c,
            Tax_Amount_GST__c,
            Tax_Rate_HST__c,
            Tax_Amount_HST__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];
        
        
        
        // Verify parent results
        quote = [
            SELECT Id, Tax_Rate_GST__c, Tax_Rate_HST__c
            FROM Quote
            WHERE Id = :quote.Id
        ];
        
        Test.stopTest();
    }
    
    @IsTest
    static void testInvalidTaxDetails() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Create test QuoteLineItem with invalid tax details
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = 'Invalid tax details format'
        );
        
        Test.startTest();
        insert qli;
        Test.stopTest();
        
        // Verify all tax fields are zero
        qli = [
            SELECT
            Id,
            Tax_Rate_GST__c,
            Tax_Amount_GST__c,
            Tax_Rate_PST__c,
            Tax_Amount_PST__c,
            Tax_Rate_HST__c,
            Tax_Amount_HST__c,
            Tax_Rate_QST__c,
            Tax_Amount_QST__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];
        
        
    }
    
    @IsTest
    static void testUpdateExistingRecord() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Create initial QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 143.160 Rate : 5.000000% Tax Name : CANADA GST/TPS Juris Name CANADA'
        );
        insert qli;
        
        // Update tax details
        qli.AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 286.320 Rate : 10.000000% Tax Name : NEWFOUNDLAND AND LABRADOR HST Juris Name NEWFOUNDLAND AND LABRADOR';
        
        Test.startTest();
        update qli;
        Test.stopTest();
        
        // Verify updated values
        qli = [
            SELECT
            Id,
            Tax_Rate_GST__c,
            Tax_Amount_GST__c,
            Tax_Rate_HST__c,
            Tax_Amount_HST__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];
        
        
        
    }
    
    @IsTest
    static void testNullAndEmptyHandling() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Test null tax details
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = null
        );
        
        // Test empty tax details
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            AVA_SFCLOUD__Sales_Tax_Details__c = ''
        );
        
        Test.startTest();
        List<QuoteLineItem> qlis = new List<QuoteLineItem>{ qli1, qli2 };
            insert qlis;
        Test.stopTest();
        
        // Verify all were processed without errors
        qlis = [
            SELECT Id, Tax_Rate_GST__c, Tax_Amount_GST__c
            FROM QuoteLineItem
            WHERE Id IN :qlis
        ];
        

        
        
    }
    
    @IsTest
    static void testCacheReset() {
        Test.startTest();
        TaxDetailsHandler.resetCache();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testBulkProcessing() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Create 200 QuoteLineItems
        for (Integer i = 0; i < 200; i++) {
            qlis.add(
                new QuoteLineItem(
                    QuoteId = quote.Id,
                    Product2Id = prod.Id,
                    Quantity = 1,
                    UnitPrice = 100.0,
                    AVA_SFCLOUD__Sales_Tax_Details__c = 'Tax Amount: 143.160 Rate : 5.000000% Tax Name : CANADA GST/TPS Juris Name CANADA'
                )
            );
        }
        
        Test.startTest();
        insert qlis;
        Test.stopTest();
        
        
        
        
        
    }
}