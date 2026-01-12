/***************************************************************************************************************************************************************************************
* @description       : Trigger Handler for QuoteStateReverter and QuoteLineStateReverter. To roll back the status of code if the quote is edited with certain field.
* @author            : Aress Software - AS
* @Created date      : 05/03/2025
* @related class     : -
* @test Class        : - QuoteStateReverter_Test
* @last modified on  : - 12/03/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

public class QuoteStateReverterHandler {
    public Static void quoteStateReverter(List<Quote>quoteList,Map<Id,Quote>oldQuoteMap){
        List<Quote>quoteListToUpdate = new List<Quote>();  
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        System.debug('size '+quoteList.size());
        for(Quote objQuote : quoteList){  
            System.debug('quoteid '+objQuote.Id);
            // To lock the qlis from further edit when accepted
            if(objQuote.Status == 'Sales Order Created' && oldQuoteMap.get(objQuote.Id).Status =='Accepted'){
                objQuote.varcpq__isApproved__c = true;
            }
            // To lock the quote from further edit when accepted or SO Created. Error only for non-system admin
            else if(objQuote.Status =='Sales Order Created' && UserInfo.getProfileId()!= profileList[0].Id){
                System.debug('cond1 '+objQuote.Status =='Sales Order Created');
                System.debug('status '+objQuote.Status);
                System.debug('In else if');
                objQuote.addError('This Quote is locked from further edit. Please contact Admin.');
            }
            
            // To rollback the status of quote when edited.
            if(objQuote.Status !='Sales Order Created' && objQuote.Status !='Draft'){
                if(checkCondition(objQuote,oldQuoteMap.get(objQuote.Id))){               
                    objQuote.Status ='Draft'; 
                    quoteListToUpdate.add(objQuote);   
                }                
            }
        }
    }
    
    // To rollback quote status when quotelineitem is edited
    public Static void quoteLineStateReverter(List<QuoteLineItem>quoteLineList,Map<Id,QuoteLineItem>oldQLMap){
        SET<ID>quoteSet = new SET<ID>();
        for(QuoteLineItem objQLItem : quoteLineList){
            if(objQLItem.QuoteId!=null){
                if(objQLItem.Quantity != oldQLMap.get(objQLItem.Id).Quantity
                   || objQLItem.varcpq__Unit_Cost__c != oldQLMap.get(objQLItem.Id).varcpq__Unit_Cost__c
                   || objQLItem.UnitPrice != oldQLMap.get(objQLItem.Id).UnitPrice
                  ){ 
                      quoteSet.add(objQLItem.QuoteId);
                  }
            }
        }        
        List<Quote>quoteListToUpdate = new List<Quote>();      
        List<Quote>quoteDBList = [SELECT ID,Status FROM Quote Where ID IN :quoteSet];
        
        for(Quote objQ :quoteDBList){
            if(objQ.Status!= 'Sales Order Created' &&  objQ.Status!='Draft'){
                objQ.Status='Draft'; 
                quoteListToUpdate.add(objQ);
            }  
        }
        Database.Update(quoteListToUpdate,false);       
    }
    
    //Checks the new and old field values to check whether the quote is edited or not
    private static boolean checkCondition(Quote newQuote, Quote oldQuote){
        /*if(newQuote.BillingName != oldQuote.BillingName
||newQuote.BillingAddress !=oldQuote.BillingAddress
||newQuote.ShippingName!= oldQuote.ShippingName 
||newQuote.ShippingAddress !=oldQuote.ShippingAddress
||newQuote.ShippingStreet != oldQuote.ShippingStreet
||newQuote.ShippingCity != oldQuote.ShippingCity
||newQuote.ShippingState != oldQuote.ShippingState
||newQuote.ShippingCountry != oldQuote.ShippingCountry
||newQuote.ShippingPostalCode != oldQuote.ShippingPostalCode
||newQuote.BillingStreet != oldQuote.BillingStreet
||newQuote.BillingCity != oldQuote.BillingCity
||newQuote.BillingState != oldQuote.BillingState
||newQuote.BillingCountry != oldQuote.BillingCountry
||newQuote.BillingPostalCode != oldQuote.BillingPostalCode
||newQuote.varcpq__Tax_Rate__c!= oldQuote.varcpq__Tax_Rate__c
||newQuote.Tax_Rate_GST__c !=oldQuote.Tax_Rate_GST__c
||newQuote.Tax_Rate_PST__c!=oldQuote.Tax_Rate_PST__c
||newQuote.Tax_Rate_HST__c!=oldQuote.Tax_Rate_HST__c
||newQuote.Tax_Rate_QST__c!=oldQuote.Tax_Rate_QST__c
||newQuote.varcpq__Estimated_Lead_Time__c!= oldQuote.varcpq__Estimated_Lead_Time__c
||newQuote.ShippingHandling !=oldQuote.ShippingHandling
||newQuote.Quote_Net_Terms__c!=oldQuote.Quote_Net_Terms__c
||newQuote.ExpirationDate!= oldQuote.ExpirationDate
||newQuote.Quote_Line_Item_Count__c != oldQuote.Quote_Line_Item_Count__c){
return true;
}*/
        if(	 newQuote.ShippingName!= oldQuote.ShippingName 
           ||newQuote.ShippingAddress !=oldQuote.ShippingAddress
           ||newQuote.ShippingStreet != oldQuote.ShippingStreet
           ||newQuote.ShippingCity != oldQuote.ShippingCity
           ||newQuote.ShippingState != oldQuote.ShippingState
           ||newQuote.ShippingCountry != oldQuote.ShippingCountry
           ||newQuote.ShippingPostalCode != oldQuote.ShippingPostalCode
           //||newQuote.Tax != oldQuote.Tax
           //||newQuote.varcpq__Tax_Rate__c!= oldQuote.varcpq__Tax_Rate__c
           //||newQuote.Tax_Rate_GST__c !=oldQuote.Tax_Rate_GST__c
           //||newQuote.Tax_Rate_PST__c!=oldQuote.Tax_Rate_PST__c
           //||newQuote.Tax_Rate_HST__c!=oldQuote.Tax_Rate_HST__c
           //||newQuote.Tax_Rate_QST__c!=oldQuote.Tax_Rate_QST__c
           ||newQuote.ShippingHandling !=oldQuote.ShippingHandling
           ||newQuote.Quote_Net_Terms__c!=oldQuote.Quote_Net_Terms__c
           ||newQuote.Quote_Line_Item_Count__c != oldQuote.Quote_Line_Item_Count__c){
               return true;
           }
        return false;        
    }
    
    
}