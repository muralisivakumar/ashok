public class InvoiceAutoTaxCalculationJob implements Queueable, Database.AllowsCallouts {
    private Id invoiceId;

    public InvoiceAutoTaxCalculationJob(Id invoiceId) {
        this.invoiceId = invoiceId;
    }

    public void execute(QueueableContext context) {
        varcpq__Invoice__c invoice = [SELECT Id FROM varcpq__Invoice__c WHERE Id = :invoiceId LIMIT 1];

        try {
            ApexPages.StandardController sc = new ApexPages.StandardController(invoice);
            InvoiceTaxCalculator invTaxCalc = new InvoiceTaxCalculator(sc);
            invTaxCalc.calculateTaxButton();
        } catch (Exception e) {
            System.debug('Error calculating tax: ' + e.getMessage());
        }
    }
}