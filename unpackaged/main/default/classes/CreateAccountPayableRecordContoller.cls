/******************************************************************************************************************** 
* Apex Class Name   		: CreateAccountPayableRecordContoller
* Reference Component Name	: CreateAccountPayableRecord.
* Created By        		: Nupur Deshmukh
* Created Date      		: 12-05-2025
* Description 				: This Apex class is used for get Purchase Order and Case for Creating Account Payable Invoice. 
* Apex Test Class Reference : CreateAccountPayableRecordContollerTest
**********************************************************************************************************************/
public with sharing class CreateAccountPayableRecordContoller {
    
    //Method to get conditional Case ID / Purchase Order ID from Record Page
    @AuraEnabled
    public static Map<String, Object> getParentObjectType(Id recordId) {
        Map<String, Object> result = new Map<String, Object>();
        String objectType = recordId.getSObjectType().getDescribe().getName();
        if (objectType == 'varcpq__Purchase_Order__c') {
            result.put('parentType', 'PurchaseOrder');
            result.put('purchaseOrderId', recordId);
        } else if (objectType == 'Case') {
            result.put('parentType', 'Case');
            result.put('caseId', recordId);
        } else {
            result.put('parentType', 'None');
        }
        return result;
    }
    
    //Method to Update Invoice record and Case record respectively.
    @AuraEnabled
    public static void updateCaseOnInvoice(Id invoiceId, Id caseId) {
        System.debug('invoiceId => ' + invoiceId);
        System.debug('caseId => ' + caseId);
        
        if (invoiceId != null) {
            System.debug('In updateCaseOnInvoice IF =>');
            
            // Update newly created Invoice record
            varcpq__Accounts_Payable_Invoice__c inv = [SELECT Id, Case__c, varcpq__Purchase_Order__c,
                									   varcpq__Purchase_Order__r.varcpq__Distributor_Name__r.Id,
                   									   varcpq__Purchase_Order__r.varcpq__Sales_Order__r.Id 
                									   FROM varcpq__Accounts_Payable_Invoice__c WHERE Id = :invoiceId LIMIT 1];
            
            inv.Case__c = caseId;
            // Update Case record to reference Invoice
            Case caseRecord = [
                SELECT Id, Accounts_Payable_Invoice__c 
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            caseRecord.Accounts_Payable_Invoice__c = invoiceId;
            
            update new List<SObject> { inv, caseRecord };
            System.debug('Updated AP Inv => ' + inv);
            System.debug('Updated Case => ' + caseRecord);
        }
    }
    //Method to Update Invoice record and Case record respectively.
    @AuraEnabled
    public static void updateInvoicePOs(Id invoiceId) {
        System.debug('invoiceId => ' + invoiceId);
        
        if (invoiceId != null) {
            System.debug('In updateCaseOnInvoice IF =>');
            
            // Update newly created Invoice record
            varcpq__Accounts_Payable_Invoice__c inv = [SELECT Id, varcpq__Purchase_Order__c,
                									   varcpq__Purchase_Order__r.varcpq__Distributor_Name__r.Id,
                   									   varcpq__Purchase_Order__r.varcpq__Sales_Order__r.Id 
                									   FROM varcpq__Accounts_Payable_Invoice__c WHERE Id = :invoiceId LIMIT 1];
            
            // Always map Purchase Order fields if available
            if (inv.varcpq__Purchase_Order__c != null) {
                if (inv.varcpq__Purchase_Order__r.varcpq__Distributor_Name__r != null) {
                    inv.varcpq__Supplier__c = inv.varcpq__Purchase_Order__r.varcpq__Distributor_Name__r.Id;
                }
                if (inv.varcpq__Purchase_Order__r.varcpq__Sales_Order__r != null) {
                    inv.Sales_Order__c = inv.varcpq__Purchase_Order__r.varcpq__Sales_Order__r.Id;
                }
            }
        Update inv;
        system.debug('Updated Inv==>'+inv);
        }
    }
    
}