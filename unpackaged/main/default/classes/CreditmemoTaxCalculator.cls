/***************************************************************************************************************************************************************************************
* @Class Name        : CreditmemoTaxCalculator
* @description       : Avalara Tax calculation controller on Manual Credit Memo Object
* @author            : Aress Software - AS
* @Created date      : 26/03/2025
* @test Class        : CreditmemoTaxCalculatorTest
* @VF Page           : CreditmemoTaxCalculatorVFPage
* @last modified on  : 03/9/2025
* @last modified by  : Pooja
****************************************************************************************************************************************************************************************/




public class CreditmemoTaxCalculator {

    public static Id rmaId = null;
     public static Id creditMemoId = null;
    public CreditmemoTaxCalculator() {}
    public CreditmemoTaxCalculator(ApexPages.StandardController controller) {
        creditMemoId = controller.getRecord().id;
        List<Manual_Credit_Memo__c> mcm = [SELECT ID,Return_Merchandise_Authorization__c FROM Manual_Credit_Memo__c WHERE ID =: creditMemoId
                                          LIMIT 1];
        rmaId = mcm[0].Return_Merchandise_Authorization__c;
    }
    public PageReference calculateTaxButton() {
        calculateTax();
        // postTax();
        return redirectPage();
    }
    static public void calculateTax() {
        try {
            Map<String,String> memoParam = new Map<String,String>();
            AVA_MAPPER.TaxCalculator rmaObj = null;
            if (!Test.isRunningTest()) {
                AVA_SFCLOUD.ConfigurationProvider config = new AVA_SFCLOUD.ConfigurationProvider();
                //AVA_SFCPQ.ConfigProviderCPQ config = new AVA_SFCPQ.ConfigProviderCPQ(); //For AvaTaxCPQ+ Package
                
                rmaObj = new AVA_MAPPER.TaxCalculator(config.hookExtension(),'AVA_SFCLOUD__AvaTax_Mapping__c','AVA_SFCLOUD__Field_Mapping__c');
            }
            System.debug('invoiceObj -->'+rmaObj);
            AVA_MAPPER.TaxCalculationInput taxCalcInput = new AVA_MAPPER.TaxCalculationInput();
            taxCalcInput.recordId = rmaId;
            System.debug('rmaId --------------------->'+rmaId);
            taxCalcInput.controller = 'return_merchandise_authorization__c'; //If the environment has namespace, append it to the object API name. Value should be in small letters.
            taxCalcInput.optionalParams = memoParam;
            taxCalcInput.isMultiCommit = False;
            System.debug('taxCalcInput: '+taxCalcInput);
            Ava_Mapper.TransactionModel transResult = rmaObj.calculateTax(taxCalcInput);
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
        PageReference pageRef = new PageReference('/' + creditMemoId);
        pageRef.setRedirect(true);
        return pageRef;
    }
}