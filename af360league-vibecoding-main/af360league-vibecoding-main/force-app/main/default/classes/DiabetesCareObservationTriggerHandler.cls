public class DiabetesCareObservationTriggerHandler {
    
    public static void handleAfterInsert(List<CareObservation> newObservations) {
        processObservations(newObservations);
    }
    
    public static void handleAfterUpdate(List<CareObservation> newObservations) {
        processObservations(newObservations);
    }
    
    private static void processObservations(List<CareObservation> newObservations) {
        // Return early on no records
        if (newObservations == null || newObservations.isEmpty()) {
            return;
        }
        
        // Get thresholds from Custom Metadata (cached automatically). Return early if not configured.
        Diabetes_Threshold__mdt thresholds = [
            SELECT Target_Percentage__c, Warning_Percentage__c, Critical_Percentage__c
            FROM Diabetes_Threshold__mdt
            WHERE DeveloperName = 'Standard_Diabetes_Thresholds'
            LIMIT 1
        ];
        if (thresholds == null) {
            return;
        }

        Set<Id> codeIds = new Set<Id>();
        Set<Id> candidateObservationIds = new Set<Id>();
        Map<Id, Decimal> observationHbA1cMap = new Map<Id, Decimal>();

        // First pass: collect Code IDs to query
        for (CareObservation obs : newObservations) {
            if (obs != null && obs.CodeId != null) {
                codeIds.add(obs.CodeId);
            }
        }

        // Query CodeSet records to get code names
        Map<Id, CodeSet> codeMap = codeIds.isEmpty()
            ? new Map<Id, CodeSet>()
            : new Map<Id, CodeSet>([
                SELECT Id, Name FROM CodeSet WHERE Id IN :codeIds
            ]);

        // Second pass: collect observation IDs and HbA1c values for bulk processing
        for (CareObservation obs : newObservations) {
            if (obs == null) continue;
            CodeSet code = (obs.CodeId != null) ? codeMap.get(obs.CodeId) : null;
            String codeName = (code != null) ? code.Name : null;

            // Only process finalized HbA1c observations with valid data
            if (codeName == 'HbA1c' &&
                obs.ObservationStatus == 'final' &&
                obs.ObservedValueType == 'Quantity' &&
                obs.ObservedValueNumerator != null &&
                obs.ObservedValueNumerator >= thresholds.Warning_Percentage__c && // Dynamic threshold!
                obs.ObservedSubjectId != null &&
                obs.Id != null) {

                candidateObservationIds.add(obs.Id);
                observationHbA1cMap.put(obs.Id, obs.ObservedValueNumerator);
            }
        }

        if (candidateObservationIds.isEmpty()) {
            return;
        }

        // Bulk query existing open follow-up tasks for these observations (30 days window)
        Map<Id, Boolean> observationHasOpenTask = new Map<Id, Boolean>();
        for (Task t : [
            SELECT Id, WhatId
            FROM Task
            WHERE WhatId IN :candidateObservationIds
              AND Subject LIKE '%HbA1c Follow-up%'
              AND Status != 'Completed'
              AND CreatedDate = LAST_N_DAYS:30
        ]) {
            if (t.WhatId != null) {
                observationHasOpenTask.put(t.WhatId, true);
            }
        }

        // Build tasks to insert (bulk DML)
        List<Task> tasksToInsert = new List<Task>();
        Date today = Date.today();

        for (Id observationId : candidateObservationIds) {
            if (observationHasOpenTask.containsKey(observationId)) {
                continue; // Skip if existing open follow-up found
            }

            Decimal hba1cValue = observationHbA1cMap.get(observationId);

            Task followUpTask = new Task();
            followUpTask.Subject = 'HbA1c Follow-up Required - ' + today.format();
            followUpTask.WhatId = observationId; // Task linked to CareObservation record

            // ActivityDate required: set by severity
            if (hba1cValue != null && hba1cValue >= thresholds.Critical_Percentage__c) {
                followUpTask.ActivityDate = today.addDays(1);
                followUpTask.Priority = 'High';
            } else if (hba1cValue != null && hba1cValue >= thresholds.Warning_Percentage__c) {
                followUpTask.ActivityDate = today.addDays(7);
                followUpTask.Priority = 'Normal';
            } else {
                followUpTask.ActivityDate = today.addDays(14);
                followUpTask.Priority = 'Low';
            }

            followUpTask.Status = 'Not Started';
            followUpTask.Type = 'Call';

            // Safe string building with null checks
            String valueText = (hba1cValue == null) ? 'N/A' : String.valueOf(hba1cValue);
            followUpTask.Description = 'Patient has new HbA1c level of ' +
                                       valueText + '%. Schedule follow-up appointment to review ' +
                                       'diabetes management plan and medication adherence. ' +
                                       'Thresholds: Target <' + String.valueOf(thresholds.Target_Percentage__c) +
                                       '%, Warning ≥' + String.valueOf(thresholds.Warning_Percentage__c) +
                                       '%, Critical ≥' + String.valueOf(thresholds.Critical_Percentage__c) + '%.';

            tasksToInsert.add(followUpTask);
        }

        if (!tasksToInsert.isEmpty()) {
            // Single DML, partial success allowed
            Database.insert(tasksToInsert, false);
        }
    }
}
