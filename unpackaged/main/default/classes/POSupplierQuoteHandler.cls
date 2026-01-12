public class POSupplierQuoteHandler{ 
    
    public static void fileHandler(List<varcpq__Purchase_Order__c> PONewList){
        Supplier_Quote_Naming__c supplierQTName = Supplier_Quote_Naming__c.getOrgDefaults();
        String prefix = supplierQTName.Naming_Convention__c;
        
        SET<ID>SoSet = new SET<Id>();
        for(varcpq__Purchase_Order__c objPO : PONewList){
            SoSet.add(objPO.varcpq__Sales_Order__c);
            
        }
		Map<Id,String> soQtNumMap = new Map<Id,String>();        
        List<varcpq__Sales_Order__c>SoDBList = [SELECT Id,Quote__c,Quote__r.Supplier_Quote_File__c,Quote__r.QuoteNumber FROM varcpq__Sales_Order__c 
                                                Where ID IN : SoSet ];
        
        Map<Id,List<String>> supplierFileMap = new Map<Id,List<String>>();
        List<String>valuesOfSplitedStringsList =new List<String>();
        for(varcpq__Sales_Order__c objSO :SoDBList ){
            if(!String.isBlank(objSO.Quote__r.Supplier_Quote_File__c)){
                supplierFileMap.put(objSO.Id,objSO.Quote__r.Supplier_Quote_File__c.split(';'));
                valuesOfSplitedStringsList = objSO.Quote__r.Supplier_Quote_File__c.split(';');
                soQtNumMap.put(objSO.Id,objSO.Quote__r.QuoteNumber);
                System.debug('valuesOfSplitedStringsList---->'+valuesOfSplitedStringsList);    
                System.debug('supplierFileMap--->'+supplierFileMap);    
            }
        }
        
        List<String> splitValuesList = new List<String>();
        for(Id soId :supplierFileMap.keyset()){
            for(String fileName: supplierFileMap.get(soId)){
                System.debug('FILENAMEEEE'+fileName);
                splitValuesList.add(fileName);              
            }  
            System.debug(splitValuesList);
        }
        
        
        List<ContentDocumentLink> cdlinkList=[SELECT Id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                              Where LinkedEntityId IN : SoSet AND ContentDocument.Title IN : valuesOfSplitedStringsList];
        System.debug('cdlinkList---->'+cdlinkList);
        
        Map<Id,List<Id>> soIdVsListConDocIdMap = new Map<Id,List<Id>>();       
        Map<Id,Id>conDocIdVSSOId = NEW  Map<Id,Id>();  
        
        set<Id>contentDocIdSET = new SET<Id>();
        for(ContentDocumentLink objLink : cdlinkList){
            contentDocIdSET.add(objLink.ContentDocumentId);           
            soIdVsListConDocIdMap.put(objLink.LinkedEntityId,new List<Id>{objLink.ContentDocumentId});  
            conDocIdVSSOId.Put(objLink.ContentDocumentId,objLink.LinkedEntityId);
        }
        
        List<contentVersion>contentverList = [SELECT Id,ContentDocumentId,VersionNumber,ContentLocation,PathOnClient, Title,SharingOption,
                                              SharingPrivacy,VersionData,FileType,FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocIdSET];
        System.debug('contentverList-->'+contentverList);
        
        List<ContentVersion> newConVerList = new List<ContentVersion>(); 
        Map<Id,List<contentVersion>> soIdVsListVersionMap = new Map<Id,List<contentVersion>>();
        
        if(!contentverList.isEmpty()){   
            for(contentVersion objVer : contentverList ){
            	soIdVsListVersionMap.Put(conDocIdVSSOId.get(objVer.ContentDocumentId),new List<contentVersion>());
            }
            Integer step = 1;
            for(contentVersion objVer : contentverList ){            
                if(conDocIdVSSOId.containsKey(objVer.ContentDocumentId)){
                    String quoteNum = soQtNumMap.get(conDocIdVSSOId.get(objVer.ContentDocumentId));
                    contentVersion newcv = new contentVersion();
                    newcv.ContentLocation = objVer.ContentLocation;
                    newcv.VersionData = objVer.versiondata;
                    newcv.PathOnClient = prefix+quoteNum+'_f'+step+'.'+objVer.FileExtension;
                    newcv.Title = prefix+quoteNum+'_f'+step+'.'+objVer.FileExtension;              
                    newConVerList.add(newcv);
                    //soIdVsListVersionMap.Put(conDocIdVSSOId.get(objVer.ContentDocumentId),new List<contentVersion>{newcv});
                    //System.debug('soIdVsListVersionMap---->'+soIdVsListVersionMap);
                    if(soIdVsListVersionMap.containskey(conDocIdVSSOId.get(objVer.ContentDocumentId))){
                        soIdVsListVersionMap.get(conDocIdVSSOId.get(objVer.ContentDocumentId)).add(newcv);
                    }
                    step++;
                    System.debug('newConVerList------->'+newConVerList);
                }
            }
        }
        System.debug('soIdVsListVersionMap ---->'+soIdVsListVersionMap);
        if(!newConVerList.isEmpty()){
            INSERT newConVerList;
            System.debug('newConVerList-->'+newConVerList);
        }
        
        List<contentversion> newVersionList = [SELECT ID,ContentDocumentId FROM  contentversion WHERE ID IN:newConVerList];
        System.debug('newVersionList---++>'+newVersionList);
        Map<ID,ID> conVerIdVDconDocIdMap = new Map<ID,ID>();
        for( contentversion objNewVersion : newVersionList){
            conVerIdVDconDocIdMap.Put(objNewVersion.Id,objNewVersion.ContentDocumentId);
        }
        
        List<ContentDocumentLink> doclinkListToInsert = new List<ContentDocumentLink>();
        for(varcpq__Purchase_Order__c objPO : PONewList){                      
            if(soIdVsListVersionMap.containsKey(objPO.varcpq__Sales_Order__c)){
                List<contentVersion> conList = soIdVsListVersionMap.get(objPO.varcpq__Sales_Order__c);
                System.debug('conList---->'+conList);
                for(contentVersion objCon : conList){
                    if(conVerIdVDconDocIdMap.containsKey(objCon.Id)){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = conVerIdVDconDocIdMap.get(objCon.Id);
                        cdl.LinkedEntityId = objPO.Id;
                        cdl.ShareType = 'v';
                        doclinkListToInsert.add(cdl);
                    }
                }
            }            
        } 
        if (!doclinkListToInsert.isEmpty()) {
            System.debug('doclinkListToInsertSIZE'+doclinkListToInsert.size());
            System.debug('doclinkListToInsert'+doclinkListToInsert);
            insert doclinkListToInsert;
        }
        
    }
}