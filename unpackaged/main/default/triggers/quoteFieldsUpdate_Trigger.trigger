trigger quoteFieldsUpdate_Trigger on Quote (before insert) {
    if(Trigger.isInsert && Trigger.isbefore){
        System.debug('Trigger.new '+Trigger.new);
        quoteFieldsUpdate.getBillShipDefault(Trigger.new);
    }
}