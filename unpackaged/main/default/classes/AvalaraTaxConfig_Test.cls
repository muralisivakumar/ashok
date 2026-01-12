@IsTest
private class AvalaraTaxConfig_Test {
    @IsTest
    static void testGetParentConfigs() {
        Test.startTest();
        Map<String, Avalara_Tax_Configuration__mdt> configs = AvalaraTaxConfig.getParentConfigs();
        //System.assertNotEquals(null, configs, 'Config map should not be null');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfigForLineItem() {
        Test.startTest();
        Avalara_Tax_Configuration__mdt config = AvalaraTaxConfig.getConfigForLineItem('Order_Line_Item__c');
        //System.assertNotEquals(null, config, 'Config should not be null for valid line item');
        Test.stopTest();
    }
}