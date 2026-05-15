# Step-by-Step Instructions: Create Case On Critical Health Flow

## Overview
This flow creates a Case automatically when a Data Cloud record has `health_status__c` set to "Critical".

## Prerequisites
- Access to Setup in Salesforce
- Flow Builder permissions
- The Data Cloud object `Manufacturing_Asset_Health_Score__dlm` (or `__cio`) must exist and be triggerable

---

## Step 1: Create a New Data Cloud Triggered Flow

1. Navigate to **Setup** → Search for "Flows" → Click **Flows**
2. Click **New Flow**
3. Select **Data Cloud Triggered Flow** (this is the specific template for Data Cloud)
4. Click **Create**

---

## Step 2: Configure the Data Cloud Flow Trigger

1. **Data Cloud Object**: Select your Data Cloud object:
   - Try `Manufacturing_Asset_Health_Score__dlm` first
   - If that doesn't exist, try `Manufacturing_Asset_Health_Score__cio`
   - If neither exists, check your Data Cloud objects for the correct name
   - Note: Only Data Cloud objects (with `__dlm` or `__cio` suffix) will appear in this list

2. **Trigger the Flow When**: Select **A record is created or updated**

3. **Entry Conditions**: Leave blank (we'll check conditions in the flow)

4. Click **Done**

---

## Step 3: Add a Decision Element

1. From the **Toolbox** on the left, drag **Decision** onto the canvas
2. Click the **Decision** element to configure it
3. **Label**: `Check Health Status`
4. **API Name**: `CheckHealthStatus` (auto-generated)
5. **Outcome Label**: `Is Critical`
6. **Condition Requirements**: Select **All conditions are met (AND)**
7. **Add Condition**:
   - **Resource**: Select `$Record.health_status__c` (from the trigger object)
   - **Operator**: `Equals`
   - **Value**: `Critical` (text)
8. **Default Outcome**: `Not Critical` (leave this path empty - it will end the flow)
9. Click **Done**

---

## Step 4: Add a Get Records Element

1. From the **Toolbox**, drag **Get Records** onto the canvas
2. Connect it from the **"Is Critical"** outcome of the Decision element
3. Click the **Get Records** element to configure it
4. **Label**: `Get Asset Record`
5. **API Name**: `GetAssetRecord` (auto-generated)
6. **Object**: Select `Asset`
7. **How Many Records to Store**: `Only the first record`
8. **Filter Asset Records**:
   - **Field**: `SerialNumber`
   - **Operator**: `Equals`
   - **Value**: Select `$Record.asset_serial__c` (from the trigger object)
9. **Get Fields**: 
   - Add `Id`
   - Add `AccountId`
10. **How to Store Record Data**: `Automatically store all fields`
11. Click **Done**

---

## Step 5: Add a Formula Resource (Case Subject)

1. In the **Manager** tab (left sidebar), click **New Resource**
2. Select **Formula**
3. **Resource Type**: `Formula`
4. **API Name**: `CaseSubject`
5. **Data Type**: `Text`
6. **Formula**: 
   ```
   "Critical Health Alert - Asset " & {!$Record.asset_serial__c}
   ```
7. Click **Done**

---

## Step 6: Add Another Formula Resource (Case Description)

1. In the **Manager** tab, click **New Resource**
2. Select **Formula**
3. **Resource Type**: `Formula`
4. **API Name**: `CaseDescription`
5. **Data Type**: `Text`
6. **Formula**:
   ```
   "Critical health status detected for asset " & {!$Record.asset_serial__c} & ". Immediate attention required."
   ```
7. Click **Done**

---

## Step 7: Add a Create Records Element

1. From the **Toolbox**, drag **Create Records** onto the canvas
2. Connect it from the **Get Asset Record** element
3. Click the **Create Records** element to configure it
4. **Label**: `Create Case`
5. **API Name**: `CreateCase` (auto-generated)
6. **How to Create Records**: `Use separate resources, and set fields individually`
7. **Object**: Select `Case`
8. **Set Field Values**:
   
   **Subject**:
   - **Field**: `Subject`
   - **Value**: Select `{!CaseSubject}` (the formula you created)
   
   **Description**:
   - **Field**: `Description`
   - **Value**: Select `{!CaseDescription}` (the formula you created)
   
   **Status**:
   - **Field**: `Status`
   - **Value**: `New` (text)
   
   **Priority**:
   - **Field**: `Priority`
   - **Value**: `High` (text)
   
   **Origin**:
   - **Field**: `Origin`
   - **Value**: `Data Cloud` (text)
   

9. Click **Done**

---

## Step 8: Configure Flow Settings

1. Click the **Flow Properties** (gear icon) in the top right
2. **Flow Label**: `Create Case On Critical Health`
3. **Flow API Name**: `CreateCaseOnCriticalHealth`
4. **Description**: `Data Cloud triggered flow that creates a Case when health_status__c is Critical`
5. **Interview Label**: `Create Case On Critical Health {!$Flow.CurrentDateTime}`
6. Click **Done**

---

## Step 9: Save and Activate

1. Click **Save** (top right)
2. Enter a **Flow Label**: `Create Case On Critical Health`
3. Click **Save**
4. Click **Activate** (top right)
5. Click **Activate** in the confirmation dialog

---

## Flow Structure Summary

```
Start (Data Cloud Trigger)
    ↓
Decision: Check Health Status
    ├─ Is Critical? → Get Asset Record → Create Case
    └─ Not Critical → (End)
```

**Important**: This is a **Data Cloud Triggered Flow**, which is specifically designed to work with Data Cloud objects. It provides better integration and performance for Data Cloud scenarios compared to regular record-triggered flows.

---

## Troubleshooting

### If the Data Cloud object is not available:
1. Verify the object exists in Data Cloud
2. Check that the object is configured for flow triggers
3. Try using the object API name with `__dlm` suffix instead of `__cio`

### If fields are not found:
1. Verify field API names match exactly (case-sensitive)
2. Check that fields exist on the Data Cloud object
3. Ensure you're selecting from the correct object in the resource picker

### If the flow doesn't trigger:
1. Check that the flow is **Active**
2. Verify the trigger object and field names are correct
3. Test by creating/updating a record with `health_status__c = "Critical"`
4. Check **Debug Logs** for errors

### If Asset lookup fails:
1. Verify the `SerialNumber` field exists on Asset
2. Ensure the `asset_serial__c` value matches an Asset's SerialNumber exactly
3. Check that the Asset record exists

---

## Testing the Flow

1. Create or update a record in your Data Cloud object
2. Set `health_status__c` to `Critical`
3. Set `asset_serial__c` to a valid Asset SerialNumber
4. Save the record
5. Check that a Case was created with:
   - Subject: "Critical Health Alert - Asset [SerialNumber]"
   - Status: New
   - Priority: High
   - Origin: Data Cloud
   - Linked to the Asset and Account

---

## Notes

- **Data Cloud Triggered Flows** are specifically designed for Data Cloud objects and provide:
  - Better performance and scalability
  - Native integration with Data Cloud data models
  - Support for Data Cloud-specific features
- The flow will run every time a record is created or updated in the Data Cloud object
- To prevent duplicate cases, you may want to add a check to see if a case already exists for this asset
- Consider adding error handling if the Asset lookup fails
- The flow assumes the Asset's SerialNumber field matches the Data Cloud object's asset_serial__c field
- If you don't see "Data Cloud Triggered Flow" as an option, ensure you have Data Cloud licenses and the feature is enabled in your org

