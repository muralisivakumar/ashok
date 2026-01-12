public class PurchaseOrderStatusTriggerHandler {
  public void run() {
    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('Trigger.new postat '+Trigger.new);
        System.debug('Trigger.oldMap '+Trigger.oldMap);
      handleAfterUpdate(
        (List<varcpq__Purchase_Order__c>) Trigger.new,
        (Map<Id, varcpq__Purchase_Order__c>) Trigger.oldMap
      );
    }
  }

  public void handleAfterUpdate(
    List<varcpq__Purchase_Order__c> newPurchaseOrders,
    Map<Id, varcpq__Purchase_Order__c> oldPurchaseOrderMap
  ) {
    Set<Id> salesOrderIds = new Set<Id>();

    for (varcpq__Purchase_Order__c po : newPurchaseOrders) {
        System.debug('po.varcpq__PO_Status__c '+po.varcpq__PO_Status__c);
        System.debug('oldPurchaseOrderMap.get(po.Id).varcpq__PO_Status__c '+oldPurchaseOrderMap.get(po.Id).varcpq__PO_Status__c);
      if (
        po.varcpq__PO_Status__c == 'PO Confirmed' &&
        po.varcpq__PO_Status__c !=
        oldPurchaseOrderMap.get(po.Id).varcpq__PO_Status__c
      ) {
        salesOrderIds.add(po.varcpq__Sales_Order__c);
          System.debug('so ids '+salesOrderIds);
      }
    }

    if (!salesOrderIds.isEmpty()) {
      TriggerExecutionContext.setIsRunningFromPOConfirmation(true);
      try {
          System.debug('in try');
        updateSalesOrderStatus(salesOrderIds);
      } finally {
        // Reset the flag even if an exception occurs
        TriggerExecutionContext.setIsRunningFromPOConfirmation(false);
      }
    }
  }

  private void updateSalesOrderStatus(Set<Id> salesOrderIds) {
    List<varcpq__Sales_Order__c> salesOrdersToUpdate = new List<varcpq__Sales_Order__c>();
	System.debug('so id 2 '+salesOrderIds);
    for (varcpq__Sales_Order__c so : [
      SELECT
        Id,
        varcpq__Stage__c,
        (SELECT Id, varcpq__PO_Status__c FROM varcpq__Purchase_Orders__r)
      FROM varcpq__Sales_Order__c
      WHERE Id IN :salesOrderIds AND varcpq__Stage__c = 'POs Created'
    ]) {
        System.debug('so '+so);
      Boolean allPOsConfirmed = true;

      for (varcpq__Purchase_Order__c po : so.varcpq__Purchase_Orders__r) {
        if (po.varcpq__PO_Status__c != 'PO Confirmed') {
          allPOsConfirmed = false;
          break;
        }
      }

      if (allPOsConfirmed && so.varcpq__Stage__c == 'POs Created') {
        so.varcpq__Stage__c = 'POs Confirmed';
        salesOrdersToUpdate.add(so);
      }
    }

    if (!salesOrdersToUpdate.isEmpty()) {
      update salesOrdersToUpdate;
    }
  }
}