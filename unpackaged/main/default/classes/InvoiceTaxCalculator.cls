/***************************************************************************************************************************************************************************************
* @Class Name        : InvoiceTaxCalculator
* @description       : Avalara Tax calculation controller on Invoice Object
* @author            : Aress Software - AS
* @Created date      : 26/03/2025
* @test Class        : InvoiceTaxCalculatorTest
* @VF Page           : InvoiceTaxCalculatorVFPage
* @last modified on  : 06/11/2024
* @last modified by  : Nupur Deshmukh
****************************************************************************************************************************************************************************************/

global class InvoiceTaxCalculator {
    public static Id invoiceId = null;
    public InvoiceTaxCalculator() {}
    public InvoiceTaxCalculator(ApexPages.StandardController controller) {
        invoiceId = controller.getRecord().id;
    }
    public PageReference calculateTaxButton() {
        calculateTax();
        // postTax();
        return redirectPage();
    }
    static public void calculateTax() {
        try {
            Map<String,String> invoiceParam = new Map<String,String>();
            AVA_MAPPER.TaxCalculator invoiceObj = null;
            if (!Test.isRunningTest()) {
                AVA_SFCLOUD.ConfigurationProvider config = new AVA_SFCLOUD.ConfigurationProvider();
                //AVA_SFCPQ.ConfigProviderCPQ config = new AVA_SFCPQ.ConfigProviderCPQ(); //For AvaTaxCPQ+ Package
                
                invoiceObj = new AVA_MAPPER.TaxCalculator(config.hookExtension(),'AVA_SFCLOUD__AvaTax_Mapping__c','AVA_SFCLOUD__Field_Mapping__c');
            }
            System.debug('invoiceObj -->'+invoiceObj);
            AVA_MAPPER.TaxCalculationInput taxCalcInput = new AVA_MAPPER.TaxCalculationInput();
            taxCalcInput.recordId = invoiceId;
            System.debug('invoiceId -->'+invoiceId);
            taxCalcInput.controller = 'varcpq__invoice__c'; //If the environment has namespace, append it to the object API name. Value should be in small letters.
            taxCalcInput.optionalParams = invoiceParam;
            taxCalcInput.isMultiCommit = False;
            System.debug('taxCalcInput: '+taxCalcInput);
            Ava_Mapper.TransactionModel transResult = invoiceObj.calculateTax(taxCalcInput);
            System.debug('transResult: '+transResult);
            if (transResult.statusCode == 200 || transResult.statusCode == 201) {
                System.debug('success');
                //Tax calculation is successful. Add business logic as required to display the details.
            } else {
                //There is some error in Tax calculation.Error details will be available in below debug logs.
                System.debug('transResult.statusCode: ' + transResult.statusCode);
                System.debug('AVA_MAPPER.ErrorInfo error: ' + transResult.error);
            }
        } catch (Exception e) {
            system.debug('In exception '+e.getmessage());
        }
    }
    /*Public void postTax() {
AVA_SFCLOUD.ConfigurationProvider config = new AVA_SFCLOUD.ConfigurationProvider();
Map<String,String> ordParam = new Map<String,String>();
AVA_MAPPER.PostTaxCalculator postTaxObj = new
AVA_MAPPER.PostTaxCalculator(config.hookExtension(),'AVA_SFCLOUD__AvaTax_Mapping__c','AVA_ SFCLOUD__Field_Mapping__c');
AVA_MAPPER.QueryInput queryInput = new AVA_MAPPER.QueryInput();
queryInput.recordId = invoiceId;
queryInput.controller = invoiceId.getSObjectType().getDescribe().getName().toLowerCase();
queryInput.optionalParams = ordParam;
postTaxObj.executeQuery(queryInput);
AVA_MAPPER.PostTaxCalculationInput postTaxInput = new
AVA_MAPPER.PostTaxCalculationInput();
postTaxInput.companyCode = AVA_SFCLOUD__AvaTax__c.getInstance('AvaTaxConfig').AVA_SFCLOUD__Company_Code__c;
postTaxInput.transactionCode = String.valueof(invoiceId);
postTaxInput.commitFlag = False;
postTaxInput.docType = AVA_MAPPER.DocumentType.SalesInvoice;
AVA_MAPPER.TransactionModel postTaxResult = postTaxObj.postTax(postTaxInput);
if (postTaxResult.statusCode == 200 || postTaxResult.statusCode == 201) {
System.debug('success');
} else {
System.debug('error');
System.debug('transResult.statusCode: ' + postTaxResult.statusCode);
System.debug('AVA_MAPPER.ErrorInfo error: ' + postTaxResult.error);
}
}*/
    public PageReference redirectPage() {
        PageReference pageRef = new PageReference('/' + invoiceId);
        pageRef.setRedirect(true);
        return pageRef;
    }
}