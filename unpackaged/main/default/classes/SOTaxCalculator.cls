/***************************************************************************************************************************************************************************************
* @description       : Avalara Tax calculation controller on Sales Order
* @author            : Aress Software - AS
* @Created date      : 04/10/2024
* @related class     : - 
* @test Class        : - SOTaxCalculatorTest
* @VF Page           : - salesOrderTaxCalculation
* @last modified on  : - 06/11/2024
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

global class SOTaxCalculator {
    public static Id salesOrderId = null;
    public SOTaxCalculator() {}
    public SOTaxCalculator(ApexPages.StandardController controller) {
        salesOrderId = controller.getRecord().id;
    }
    public PageReference calculateTaxButton() {
        calculateTax();
        return redirectPage();
    }
    static public void calculateTax() {
        try {
            Map<String,String> salesOrderParam = new Map<String,String>();
            AVA_MAPPER.TaxCalculator salesOrderObj = null;
            if (!Test.isRunningTest()) {
                AVA_SFCLOUD.ConfigurationProvider config = new AVA_SFCLOUD.ConfigurationProvider();
                //AVA_SFCPQ.ConfigProviderCPQ config = new AVA_SFCPQ.ConfigProviderCPQ(); //For AvaTaxCPQ+ Package
                
                salesOrderObj = new AVA_MAPPER.TaxCalculator(config.hookExtension(),'AVA_SFCLOUD__AvaTax_Mapping__c', 
                                                             'AVA_SFCLOUD__Field_Mapping__c');
            }
            System.debug('salesOrderObj -->'+salesOrderObj);
            AVA_MAPPER.TaxCalculationInput taxCalcInput = new AVA_MAPPER.TaxCalculationInput();
            taxCalcInput.recordId = salesOrderId;
            taxCalcInput.controller = 'varcpq__sales_order__c'; //If the environment has namespace, append it to the object API name. Value should be in small letters.
            taxCalcInput.optionalParams = salesOrderParam;
            taxCalcInput.isMultiCommit = False;
            System.debug('taxCalcInput: '+taxCalcInput);
            Ava_Mapper.TransactionModel transResult = salesOrderObj.calculateTax(taxCalcInput);
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
    public PageReference redirectPage() {
        PageReference pageRef = new PageReference('/' + salesOrderId);
        pageRef.setRedirect(true);
        return pageRef;
    }
}