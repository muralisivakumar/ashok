trigger AVASFDC_QuoteLineItemTaxTrigger on QuoteLineItem (before insert, before update) {
 
    if (Trigger.isInsert || Trigger.isUpdate) {
    System.debug('---Trigger Start---');

    // STEP 1: Collect Part Numbers and Quote Ids only
    Set<String> partNumbers = new Set<String>();
    Set<Id> quoteIds = new Set<Id>();

    for (QuoteLineItem qli : Trigger.new) {
        if (qli.varcpq__PartNumber__c != null) partNumbers.add(qli.varcpq__PartNumber__c);
        if (qli.QuoteId != null) quoteIds.add(qli.QuoteId);
    }

    if (partNumbers.isEmpty() || quoteIds.isEmpty()) return;

    // STEP 2: Supporting Quotes of Record Type = Part
    List<varcpq__DH_Supporting_Quote__c> partSupQuotes = [
        SELECT Id, varcpq__DH_Part_No__c, varcpq__DH_Supporting_File_Quote__c
        FROM varcpq__DH_Supporting_Quote__c
        WHERE RecordType.Name = 'Part'
        AND varcpq__DH_Part_No__c IN :partNumbers
    ];

    // Map: Part Number → Parent Supporting Quote Id
    Map<String, Id> partToParentQuoteId = new Map<String, Id>();
    for (varcpq__DH_Supporting_Quote__c psq : partSupQuotes) {
        if (psq.varcpq__DH_Part_No__c != null && psq.varcpq__DH_Supporting_File_Quote__c != null)
            partToParentQuoteId.put(psq.varcpq__DH_Part_No__c, psq.varcpq__DH_Supporting_File_Quote__c);
    }
		/* commented by apexify: shankar: To fix the description being empty on product creation for manually created quotes and QLI
		  								  that doesn't have a supporting quote record
        if (partToParentQuoteId.isEmpty())
        return; 
       */

    // STEP 3: Query the Quote Record type supporting quotes
    Set<Id> parentQuoteIds = new Set<Id>(partToParentQuoteId.values());

    List<varcpq__DH_Supporting_Quote__c> quoteSupQuotes = [
        SELECT Id, varcpq__DH_Quote_No__c
        FROM varcpq__DH_Supporting_Quote__c
        WHERE RecordType.Name = 'Quote Record'
        AND Id IN :parentQuoteIds
    ];

    // Map: Supporting Quote Id → Supplier Quote No
    Map<Id, String> parentQuoteIdToQuoteNo = new Map<Id, String>();
    for (varcpq__DH_Supporting_Quote__c qs : quoteSupQuotes) {
        if (qs.varcpq__DH_Quote_No__c != null)
            parentQuoteIdToQuoteNo.put(qs.Id, qs.varcpq__DH_Quote_No__c);
    }

    // STEP 4: Build map of QuoteId → Supplier_Quote_Number__c
    Map<Id, String> quoteIdToSupplierQuoteNo = new Map<Id, String>();

    for (QuoteLineItem qli : Trigger.new) {
        if (qli.varcpq__PartNumber__c != null &&
            partToParentQuoteId.containsKey(qli.varcpq__PartNumber__c)) {

            Id parentSupportingQuoteId = partToParentQuoteId.get(qli.varcpq__PartNumber__c);

            if (parentQuoteIdToQuoteNo.containsKey(parentSupportingQuoteId)) {
                quoteIdToSupplierQuoteNo.put(
                    qli.QuoteId,
                    parentQuoteIdToQuoteNo.get(parentSupportingQuoteId)
                );
            }
        }
    }

    // STEP 5: Update only the Quote (NOT Quote Line Item)
    if (!quoteIdToSupplierQuoteNo.isEmpty()) {

        List<Quote> quotesToUpdate = [
            SELECT Id, Supplier_Quote_Number__c
            FROM Quote
            WHERE Id IN :quoteIdToSupplierQuoteNo.keySet()
        ];

        for (Quote q : quotesToUpdate) {
            if (q.Supplier_Quote_Number__c == null) {     // only update if empty
                q.Supplier_Quote_Number__c = quoteIdToSupplierQuoteNo.get(q.Id);
            }
        }

        update quotesToUpdate;
    }



  // Step 0: Truncate Description to 255 characters
        for (QuoteLineItem qli : Trigger.new) {
            if (qli.Description != null && qli.Description.length() > 255) {
                qli.Description = qli.Description.substring(0, 255);
            }
        }

        // Step 1: Tax logic
        TaxDetailsHandler.processTaxDetails(Trigger.new);

        Set<Id> productIdsToQuery = new Set<Id>();
        Set<Id> productIdsToUpdate = new Set<Id>();
        Map<Id, String> newDescriptionsFromQLI = new Map<Id, String>();

        for (QuoteLineItem qli : Trigger.new) {
            // When Description__c is empty and Description is long enough, get Product2.Description
            if (qli.Description != null && qli.Description.length() > 80 && String.isEmpty(qli.Description__c)) {
                productIdsToQuery.add(qli.Product2Id);
            }

            // When Description__c changes, update Product2.Description
            if (Trigger.isUpdate && qli.Product2Id != null) {
                QuoteLineItem oldQLI = Trigger.oldMap.get(qli.Id);
                if (oldQLI.Description__c != qli.Description__c && !String.isEmpty(qli.Description__c)) {
                    productIdsToUpdate.add(qli.Product2Id);
                    newDescriptionsFromQLI.put(qli.Product2Id, qli.Description__c);
                }
            }
        }

        // Step 2: Update Product2.Description based on Description__c
        List<Product2> productsToUpdate = new List<Product2>();
        if (!productIdsToUpdate.isEmpty()) {
            Map<Id, Product2> products = new Map<Id, Product2>(
                [SELECT Id, Description FROM Product2 WHERE Id IN :productIdsToUpdate]
            );

            for (Id prodId : productIdsToUpdate) {
                String newDesc = newDescriptionsFromQLI.get(prodId);
                if (products.containsKey(prodId) && newDesc != null && products.get(prodId).Description != newDesc) {
                    products.get(prodId).Description = newDesc;
                    productsToUpdate.add(products.get(prodId));
                }
            }

            if (!productsToUpdate.isEmpty()) {
                update productsToUpdate;
            }
        }

        // Step 3: Re-query Product2 to get updated descriptions
        Set<Id> allProductIds = new Set<Id>();
        allProductIds.addAll(productIdsToQuery);
        allProductIds.addAll(productIdsToUpdate);

        Map<Id, Product2> refreshedProducts = new Map<Id, Product2>();
        if (!allProductIds.isEmpty()) {
            refreshedProducts = new Map<Id, Product2>(
                [SELECT Id, Description FROM Product2 WHERE Id IN :allProductIds]
            );
        }

        // Step 4: Populate Description__c either from Description or Product2 if needed
        for (QuoteLineItem qli : Trigger.new) {
            // New logic to handle when Description is null
            if (String.isEmpty(qli.Description__c)) {
                if (qli.Description != null && qli.Description.length() > 0) {
                    // Copy Description to Description__c if Description__c is empty
                    qli.Description__c = qli.Description;
                } else if ((qli.Description == null || qli.Description.length() == 0) && qli.Product2Id != null) {
                    // If Description is null or empty, fallback to Product2.Description if exists
                    Product2 relatedProduct = refreshedProducts.get(qli.Product2Id);
                    if (relatedProduct != null && relatedProduct.Description != null) {
                        qli.Description__c = relatedProduct.Description;
                    }
                }
            }
        }

        // Step 5: Set QuoteLineItem.Description from Product2.Description (truncate if needed)
        for (QuoteLineItem qli : Trigger.new) {
            if (qli.Product2Id != null && refreshedProducts.containsKey(qli.Product2Id)) {
                String prodDesc = refreshedProducts.get(qli.Product2Id).Description;
                if (prodDesc != null) {
                    qli.Description = prodDesc.length() > 255 ? prodDesc.substring(0, 255) : prodDesc;
                }
            }
        }
    }
}