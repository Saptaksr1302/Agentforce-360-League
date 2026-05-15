SELECT 
    ssot__AssetTelematicsEvent__dlm.ssot__AssetId__c as AssetId__c,
    AVG(ssot__AssetTelematicsEvent__dlm.ssot__AssetTemperatureNumber__c) as AssetTemperatureNumber__c,
    CASE 
        WHEN AVG(ssot__AssetTelematicsEvent__dlm.ssot__AssetTemperatureNumber__c) > 200 THEN 'Critical'
        WHEN AVG(ssot__AssetTelematicsEvent__dlm.ssot__AssetTemperatureNumber__c) > 180 THEN 'Warning'
        ELSE 'Normal'
    END as Health_Status__c
FROM ssot__AssetTelematicsEvent__dlm
GROUP BY AssetId__c