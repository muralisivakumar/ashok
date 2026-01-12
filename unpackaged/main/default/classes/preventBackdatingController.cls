public class preventBackdatingController {
    public static void invoiceBackdating(List<varcpq__Invoice__c> invoices){
        for(varcpq__invoice__c invoice: invoices){
            if(!getValidationforAR(invoice.varcpq__Issued_Date__c)){
                invoice.addError('Backdating Issued Date is not Allowed');
            }
        }        
    }
    
    
    
    public static boolean getValidationforAR(Date issuedDate){
        List<Accounting_Configuration__c> accountingConfig = [SELECT Id, Name, Days_AR_Issue_Date_Remain_Open__c, AP_Closed_Books_Date__c FROM Accounting_Configuration__c WHERE Is_Active__c = true LIMIT 1];
        if(!accountingConfig.isEmpty()){
            Integer businessDay = Integer.valueOf(accountingConfig[0].Days_AR_Issue_Date_Remain_Open__c);
            Boolean isValid = true;
            Date today = Date.today();
            Date startDate = today.toStartOfMonth();
            
            Date cutOffDateStart = getBusinessDate(startDate,businessDay);
            System.debug('cutOffDateStart '+cutOffDateStart);
           // Date cutoffDateEnd = getBusinessDate(startDate.addMonths(1),businessDay);
            Date cutoffMonthStart = cutOffDateStart.toStartOfMonth();
            //System.debug('cutoffDateEnd '+cutoffDateEnd);
            System.debug('today '+today);
            System.debug('issuedDate '+issuedDate);
            System.debug('startDate '+startDate);
            if( issuedDate < cutoffMonthStart && today >= cutOffDateStart){ // Compares that the issued date should not be before the starting date of the cutoffDatestart month
                isValid = false;
            }
            
            return isValid;
        }
        return true;
    }
    
    public static Date getBusinessDate(Date inputDate, Integer n) {
        // StartDate = start of the month || n = number of business days
        // Validate inputs
        if (inputDate == null) {
            throw new IllegalArgumentException('Input date cannot be null');
        }
        if (n < 0) {
            throw new IllegalArgumentException('Number of business days must be positive');
        }
        Date today = Date.today();
        
        Date thisMonthStart = inputDate;
        Date resultDate = thisMonthStart;
        Integer businessDaysAdded = 0;
        
        // Move forward from this month's start
        while (businessDaysAdded < n) {
            resultDate = resultDate.addDays(1);
            String dayOfWeek = DateTime.newInstance(resultDate, Time.newInstance(0,0,0,0)).format('E');
            
            if (dayOfWeek != 'Sat' && dayOfWeek != 'Sun') {
                businessDaysAdded++;
            }
        }
        
        // If result date is after today → recalc using previous month
        if (resultDate > today) {
            Date prevMonthStart = thisMonthStart.addMonths(-1);
            resultDate = prevMonthStart;
            businessDaysAdded = 0;
            
            while (businessDaysAdded < n) {
                resultDate = resultDate.addDays(1);
                String dayOfWeek = DateTime.newInstance(resultDate, Time.newInstance(0,0,0,0)).format('E');
                
                if (dayOfWeek != 'Sat' && dayOfWeek != 'Sun') {
                    businessDaysAdded++;
                }
            }
        }
        
        return resultDate;
        
    }
    
    
}