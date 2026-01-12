/***************************************************************************************************************************************************************************************
* @description       : Controller Class for Clone Quote and Clone Quote to new Opportunity
* @author            : Aress Software - AS
* @Created date      : 09/05/2024
* @related class     : -
* @test Class        : - cloneOppQuote_Test
* @last modified on  : - 10/10/2025
* @last modified by  : - Kunal Deshpande
****************************************************************************************************************************************************************************************/

/* Clone Quote for better UX.
* Option A - Clone Quote for the existing Opportunity
* Option B - Clone Quote for new Opportunity
* Option C - Clone Quote for different existing Opportunity (backloged)
*/ 

public class cloneOppQuote {
    @AuraEnabled
    public static Quote getQuoteInfo(Id quoteId){
        if(quoteId != null){
            Quote quote = [SELECT Id,opportunityId,Account_Record_Type__c, AccountId, Account.recordTypeId FROM Quote WHERE Id =: quoteId];
            return quote;
        }
        return null;
    }
    
    // Option B - Clone Quote for new Opportunity
    @AuraEnabled
    public static Id cloneQuoteToNewOpp(Id quoteId,Id accId,String oppName,String leadSource, Date closeDate,String recordType, Decimal amount,
                                        Decimal margin, String dealRegistered, String isSE, List<Id> userIds)
    {	
        System.debug('isSE '+isSE);
        // Step 1: Query Account owner
        Opportunity opp = new Opportunity();
        opp.Name = oppName;
        opp.AccountId = accId;
        opp.LeadSource = leadSource;
        opp.CloseDate = closeDate;
        opp.Amount = amount;
        opp.varcpq__Margin__c = margin;
        if (dealRegistered == 'Yes') {
            opp.varcpq__Registered__c = true;
        } 
        else {
            opp.varcpq__Registered__c = false;
        }
        if(!userIds.isEmpty()){ 
            opp.SE_Assigned__c = userIds[0]; 
        }                               
        
        insert opp;
        
        // Handle Opportunity Team Members
        if (isSE == 'Yes' && userIds != null && !userIds.isEmpty()) {
            List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
            
            List<User> userList = [ SELECT Id FROM User WHERE Id IN :userIds AND UserRoleId != null];
            
            for (User usr : userList) {
                OpportunityTeamMember member = new OpportunityTeamMember();
                member.OpportunityId = opp.Id;
                member.UserId = usr.Id;
                member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                member.TeamMemberRole = 'Sales Engineer';
                oppTeamList.add(member);
            }
            
            if (!oppTeamList.isEmpty()) {
                insert oppTeamList;
            }
        }
        
        Account acc = [ SELECT OwnerId FROM Account WHERE Id = :accId LIMIT 1]; 
        Opportunity Opportunity = [SELECT Id, CreatedById, OwnerId FROM Opportunity WHERE Id = :opp.Id LIMIT 1];  
        
        //Logic to update Opportunity Original Creator TeamMemberRole To its UserRole with Edit Access                                           
        try {
            
            if(acc.OwnerId != Opportunity.CreatedById){
                
                
                // Change Opportunity Owner  
                // Apexify -- Surya -- Ticket #51 -- commented the below update because the ownerId assignment is handled from the trigger
                // Opportunity.OwnerId = acc.OwnerId;
                // update Opportunity;
                
                System.debug('Opportunity.CreatedById------------>'+Opportunity.CreatedById);
                System.debug('Opportunity Account OwnerId---------------->'+acc.OwnerId);
                
                User creatorUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :Opportunity.CreatedById LIMIT 1];
                User accOwner = [SELECT Id, UserRole.Name FROM User WHERE Id = :acc.OwnerId LIMIT 1];
                
                System.debug('creatorUser---------------------->'+creatorUser);
                System.debug('creatorUser Role Name---------------------->'+creatorUser.UserRole.Name);
                System.debug('accOwner---------------------->'+accOwner);
                System.debug('accOwner Role Name---------------------->'+accOwner.UserRole.Name);
                
                // Check if the creator is already on the opportunity team
                List<OpportunityTeamMember> existingCreatorMember = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :Opportunity.Id  AND UserId = :Opportunity.CreatedById LIMIT 1];
                
                if (existingCreatorMember.isEmpty()) {  // Apexify -- Surya -- Ticket #51 -- modified the if condition to check isEmpty
                    System.debug('existingCreatorMember-------------->'+existingCreatorMember);
                    // Update existing member
                    // Apexify -- Surya -- Ticket #51 -- commenting below code that updates the member and added logic to inset member.
                  /*  OpportunityTeamMember member = existingCreatorMember[0];
                    member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                    member.OpportunityAccessLevel = 'Edit';
                    update member;*/
                     OpportunityTeamMember member = new OpportunityTeamMember();
                                                       member.OpportunityId = opp.Id;
                                                       member.UserId = Opportunity.CreatedById;
                                                       member.OpportunityAccessLevel = 'Edit'; // or 'Edit'
                                                       member.TeamMemberRole = (creatorUser.UserRole != null) ? creatorUser.UserRole.Name : 'Team Member';
                                                       insert member;
                    //Delete member;
                    System.debug('Original creator member after updation of member role and access------>'+member);
                }          
            }
            
        } catch (Exception e) {
            System.debug('Error adding/updating creator on team: ' + e.getMessage());
        }         
        
        
        // Step 4: Clone the Quote and return the new Quote Id
        Id cloneQuoteId = cloneQuote(quoteId,opp.Id,recordType);
        //System.debug('opp currency '+newOpp.CurrencyIsoCode);
        if(cloneQuoteId != null){
            return cloneQuoteId;
        }
        return null;
    }
    
    @AuraEnabled
    public static Id cloneQuote(Id quoteId,Id oppId,String recordType){
        
        String queryQuote = getEditableFieldsRecord('Quote')  + ' WHERE Id = :quoteId';
        String qtRecTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        Opportunity opp = [SELECT Id,CurrencyIsoCode,PriceBook2Id,Name FROM Opportunity WHERE Id=:oppId];
        Quote quote = Database.query(queryQuote);
        String supplierQuoteFiles = quote.Supplier_Quote_File__c;
        List<PriceBook2> priceBooks = [SELECT Id,Name,CurrencyIsoCode,IsStandard FROM PriceBook2 WHERE IsActive = true];
        System.debug('pricebooks '+priceBooks);
        Id stdPB;
        Id intPB;
        for(PriceBook2 pb : priceBooks){
            if(pb.IsStandard) stdPB = pb.Id;
            if(quote.CurrencyIsoCode == pb.CurrencyIsoCode && !pb.IsStandard){
                intPB = pb.Id;
                System.debug('in us');
            }
            
        }
        System.debug('stdpb '+stdPB+' intPB '+intPB);
        Quote cloneQuote = quote.clone(false,true,false,false);
        cloneQuote.Name = opp.Name;
        cloneQuote.Status = 'Draft';
        cloneQuote.OpportunityId = oppId;
        cloneQuote.Pricebook2Id = intPB;
        cloneQuote.RecordTypeId = qtRecTypeId;
        cloneQuote.Tax = 0;
        cloneQuote.BillingStreet     = null;
        cloneQuote.BillingCity       = null;
        cloneQuote.BillingState      = null;
        cloneQuote.BillingPostalCode = null;
        cloneQuote.BillingCountry    = null;
        cloneQuote.BillingLatitude   = null;
        cloneQuote.BillingLongitude  = null;
        cloneQuote.Bill_To_Company__c = null;
        cloneQuote.Bill_to_email__c = null;
        cloneQuote.Bill_to_phone__c = null;
        cloneQuote.BillingName = null;
        cloneQuote.Bill_Customer_Address_Id__c = null;
        cloneQuote.ShippingStreet     = null;
        cloneQuote.ShippingCity       = null;
        cloneQuote.ShippingState      = null;
        cloneQuote.ShippingPostalCode = null;
        cloneQuote.ShippingCountry    = null;
        cloneQuote.ShippingLatitude   = null;
        cloneQuote.ShippingLongitude  = null;
        cloneQuote.Ship_To_Company__c = null;
        cloneQuote.Ship_to_email__c= null;
        cloneQuote.Ship_to_phone__c = null;
        cloneQuote.ShippingName = null;
        cloneQuote.Ship_Customer_Address_Id__c = null;
        cloneQuote.varcpq__isApproved__c = false;
        Insert cloneQuote;
        
        System.debug('CloneQuote '+cloneQuote);
        
        //System.debug('cloneqt '+cloneQuote.Pricebook2Id);
        System.debug('opp  '+opp);
        Set<Id> qliIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Map<Id,Id> qliProdMap = new Map<Id,Id>();
        for(QuoteLineItem qli : [SELECT Id,Product2Id from QuoteLineItem WHERE QuoteId=:quoteId]){
            qliIds.add(qli.Id);
            productIds.add(qli.Product2Id);
            qliProdMap.put(qli.Id,qli.Product2Id);
        }
        
        String queryProd = getEditableFieldsRecord('Product2') + ' WHERE Id =: productIds';
        List<Product2> products = Database.query(queryprod);
        List<Product2> cloneProds = new List<Product2>();
        Map<Id,Product2> originaltoCloneMap = new Map<Id,Product2>();
        Map<Id,Id> oldNewProdMap = new Map<Id,Id>();
        for(Product2 prod : products){
            Product2 product = prod.clone(false,true,false,false);
            originaltoCloneMap.put(prod.Id,product);
            //cloneProds.add(product);
        }
        if(!originaltoCloneMap.values().isEmpty()){
            //Insert cloneProds;
            Insert originaltoCloneMap.values();
        }
        
        for(Id oldId : originaltoCloneMap.keySet()){
            oldNewProdMap.put(oldId,originaltoCloneMap.get(oldId).Id);
        }
        System.debug('oldNewProdMap '+oldNewProdMap);
        
        List<PriceBookEntry> stdpbelist = new List<PriceBookEntry>();
        List<PriceBookEntry> intpbelist = new List<PriceBookEntry>();
        for(Product2 prod : originaltoCloneMap.values()){
            // Standard Pricebook entry
            System.debug('newProd '+prod.Id);
            PriceBookEntry stdpbe = new PriceBookEntry();
            stdpbe.Pricebook2Id = stdPB;
            stdpbe.Product2Id = prod.Id;
            stdpbe.CurrencyIsoCode = Quote.CurrencyIsoCode;
            stdpbe.UnitPrice = prod.varcpq__LISTPRICE__c;
            stdpbe.IsActive = false;
            stdpbelist.add(stdpbe);
            
            // Integration Pricebook entry
            //System.debug('intpb '+intpb);
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Pricebook2Id = intPB;
            pbe.Product2Id = prod.Id;
            pbe.CurrencyIsoCode = Quote.CurrencyIsoCode;
            pbe.UnitPrice = prod.varcpq__LISTPRICE__c;
            pbe.IsActive = true;
            intpbelist.add(pbe);
            /*for(Product2 oldProd : Products){
if(oldProd.varcpq__LISTPRICE__c == prod.varcpq__LISTPRICE__c && oldProd.varcpq__PARTNUMBER__c == prod.varcpq__PARTNUMBER__c){
oldNewProdMap.put(oldProd.Id,prod.Id); // old product and new product
System.debug('oldprod '+oldProd.Id+' newprod '+prod.Id);
}
}*/
            
        }
        if(!stdpbelist.isEmpty()){
            Insert stdpbelist;
        }
        if(!intpbelist.isEmpty()){
            Insert intpbelist;
        }
        
        List<PriceBookEntry> pbes = [SELECT Id, Product2Id,PriceBook2Id FROM PricebookEntry WHERE Product2Id IN :originaltoCloneMap.values() AND Pricebook2Id = :intPB];
        
        
        Map<Id,Id> prodPbeMap = new Map<Id,Id>();
        for(PriceBookEntry pbe : pbes){
            
            System.debug('prod- '+pbe.Product2Id+' |PriceBook- '+pbe.Pricebook2Id + ' |pbe- '+ pbe.id);
            prodPbeMap.put(pbe.Product2Id,pbe.Id); //new prod vs its integretion pbe
            
        }
        System.debug('pbelist '+intpbelist);
        Map<Id,Id> oldNewGroup = new Map<Id,Id>();
        List<varcpq__DH_Quote_Group__c> quoteGroups = [SELECT Id, Name, varcpq__DH_Margin_Sub_Total__c, varcpq__DH_Sequence__c, varcpq__DH_Quote__c, varcpq__DH_Sub_Total__c 
                                                       FROM varcpq__DH_Quote_Group__c
                                                       WHERE varcpq__DH_Quote__c =:quoteId];
        List<varcpq__DH_Quote_Group__c> cloneGroups = new list<varcpq__DH_Quote_Group__c>();
        for(varcpq__DH_Quote_Group__c grp : quoteGroups){
            varcpq__DH_Quote_Group__c newGrp = new varcpq__DH_Quote_Group__c();
            newGrp.Name = grp.Name;
            newGrp.varcpq__DH_Quote__c = cloneQuote.Id;
            newGrp.varcpq__DH_Margin_Sub_Total__c = grp.varcpq__DH_Margin_Sub_Total__c;
            newGrp.varcpq__DH_Sequence__c = grp.varcpq__DH_Sequence__c;
            newGrp.varcpq__DH_Sub_Total__c = grp.varcpq__DH_Sub_Total__c;
            cloneGroups.add(newGrp);
        }
        if(!cloneGroups.isEmpty()){
            Insert cloneGroups;
        }
        for(varcpq__DH_Quote_Group__c grp : quoteGroups){
            for(varcpq__DH_Quote_Group__c newgrp : cloneGroups){
                if(grp.varcpq__DH_Sequence__c == newgrp.varcpq__DH_Sequence__c) oldNewGroup.put(grp.Id,newgrp.Id);
            }
        }      
        
        /*String queryQli = getEditableFieldsRecord('QuoteLineItem') +' WHERE Id =:qliIds';        
List<QuoteLineItem> qlis = Database.query(queryQli);*/
        List<QuoteLineItem> qlis = [SELECT Id, IsDeleted, LineNumber, QuoteId, 
                                    PricebookEntryId, Quantity, varcpq__Unit_Cost__c, Discount, 
                                    Description, ServiceDate, Product2Id, SortOrder, ListPrice, Subtotal,varcpq__Open_Market__c, 
                                    TotalPrice,  UnitPrice, varcpq__GSA__c,varcpq__GSA_Price__c,varcpq__X2GIT_Price__c,Product2.varcpq__PARTNUMBER__c,Product2.varcpq__Manufacturer__c,
                                    Product2.varcpq__LISTPRICE__c,Product2.varcpq__DH_Cost_Price__c,Product2.varcpq__DH_Sell_Price__c,
                                    varcpq__EXT_Price__c, varcpq__Margin_Dollor__c, varcpq__Total_Margin__c,varcpq__CTA_Member__c,
                                    varcpq__Margin_Percentage__c, varcpq__Percentage_Of_List_Price__c,varcpq__BLIN__c,
                                    varcpq__Product_Group__c,
                                    varcpq__DH_Quote_Group__c,varcpq__DH_Quote_Group__r.Id,varcpq__DH_Quote_Group__r.Name,
                                    varcpq__DH_Quote_Group__r.varcpq__DH_Sequence__c,varcpq__DH_Quote_Group__r.varcpq__DH_Sub_Total__c,
                                    varcpq__DH_Group_Name__c,varcpq__DH_Line__c,varcpq__DH_Quote_Group__r.varcpq__DH_Margin_Sub_Total__c
                                    /*Tax_Rate_PST__c, Tax_Rate_HST__c, Tax_Rate_QST__c, Tax_Rate_GST__c, Tax_Amount_HST__c, Tax_Amount_QST__c,varcpq__TAXABLE__c,varcpq__TAX__c,varcpq__Tax_Rate__c, 
Tax_Amount_GST__c, Tax_Amount_PST__c, Term_Start_Date__c, Term_End_Date__c,AVA_SFCLOUD__SalesTax_Line__c,
AVA_SFCLOUD__Sales_Tax_Details__c, AVA_SFCLOUD__Sales_Tax_Rate__c*/	
                                    FROM QuoteLineItem 
                                    where QuoteId = :QuoteId];
        List<QuoteLineItem> cloneQlis = new List<QuoteLineItem>();
        for(QuoteLineItem qli : qlis){
            QuoteLineItem cloneqli = qli.clone(false,true,false,false);
            cloneqli.QuoteId = cloneQuote.Id;
            cloneqli.Product2Id = oldNewProdMap.get(qli.Product2Id);
            cloneqli.varcpq__DH_Quote_Group__c = oldNewGroup.get(qli.varcpq__DH_Quote_Group__c);
            cloneqli.PricebookEntryId = prodPbeMap.get(oldNewProdMap.get(qli.Product2Id));
            System.debug('new prod '+cloneqli.Product2Id+'cloneqlipbe '+cloneqli.PricebookEntryId);
            cloneQlis.add(cloneqli);
        }
        
        // create a map of pbes for assigning to new qlis
        System.debug('cloneqlis before insert '+cloneQlis);
        if(!cloneQlis.isEmpty()){
            Insert cloneQlis;
        }
        
        // Get files (Only Supplier Quote Files)
        if(!String.isBlank(supplierQuoteFiles)){
            System.debug('supplierQuoteFiles -- '+supplierQuoteFiles);
            List<String> filesList = supplierQuoteFiles.split(';');
            if(!filesList.isEmpty()){
                List<ContentDocument> cdList = [SELECT Id,Title FROM ContentDocument WHERE Title =: filesList];
                List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
                System.debug('cdList '+cdList);
                if(!cdList.isEmpty()){
                    for(ContentDocument cd:cdList){
                        ContentDocumentLink cdLink = new ContentDocumentLink();
                        cdLink.ContentDocumentId = cd.Id;
                        cdLink.LinkedEntityId = cloneQuote.Id;
                        cdLink.ShareType = 'v';
                        cdLink.Visibility = 'AllUsers';
                        cdLinkList.add(cdLink);
                    }
                }
                If(!cdLinkList.isEmpty()){
                    Insert cdLinkList;
                }
                System.debug('cdLinkList '+cdLinkList);
            }
        }
        
        
        System.debug('cloneqlis '+cloneQlis);
        return cloneQuote.Id;
        /*catch(exception e){
System.debug('Error Message: ' + e.getMessage());
System.debug('Stack Trace: ' + e.getStackTraceString());
return null;
}*/
    }
    
    public static String getEditableFieldsRecord(String objectApiName) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        
        List<String> editableFields = new List<String>();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            
            if (fieldDescribe.isCreateable() && !fieldDescribe.isCalculated() && !fieldDescribe.isAutoNumber()) {
                //System.debug(fieldName);
                editableFields.add(fieldName);
            }
        }
        
        String query = 'SELECT Id, ' + String.join(editableFields, ',') + ' FROM ' + objectApiName;
        System.debug('Generated SOQL: ' + query);
        
        return query;
    }
    
}