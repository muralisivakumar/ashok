/***************************************************************************************************************************************************************************************
* @class Name     	 : POTaxCalculator
* @description       : Avalara Tax calculation controller on Purchase Order
* @author            : Aress Software - AS
* @Created date      : 03/05/2025
* @test Class        : POTaxCalculatorTest
* @VF Page           : POTaxCalculatorVFPage
* @last modified on  : 03/05/2025
* @last modified by  : Nupur Deshmukh
****************************************************************************************************************************************************************************************/

global class POTaxCalculator {
    public static Id POId = null;
    public POTaxCalculator() {}
    public POTaxCalculator(ApexPages.StandardController controller) {
        POId = controller.getRecord().id;
    }
    public PageReference calculateTaxButton() {
        calculateTax();
        return redirectPage();
    }
    static public void calculateTax() {
        try {
            Map<String,String> POParam = new Map<String,String>();
            AVA_MAPPER.TaxCalculator POObj = null;
            if (!Test.isRunningTest()) {
                AVA_SFCLOUD.ConfigurationProvider config = new AVA_SFCLOUD.ConfigurationProvider();
                //AVA_SFCPQ.ConfigProviderCPQ config = new AVA_SFCPQ.ConfigProviderCPQ(); //For AvaTaxCPQ+ Package
                
                POObj = new AVA_MAPPER.TaxCalculator(config.hookExtension(),'AVA_SFCLOUD__AvaTax_Mapping__c', 
                                                             'AVA_SFCLOUD__Field_Mapping__c');
            }
            System.debug('POObj -->'+POObj);
            AVA_MAPPER.TaxCalculationInput taxCalcInput = new AVA_MAPPER.TaxCalculationInput();
            taxCalcInput.recordId = POId;
            taxCalcInput.controller = 'varcpq__purchase_order__c'; //If the environment has namespace, append it to the object API name. Value should be in small letters.
            taxCalcInput.optionalParams = POParam;
            taxCalcInput.isMultiCommit = False;
            System.debug('taxCalcInput: '+taxCalcInput);
            Ava_Mapper.TransactionModel transResult = POObj.calculateTax(taxCalcInput);
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
        PageReference pageRef = new PageReference('/' + POId);
        pageRef.setRedirect(true);
        return pageRef;
    }
}