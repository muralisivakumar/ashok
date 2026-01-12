global class ReassignSFObjectsSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ReassignSFObjectsBatch batch = new ReassignSFObjectsBatch();
        Database.executeBatch(batch, 200); // 200 is the batch size
    }
}