/**
 * @description Configuration class that manages access to Avalara Tax Custom Metadata settings.
 *              This class provides caching and easy access to configurations that define
 *              parent-child relationships for tax calculation triggers.
 *
 * @dependencies
 * - Avalara_Tax_Configuration__mdt (Custom Metadata Type)
 *
 * @author Aaron Smith
 * @date 2025-01-27
 * @last modified by Aaron Smith
 * @last modified date 2025-01-27
 */
public class AvalaraTaxConfig {
  private static Map<String, Avalara_Tax_Configuration__mdt> parentConfigCache;
  private static Map<String, Avalara_Tax_Configuration__mdt> lineItemConfigCache;

  public static Map<String, Avalara_Tax_Configuration__mdt> getParentConfigs() {
    if (parentConfigCache == null) {
      parentConfigCache = new Map<String, Avalara_Tax_Configuration__mdt>();

      for (Avalara_Tax_Configuration__mdt config : [
        SELECT
          Id,
          Parent_Object_API_Name__c,
          Line_Item_Object_API_Name__c,
          Line_Item_Parent_Field_API_Name__c,
          Tax_Calculator_Class_Name__c,
          Parent_Monitored_Fields__c,
          Line_Item_Monitored_Fields__c,
          Active__c,
          Description__c
        FROM Avalara_Tax_Configuration__mdt
        WHERE Active__c = TRUE
      ]) {
        if (String.isNotBlank(config.Parent_Object_API_Name__c)) {
          parentConfigCache.put(config.Parent_Object_API_Name__c, config);
        }
      }
    }
    return parentConfigCache;
  }

  public static Avalara_Tax_Configuration__mdt getConfigForLineItem(
    String lineItemObjectName
  ) {
    if (lineItemConfigCache == null) {
      lineItemConfigCache = new Map<String, Avalara_Tax_Configuration__mdt>();

      for (
        Avalara_Tax_Configuration__mdt config : getParentConfigs().values()
      ) {
        if (String.isNotBlank(config.Line_Item_Object_API_Name__c)) {
          lineItemConfigCache.put(config.Line_Item_Object_API_Name__c, config);
        }
      }
    }
    return lineItemConfigCache.get(lineItemObjectName);
  }
}