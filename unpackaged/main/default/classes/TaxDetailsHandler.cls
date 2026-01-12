public class TaxDetailsHandler {
  // Cache the tax configurations
  private static List<Tax_Type_Configuration__mdt> taxConfigs {
    get {
      if (taxConfigs == null) {
        taxConfigs = [
          SELECT
            Tax_Type__c,
            Pattern_Match__c,
            Rate_Field_API_Name__c,
            Amount_Field_API_Name__c
          FROM Tax_Type_Configuration__mdt
          WHERE Active__c = TRUE
        ];
      }
      return taxConfigs;
    }
    set;
  }

  // Cache object configurations
  private static Map<String, Tax_Object_Configuration__mdt> objectConfigs {
    get {
      if (objectConfigs == null) {
        objectConfigs = new Map<String, Tax_Object_Configuration__mdt>();
        for (Tax_Object_Configuration__mdt config : [
          SELECT
            Object_API_Name__c,
            Tax_Details_Field_API_Name__c,
            Parent_Relationship_Field_API_Name__c
          FROM Tax_Object_Configuration__mdt
          WHERE Active__c = TRUE
        ]) {
          objectConfigs.put(config.Object_API_Name__c, config);
        }
      }
      return objectConfigs;
    }
    set;
  }

  // Map to track parent records that need updating
  private static Map<Id, SObject> parentsToUpdate;

  // Common tax extraction patterns
  private static final Pattern TAX_AMOUNT_PATTERN = Pattern.compile(
    'Tax Amount:\\s*(\\d+\\.\\d+)'
  );
  private static final Pattern TAX_RATE_PATTERN = Pattern.compile(
    'Rate :\\s*(\\d+\\.?\\d{0,2})'
  );
  private static final Pattern TAX_NAME_PATTERN = Pattern.compile(
    'Tax Name :\\s*([^J]+)'
  );

  public class TaxDetail {
    public Decimal amount { get; set; }
    public Decimal rate { get; set; }
    public String taxName { get; set; }
  }

  public static void processTaxDetails(List<SObject> records) {
    if (records == null || records.isEmpty())
      return;
	System.debug('records -->11'+records);
    String objectType = records[0].getSObjectType().getDescribe().getName();
    Tax_Object_Configuration__mdt objConfig = objectConfigs.get(objectType);
	System.debug('objConfig -->11'+objConfig);
    if (objConfig == null)
      return;

    // Initialize parents map
    parentsToUpdate = new Map<Id, SObject>();

    // Process line items and collect parent records
    for (SObject record : records) {
      String taxDetails = (String) record.get(
        objConfig.Tax_Details_Field_API_Name__c
      );
      System.debug('taxDetails -->11'+taxDetails);
      if (String.isNotBlank(taxDetails)) {
          // Get parent ID using metadata-defined relationship field
        Id parentId = (Id) record.get(
          objConfig.Parent_Relationship_Field_API_Name__c
        );
          System.debug('parentid 85 '+parentId);
        if (parentId != null && !parentsToUpdate.containsKey(parentId)) {
          SObject parent = parentId.getSObjectType().newSObject(parentId);
          parentsToUpdate.put(parentId, parent);
            System.debug('parentsToUpdate 92 '+parentsToUpdate);
        }
        processSingleRecord(record, taxDetails);

        
      }
    }
      System.debug('parentsToUpdate -->11'+parentsToUpdate);

    // Process parent records if any need updating
    if (!parentsToUpdate.isEmpty()) {
      processParentRecords(records[0]);
    }
  }
@testVisible
  private static void processParentRecords(SObject record) {
    try {
      System.debug('### Starting processParentRecords ###');

      Tax_Object_Configuration__mdt objConfig = objectConfigs.get(
        record.getSObjectType().getDescribe().getName()
      );
      System.debug('Object config: 11' + objConfig);

      // Get parent type directly from the first parent record ID
      Id firstParentId;
      for (Id parentId : parentsToUpdate.keySet()) {
        firstParentId = parentId;
        break;
      }

      if (firstParentId == null) {
        System.debug('No parent ID found - returning');
        return;
      }
      System.debug('firstParentId -->11'+firstParentId);

      // Get the fully qualified (with namespace) object name
      Schema.DescribeSObjectResult parentDescribe = firstParentId.getSObjectType().getDescribe();
      String parentType = parentDescribe.getName();
      System.debug('### Parent Type (with namespace): 11' + parentType);

      // Build dynamic query for parent records
      List<String> fields = new List<String>{ 'Id' };
      for (Tax_Type_Configuration__mdt config : taxConfigs) {
        if (String.isNotBlank(config.Rate_Field_API_Name__c)) {
          fields.add(config.Rate_Field_API_Name__c.trim());
        }
      }
	System.debug('parentsmap 138 '+parentsToUpdate);
      // Convert the Set of Ids to a list of strings for the IN clause
      List<String> idStrings = new List<String>();
      for (Id parentId : parentsToUpdate.keySet()) {
        idStrings.add('\'' + String.escapeSingleQuotes(parentId) + '\'');
      }
		System.debug('idStrings -->11'+idStrings);
      String query =
        'SELECT ' +
        String.join(fields, ', ') +
        ' FROM ' +
        parentType +
        ' WHERE Id IN (' +
        String.join(idStrings, ',') +
        ')';

      System.debug('### Final Query: [' + query + ']');

      // Query existing parent records
      List<SObject> existingParentList = Database.query(query);
      Map<Id, SObject> existingParents = new Map<Id, SObject>(
        existingParentList
      );
	System.debug('existingParentList -->11'+existingParentList);
      System.debug('Found existing parents: ' + existingParents.size());

      // Update parents
      if (!parentsToUpdate.isEmpty()) {
        try {
          System.debug(
            'Updating parents with values: ' + parentsToUpdate.values()
          );
          update parentsToUpdate.values();
        } catch (Exception e) {
          System.debug('Error updating parents: ' + e.getMessage());
          throw e;
        }
      }
    } catch (Exception e) {
      System.debug('### Error in processParentRecords ###');
      System.debug('Error message: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());
      throw e;
    }
  }
@testVisible
  private static void processSingleRecord(SObject record, String taxDetails) {
    // Reset all tax fields based on configuration
    for (Tax_Type_Configuration__mdt config : taxConfigs) {
      record.put(config.Rate_Field_API_Name__c, 0);
      record.put(config.Amount_Field_API_Name__c, 0);
    }

    // Split into individual tax entries
    List<String> taxEntries = taxDetails.split(',');

    for (String entry : taxEntries) {
      if (String.isBlank(entry))
        continue;

      TaxDetail tax = extractTaxDetail(entry);
      if (tax == null)
        continue;
		System.debug('Tax -->11'+tax);
      // Check each tax configuration for a match
      System.debug('parentsmap 203 '+parentsToUpdate);
      for (Tax_Type_Configuration__mdt config : taxConfigs) {
        Pattern taxPattern = Pattern.compile('(?i)' + config.Pattern_Match__c);
        if (taxPattern.matcher(tax.taxName).find()) {
          record.put(config.Rate_Field_API_Name__c, tax.rate.setScale(2));
          record.put(config.Amount_Field_API_Name__c, tax.amount);
          System.debug('record -->11'+record);
          updateParentTaxRate(record, config, tax.rate);
          break;
        }
      }
    }
  }
@testVisible
  private static void updateParentTaxRate(
    SObject record,
    Tax_Type_Configuration__mdt config,
    Decimal rate
  ) {
    if (parentsToUpdate != null && rate > 0) {
      Tax_Object_Configuration__mdt objConfig = objectConfigs.get(
        record.getSObjectType().getDescribe().getName()
      );
      Id parentId = (Id) record.get(
        objConfig.Parent_Relationship_Field_API_Name__c
      );
        
      if (parentId != null) {
        SObject parent = parentsToUpdate.get(parentId);
          System.debug('parentmap '+parentsToUpdate);
          System.debug('parent 228-->11'+parent);
        if (parent != null) {
          System.debug(
            'Setting parent tax rate: ' +
              rate +
              ' for field: 11' +
              config.Rate_Field_API_Name__c
          );
          parent.put(config.Rate_Field_API_Name__c, rate.setScale(2));
            System.debug('parent--> 11'+parent);
        }
      }
    }
  }
@testVisible
  private static TaxDetail extractTaxDetail(String entry) {
    TaxDetail detail = new TaxDetail();

    // Extract amount
    Matcher amountMatcher = TAX_AMOUNT_PATTERN.matcher(entry);
    if (!amountMatcher.find())
      return null;
    detail.amount = Decimal.valueOf(amountMatcher.group(1));

    // Extract rate and store as percentage value (e.g., 8.25 for 8.25%)
    Matcher rateMatcher = TAX_RATE_PATTERN.matcher(entry);
    if (!rateMatcher.find())
      return null;
    detail.rate = Decimal.valueOf(rateMatcher.group(1)).setScale(2);

    // Extract tax name
    Matcher nameMatcher = TAX_NAME_PATTERN.matcher(entry);
    if (!nameMatcher.find())
      return null;
    detail.taxName = nameMatcher.group(1).trim();

    return detail;
  }

  @TestVisible
  private static void resetCache() {
    taxConfigs = null;
    objectConfigs = null;
    parentsToUpdate = null;
  }
}