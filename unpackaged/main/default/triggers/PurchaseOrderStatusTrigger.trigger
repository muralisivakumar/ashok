trigger PurchaseOrderStatusTrigger on varcpq__Purchase_Order__c(after update) {
  new PurchaseOrderStatusTriggerHandler().run();
}