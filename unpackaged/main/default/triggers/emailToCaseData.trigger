trigger emailToCaseData on EmailMessage (after insert) {
    // Collect Parent Case IDs
    Set<Id> caseIds = new Set<Id>();
    for (EmailMessage email : Trigger.new) {
        if (email.ParentId != null && String.valueOf(email.ParentId).startsWith('500')) { // '500' is the prefix for Case IDs
            caseIds.add(email.ParentId);
        }
    }

    // Proceed only if there are Cases to update
    if (!caseIds.isEmpty()) {
        // Query the Cases to update
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        for (Case c : [SELECT Id, Email_From__c, Email_To__c, Email_cc__c, Queue__c, Thread_Identifier__c, Email_Body__c
                       FROM Case
                       WHERE Id IN :caseIds]) {
            casesToUpdate.put(c.Id, c); // Populate the map
        }

        // Prepare Cases for update
        List<Case> updatedCases = new List<Case>();
        for (EmailMessage email : Trigger.new) {
            if (casesToUpdate.containsKey(email.ParentId)) {
                Case caseToUpdate = casesToUpdate.get(email.ParentId);

                // Update Thread Identifier
                caseToUpdate.Thread_Identifier__c = email.ThreadIdentifier;
                
                // Update Email From Address - trim to 255 characters
                if (!String.isBlank(email.FromAddress)) {
                    caseToUpdate.Email_From__c = email.FromAddress.length() > 255 ? 
                        email.FromAddress.substring(0, 255) : email.FromAddress;
                }
                
                // Update Email To Address - trim to 255 characters
                if (!String.isBlank(email.ToAddress)) {
                    caseToUpdate.Email_To__c = email.ToAddress.length() > 255 ? 
                        email.ToAddress.substring(0, 255) : email.ToAddress;
                }
                
                // Update Email CC Address - trim to 255 characters
                if (!String.isBlank(email.CcAddress)) {
                    caseToUpdate.Email_cc__c = email.CcAddress.length() > 255 ? 
                        email.CcAddress.substring(0, 255) : email.CcAddress;
                }
                
                // Handle Email Body - strip out embedded images and clean HTML
                String emailBody = email.HtmlBody;
                if (!String.isBlank(emailBody)) {
                    // Remove embedded images (data URIs)
                    emailBody = emailBody.replaceAll('<img[^>]*src="data:image/[^"]*"[^>]*>', '');
                    
                    // Alternative: If you want to keep img tags but remove data URIs
                    // emailBody = emailBody.replaceAll('src="data:image/[^"]*"', 'src=""');
                    
                    // Truncate if too long (adjust size based on your field limit)
                    Integer maxLength = 32768; // Common limit for Long Text Area fields
                    if (emailBody.length() > maxLength) {
                        emailBody = emailBody.substring(0, maxLength);
                    }
                    
                    caseToUpdate.Email_Body__c = emailBody;
                } else if (!String.isBlank(email.TextBody)) {
                    // Fallback to plain text if HTML is blank
                    String textBody = email.TextBody;
                    Integer maxLength = 32768;
                    if (textBody.length() > maxLength) {
                        textBody = textBody.substring(0, maxLength);
                    }
                    caseToUpdate.Email_Body__c = textBody;
                }

                // Determine the Queue based on email addresses
                Set<String> toCcAddresses = new Set<String>();
                if (!String.isEmpty(email.ToAddress)) {
                    toCcAddresses.addAll(email.ToAddress.split(';'));
                }
                if (!String.isEmpty(email.CcAddress)) {
                    toCcAddresses.addAll(email.CcAddress.split(';'));
                }
                if (!String.isEmpty(email.FromAddress)) {
                    toCcAddresses.addAll(email.FromAddress.split(';'));
                }

                Set<String> matchedQueues = new Set<String>();
                for (String address : toCcAddresses) {
                    address = address.toLowerCase().trim(); // Normalize for case-insensitivity and trim whitespace
                    if (address.contains('operationsca@clutchsolutions.com') || address.contains('operationscanada@clutchsolutions.com')) {
                        matchedQueues.add('Operations CA');
                    } else if (address.contains('operationsus@clutchsolutions.com') || address.contains('operations@clutchsolutions.com')) {
                        matchedQueues.add('Operations US');
                    } else if (address.contains('invoicesca@clutchsolutions.com')|| address.contains('invoicescanada@clutchsolutions.com')) {
                        matchedQueues.add('Invoices CA');
                    } else if (address.contains('invoicesus@clutchsolutions.com')|| address.contains('invoices@clutchsolutions.com')) {
                        matchedQueues.add('Invoices US');
                    } else if (address.contains('accountingca@clutchsolutions.com') || address.contains('accountingcanada@clutchsolutions.com')) {
                        matchedQueues.add('Accounting CA');
                    } else if (address.contains('accountingus@clutchsolutions.com') || address.contains('accounting@clutchsolutions.com')) {
                        matchedQueues.add('Accounting US');
                    }
                    System.debug('FromAddress before processing: ' + email.FromAddress);
                    System.debug('Address being checked: ' + address);
                }

                if (matchedQueues.isEmpty()) {
                    caseToUpdate.Queue__c = 'Unknown';
                } else if (matchedQueues.size() > 1) {
                    caseToUpdate.Queue__c = 'Multiple';
                } else {
                    caseToUpdate.Queue__c = matchedQueues.iterator().next();
                }

                // Add to the list for update
                updatedCases.add(caseToUpdate);
            }
        }

        // Update Cases with error handling
        if (!updatedCases.isEmpty()) {
            try {
                update updatedCases;
            } catch (DmlException e) {
                // Log the error for debugging
                System.debug('Error updating cases: ' + e.getMessage());
                System.debug('Failed record IDs: ' + e.getDmlId(0));
                
                // Optional: Send email to admin or create a custom error log record
                // You could also implement partial success handling here
                throw e; // Re-throw if you want the email creation to fail
            }
        }
    }
}