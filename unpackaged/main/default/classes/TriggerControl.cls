public class TriggerControl {
    private static Map<String, Boolean> triggerStatusMap;

    public static Boolean isActive(String triggerName) {
        if(triggerStatusMap == null) {
            triggerStatusMap = new Map<String, Boolean>();
            for (TriggerActivation__mdt t : [
                SELECT DeveloperName, IsActive__c
                FROM TriggerActivation__mdt
            ]) {
                triggerStatusMap.put(t.DeveloperName.toLowerCase(), t.IsActive__c);
            }
        }
        return triggerStatusMap.get(triggerName.toLowerCase()) == true;
    }
}