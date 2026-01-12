/**
 * @description Helper class that handles the asynchronous processing of Avalara tax calculations.
 *              Relies on Avalara's mapper for field requirements and validation.
 *
 * @dependencies
 * - AvalaraTaxConfig.cls
 * - SOTaxCalculator.cls
 * - Avalara_Tax_Configuration__mdt
 */
public class AvalaraTaxHelper implements Queueable, Database.AllowsCallouts {
  private Set<Id> recordIds;
  private String objectType;
  public static Boolean isProcessing = false;

  public AvalaraTaxHelper(Set<Id> recordIds, String objectType) {
    this.recordIds = recordIds;
    this.objectType = objectType;
  }

  public void execute(QueueableContext context) {
    isProcessing = true;
    try {
      Avalara_Tax_Configuration__mdt config = AvalaraTaxConfig.getParentConfigs()
        .get(objectType);
      if (config == null) {
        System.debug(
          LoggingLevel.ERROR,
          'No configuration found for object type: ' + objectType
        );
        return;
      }

      // Process each record
      for (Id recordId : recordIds) {
        try {
          System.debug('Processing Record ID: ' + recordId);

          // Query just the Id since Avalara will handle the rest
          SObject record = Database.query(
            'SELECT Id FROM ' + objectType + ' WHERE Id = :recordId'
          );
          ApexPages.StandardController sc = new ApexPages.StandardController(
            record
          );

          // Process based on object type
          if (objectType == 'varcpq__Sales_Order__c') {
            SOTaxCalculator.salesOrderId = recordId;
            SOTaxCalculator taxCalc = new SOTaxCalculator(sc);
            taxCalc.calculateTaxButton();
          }
          // Add other object types here as needed

          System.debug('Tax calculation completed for record: ' + recordId);
        } catch (Exception e) {
          System.debug(
            LoggingLevel.ERROR,
            'Error calculating tax for record ' + recordId
          );
          System.debug(LoggingLevel.ERROR, 'Error message: ' + e.getMessage());
          System.debug(
            LoggingLevel.ERROR,
            'Stack trace: ' + e.getStackTraceString()
          );
        }
      }
    } finally {
      isProcessing = false;
    }
  }
}