trigger QuoteCountryFieldUpdateTRigger on Quote (before insert) {
    QuoteCountryFieldUpdateHandler.updateCountryHandler(trigger.new);   
}