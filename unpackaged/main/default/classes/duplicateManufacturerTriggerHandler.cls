public class duplicateManufacturerTriggerHandler {
    public static void checkForDuplicates(List<varcpq__Manufacturer__c> newRecords) {
        Set<String> newNamesLower = new Set<String>();
        
        // Collect names in lowercase
        for (varcpq__Manufacturer__c m : newRecords) {
            if (m.Name != null) {
                newNamesLower.add(m.Name.toLowerCase());
            }
        }

        if (newNamesLower.isEmpty()) return;

        // Query existing records
        List<varcpq__Manufacturer__c> existingManufacturers = [
            SELECT Name 
            FROM varcpq__Manufacturer__c 
            WHERE Name != null
        ];

        Set<String> existingNamesLower = new Set<String>();
        for (varcpq__Manufacturer__c existing : existingManufacturers) {
            existingNamesLower.add(existing.Name.toLowerCase());
        }

        // Validate and raise errors
        for (varcpq__Manufacturer__c m : newRecords) {
            if (m.Name != null && existingNamesLower.contains(m.Name.toLowerCase())) {
                m.addError('Duplicate Manufacturer name "' + m.Name + '" already exists.');
            }
        }
    }
}