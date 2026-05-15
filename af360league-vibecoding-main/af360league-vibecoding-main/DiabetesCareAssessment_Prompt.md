# Prompt: Create DiabetesCareAssessment Apex Class

## Overview
Create a Salesforce Apex class named `DiabetesCareAssessment` that assesses diabetes care for patients based on their latest HbA1c (glycated hemoglobin) laboratory values and their enrollment status in diabetes care programs. This class is designed to be invocable from Flow, Process Builder, or other automation tools, making it suitable for automated patient assessment workflows.

## Class Structure

### Class Declaration
- **Class Name**: `DiabetesCareAssessment`
- **Access Modifier**: `public with sharing`
- **Purpose**: Apex class for assessing diabetes care based on HbA1c values and program enrollment

### Inner Wrapper Classes

#### 1. AssessmentRequest Class
A public inner class that serves as the input wrapper for the invocable method:
- **Access Modifier**: `public`
- **Properties** (all marked with `@InvocableVariable`):
  - `patientId` (Id): The Salesforce ID of the patient/account to assess
  - `daysLookback` (Integer): Number of days to look back for observations (note: currently not used in implementation but included in the structure)
- **Constructors**:
  - Default no-argument constructor
  - Parameterized constructor accepting `patientId` and `daysLookback`

#### 2. AssessmentResult Class
A public inner class that serves as the output wrapper for the invocable method:
- **Access Modifier**: `public`
- **Properties** (all marked with `@InvocableVariable`):
  - `patientId` (Id): The Salesforce ID of the patient that was assessed
  - `hba1cValue` (Decimal): The latest HbA1c value found for the patient (can be null if no observation found)
  - `riskCategory` (String): Categorized risk level based on HbA1c value (see risk categorization logic below)
  - `isInDiabetesProgram` (Boolean): Indicates whether the patient is enrolled in an active Diabetes care program
  - `errorMessage` (String): Contains error message if processing failed for this patient (null if successful)
- **Constructors**:
  - Default no-argument constructor
  - Parameterized constructor accepting `patientId`

## Main Method: assessPatient

### Method Signature
```apex
@InvocableMethod(label='Assess Patient' description='Assesses patient diabetes care based on HbA1c values and program enrollment')
public static List<AssessmentResult> assessPatient(List<AssessmentRequest> requests)
```

### Method Behavior

1. **Input Validation**:
   - If `requests` is null or empty, return an empty list immediately

2. **Patient ID Extraction**:
   - Extract all non-null `patientId` values from the requests
   - Create a `Set<Id>` of patient IDs for efficient querying
   - Create a `Map<Id, AssessmentRequest>` to map patient IDs back to their original request objects

3. **HbA1c CodeSet Lookup**:
   - Call private helper method `getHbA1cCodeSetId()` to find the CodeSet record with Name = 'HbA1c'
   - If no HbA1c CodeSet is found, create error results for all patients with error message "HbA1c CodeSet not found in the system" and return early

4. **Data Retrieval**:
   - Call `getLatestHbA1cObservations()` to retrieve the most recent HbA1c observation for each patient
   - Call `checkActiveDiabetesPrograms()` to determine which patients are enrolled in active Diabetes programs

5. **Result Processing**:
   - For each patient ID:
     - Create a new `AssessmentResult` with the patient ID
     - Wrap processing in a try-catch block for error handling
     - Retrieve the latest HbA1c observation from the map
     - If observation exists and has a valid `ObservedValueNumerator`:
       - Set `hba1cValue` to the observation's `ObservedValueNumerator`
       - Categorize risk based on HbA1c value:
         - If `hba1cValue < 7.0`: Set `riskCategory = 'Well Controlled'`
         - If `hba1cValue >= 7.0 AND hba1cValue < 9.0`: Set `riskCategory = 'Needs Attention'`
         - If `hba1cValue >= 9.0`: Set `riskCategory = 'High Risk/Urgent'`
     - If no observation or no value found: Set `riskCategory = 'No Data Available'`
     - Set `isInDiabetesProgram` from the program enrollment map (default to false if not found)
     - Add result to results list
     - If exception occurs: Set `errorMessage` to "Error processing patient {patientId}: {exception message}" and add result

6. **Return**: List of `AssessmentResult` objects, one per patient

## Helper Methods

### 1. getHbA1cCodeSetId()
- **Access Modifier**: `private static`
- **Return Type**: `Id` (can be null)
- **Purpose**: Retrieves the Salesforce ID of the CodeSet record named 'HbA1c'
- **Implementation**:
  - Query: `SELECT Id FROM CodeSet WHERE Name = 'HbA1c' LIMIT 1`
  - Return the first record's Id if found, otherwise return null

### 2. getLatestHbA1cObservations(Set<Id> patientIds, Id hba1cCodeSetId)
- **Access Modifier**: `private static`
- **Return Type**: `Map<Id, CareObservation>`
- **Parameters**:
  - `patientIds`: Set of patient/account IDs to query
  - `hba1cCodeSetId`: The ID of the HbA1c CodeSet
- **Purpose**: Retrieves the most recent HbA1c observation for each patient
- **Implementation Details**:
  - Early return empty map if `patientIds` is empty or `hba1cCodeSetId` is null
  - Query CareObservation records with:
    - Fields: `Id, ObservedSubjectId, ObservedValueNumerator, EffectiveDateTime`
    - WHERE conditions:
      - `CodeId = :hba1cCodeSetId` (matches HbA1c CodeSet)
      - `ObservedSubjectId IN :patientIds` (matches requested patients)
      - `ObservationStatus = 'Final'` (only finalized observations)
      - `ObservedValueType = 'Quantity'` (numeric value type)
      - `ObservedValueNumerator != null` (has a numeric value)
    - ORDER BY: `EffectiveDateTime DESC NULLS LAST` (most recent first)
    - LIMIT: 1000
  - Iterate through results and create a map with one observation per patient (the first one encountered for each patient, which will be the latest due to ordering)
  - Return the map

### 3. checkActiveDiabetesPrograms(Set<Id> patientIds)
- **Access Modifier**: `private static`
- **Return Type**: `Map<Id, Boolean>`
- **Parameters**:
  - `patientIds`: Set of patient/account IDs to check
- **Purpose**: Determines which patients are enrolled in active Diabetes care programs
- **Implementation Details**:
  - Early return empty map if `patientIds` is empty
  - Initialize a map with all patient IDs set to `false` (not enrolled)
  - Query CareProgramEnrollee records with:
    - Fields: `Id, CareProgramId, AccountId, Status`
    - WHERE conditions:
      - `AccountId IN :patientIds` (matches requested patients)
      - `Status = 'Active'` (only active enrollments)
      - `CareProgramId IN (SELECT Id FROM CareProgram WHERE Name LIKE '%Diabetes%')` (subquery to find Diabetes programs)
  - For each enrollee found, set the corresponding patient ID in the map to `true`
  - Return the map

## Risk Categorization Logic

The class categorizes patients into risk categories based on their HbA1c values:
- **Well Controlled**: HbA1c < 7.0%
- **Needs Attention**: HbA1c >= 7.0% and < 9.0%
- **High Risk/Urgent**: HbA1c >= 9.0%
- **No Data Available**: No valid HbA1c observation found

## Error Handling

- The main method handles errors at two levels:
  1. **System-level errors**: If HbA1c CodeSet is not found, all patients receive an error result
  2. **Patient-level errors**: Each patient's processing is wrapped in try-catch, so one patient's error doesn't affect others

- Error messages are stored in the `errorMessage` field of the `AssessmentResult` object

## Salesforce Objects Used

The class interacts with the following standard Salesforce Health Cloud objects:
- **CodeSet**: To identify HbA1c laboratory codes
- **CareObservation**: To retrieve HbA1c laboratory values
- **CareProgram**: To identify Diabetes care programs
- **CareProgramEnrollee**: To check patient enrollment in programs

## Code Quality Requirements

- Include comprehensive JavaDoc comments for the class and all methods
- Use `with sharing` to enforce sharing rules
- Follow bulkification best practices (process collections, not individual records)
- Use efficient SOQL queries with appropriate filters
- Handle null values and empty collections gracefully
- Use descriptive variable names
- Include proper error handling with meaningful error messages

## Example Usage Context

This class is designed to be called from:
- Salesforce Flow (using the Invocable Method)
- Process Builder
- Other Apex code
- External systems via REST/SOAP APIs

The invocable method allows it to be used declaratively in automation tools without writing additional code.

Create label and description for all invocable variables.

Set Required=true for patientId invocable variable. 