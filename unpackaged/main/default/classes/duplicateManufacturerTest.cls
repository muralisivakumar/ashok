@isTest
public class duplicateManufacturerTest {

    // Helper method to create Manufacturer record
    private static varcpq__Manufacturer__c createManufacturer(String name) {
        return new varcpq__Manufacturer__c(Name = name);
    }

    @isTest
    static void testUniqueManufacturerInsert() {
        varcpq__Manufacturer__c m1 = createManufacturer('Unique Corp');
        insert m1;

        varcpq__Manufacturer__c m2 = createManufacturer('Another Unique Corp');
        Test.startTest();
        insert m2;
        Test.stopTest();

        System.assertEquals('Another Unique Corp', m2.Name);
    }

    @isTest
    static void testExactDuplicateManufacturerInsert() {
        varcpq__Manufacturer__c m1 = createManufacturer('Exact Corp');
        insert m1;

        varcpq__Manufacturer__c m2 = createManufacturer('Exact Corp');

        Test.startTest();
        try {
            insert m2;
            System.assert(false, 'Expected DMLException not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate Manufacturer name'), 'Expected duplicate error.');
        }
        Test.stopTest();
    }

    @isTest
    static void testCaseInsensitiveDuplicateInsert() {
        varcpq__Manufacturer__c m1 = createManufacturer('Case Corp');
        insert m1;

        varcpq__Manufacturer__c m2 = createManufacturer('case corp');

        Test.startTest();
        try {
            insert m2;
            System.assert(false, 'Expected DMLException not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate Manufacturer name'));
        }
        Test.stopTest();
    }

    
}