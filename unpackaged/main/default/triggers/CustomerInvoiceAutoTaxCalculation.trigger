/***************************************************************************************************************************************************************************************
* @Trigger Name      : CustomerInvoiceAutoTaxCalculation.
* @description       : Avalara Automatic Tax calculation Trigger on Invoice Object.
* @author            : Aress Software - AS.
* @Created date      : 21/05/2025
* @Ref test Class    : InvoiceTaxCalculatorTest
* @Ref Apex Name     : InvoiceTaxCalculator
* @last modified on  : 21/05/2024
* @last modified by  : Nupur Deshmukh
****************************************************************************************************************************************************************************************/
trigger CustomerInvoiceAutoTaxCalculation on varcpq__Invoice__c (after insert) {
    System.debug('In CustomerInvoiceAutoTaxCalculation Trigger -->');
    
    for (varcpq__Invoice__c insertedInvoice : Trigger.new) {
        System.debug('Queueing tax calculation job for invoice --> ' + insertedInvoice.Id);
        System.enqueueJob(new InvoiceAutoTaxCalculationJob(insertedInvoice.Id));
    }
}