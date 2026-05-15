trigger DiabetesCareObservationTrigger on CareObservation (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        DiabetesCareObservationTriggerHandler.handleAfterInsert(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        DiabetesCareObservationTriggerHandler.handleAfterUpdate(Trigger.new);
    }
}