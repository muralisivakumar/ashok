@isTest
public class TiggerExecutionContextTest {
	@isTest
    static void contextTest(){
        TriggerExecutionContext.getIsRunningFromPOConfirmation();
        TriggerExecutionContext.setIsRunningFromPOConfirmation(true);
    }
}