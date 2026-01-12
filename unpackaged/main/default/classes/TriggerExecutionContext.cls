public class TriggerExecutionContext {
  private static Boolean isRunningFromPOConfirmation = false;

  public static Boolean getIsRunningFromPOConfirmation() {
    return isRunningFromPOConfirmation;
  }

  public static void setIsRunningFromPOConfirmation(Boolean value) {
    isRunningFromPOConfirmation = value;
  }
}