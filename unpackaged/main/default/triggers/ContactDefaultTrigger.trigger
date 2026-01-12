trigger ContactDefaultTrigger on Contact (after insert, after update) {    
    new ContactDefaultHandler().handleDefaultContacts(Trigger.new, Trigger.oldMap);
}