public class fileUploadManualCreditMemo {
     @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFileCategoryOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.file_category__c.getDescribe();
        options.add(new Map<String,String>{
            'label'=>'Select one Category...', 'value'=>''
        });
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            options.add(new Map<String, String>{
                'label' => entry.getLabel(),
                    'value' => entry.getValue()
                    });
        }
        return options;
    }
    
   
    public static List<ContentDocument> getContentDocs(List<Id> docIds) {
        List<ContentDocument> newDocs = new List<ContentDocument>();
        System.debug('docIds '+docIds);
        for (ContentDocument cd : [
            SELECT Id, LatestPublishedVersionId, Title
            FROM ContentDocument
            WHERE Id IN :docIds AND FileType != 'SNOTE'
        ]) {
            newDocs.add(cd);
        }
        if(!newDocs.isEmpty()){
        	return newDocs;
        }
        return null;
    }
    @AuraEnabled
    public static list<fileWrapper> getFileWrapper(List<Id> docIds){
        list<ContentDocument> docs = getContentDocs(docIds);
        if(docs != null){
            list<fileWrapper> fileWraps = new list<fileWrapper>();
            for(ContentDocument doc: docs){
                fileWrapper filewrap = new fileWrapper();
                filewrap.contentDocId = doc.Id;
                filewrap.contentVerId = doc.LatestPublishedVersionId;
                filewrap.fileName = doc.Title;
                filewrap.fileCategory = '';
                fileWraps.add(filewrap);
            }
            if(!fileWraps.isEmpty()){
                return fileWraps;
            }
        }
        return null;
        
    }
    /*@AuraEnabled
public static String updateFileCategory(String fileWrapString) {
    List<fileWrapper> fileWraps = (List<fileWrapper>) JSON.deserialize(fileWrapString, List<fileWrapper>.class);

    List<ContentVersion> cvs = new List<ContentVersion>();

    List<File_Category_Configuration__mdt> fileCategoryConfig =
        [SELECT Id, Label, File_Prefix__c FROM File_Category_Configuration__mdt];

    Map<String, String> fccMap = new Map<String, String>();
    for (File_Category_Configuration__mdt fcc : fileCategoryConfig) {
        fccMap.put(fcc.Label, fcc.File_Prefix__c);
    }

    for (fileWrapper fw : fileWraps) {
        ContentVersion cv = new ContentVersion(
            Id = fw.contentVerId,
            File_Category__c = fw.fileCategory
        );

        if (fccMap.containsKey(cv.File_Category__c) && String.isNotBlank(fccMap.get(cv.File_Category__c))) {
            cv.Title = fccMap.get(cv.File_Category__c) + '_' + fw.fileName;
        }

        cvs.add(cv);
    }

    if (!cvs.isEmpty()) {
        update cvs;
    }

    return 'Updated ' + cvs.size() + ' file(s) successfully';
}*/
   @AuraEnabled
    public static void updateFileCategory(String fileWrapString) {
        List<fileWrapper> fileWraps = (List<fileWrapper>)JSON.deserialize(fileWrapString, list<fileWrapper>.class);
        System.debug('fileWraps '+fileWraps);
        List<ContentVersion> cvs = new List<ContentVersion>();
        List<ContentDocument> supplierQuotecds = new list<ContentDocument>();
        List<File_Category_Configuration__mdt> fileCategoryConfig = [SELECT Id, Label, File_Prefix__c FROM File_Category_Configuration__mdt];
        System.debug('fileCategoryConfig: ' + fileCategoryConfig);
        Map<String,String> fccMap = new Map<String,String>();
        for(File_Category_Configuration__mdt fcc: fileCategoryConfig){
            if(!fccMap.containsKey(fcc.Label)){
                fccMap.put(fcc.Label,fcc.File_Prefix__c);
            }
        }
        for(fileWrapper fw:fileWraps){
        	ContentVersion cv = new ContentVersion();
            cv.Id = fw.contentVerId;
            cv.File_Category__c = fw.fileCategory;
            cvs.add(cv);
            if(fccMap.containskey(cv.File_Category__c) && (fccMap.get(cv.File_Category__c)!=null)){
                System.debug('fccMap.get(cv.File_Category__c) '+fccMap.get(cv.File_Category__c));
                ContentDocument cd = new ContentDocument();
                cd.Id = fw.contentDocId;
                //cd.Title = 'ClutchSupplierQuote_'+fw.fileName;
                cd.Title = fccMap.get(cv.File_Category__c)+'_'+fw.fileName;             
                supplierQuotecds.add(cd);
            }
        }
        
        if(!cvs.isEmpty()){
        	update cvs;
        }
        if(!supplierQuotecds.isEmpty()){
            System.debug('supplierQuotecds '+supplierQuotecds);
            update supplierQuotecds;
        }
        
    }
    
    public class fileWrapper{
        @AuraEnabled
        public String contentDocId{get;set;}
        @AuraEnabled
        public String contentVerId{get;set;}
        @AuraEnabled
        public String fileName{get;set;}
        @AuraEnabled
        public String fileCategory{get;set;}
        
    }
}