public without sharing class CriticalAssetHealthService {

    public class Result {
        @InvocableVariable(description='Salesforce record id of the asset')
        public Id assetId;
        @InvocableVariable(description='Name of the asset')
        public String assetName;
        @InvocableVariable(description='Id of the account')
        public Id accountId;
        @InvocableVariable(description='Name of the account')
        public String accountName;
        @InvocableVariable(description='Health status of the asset')
        public String healthStatus;
        @InvocableVariable(description='Temperature of the asset')
        public Decimal assetTemperature;
    }

    public class Request {
        @InvocableVariable(description='Id of the account for which to query critical assets')
        public Id accountId;
    }

    @InvocableMethod(label='Get Critical Assets' description='Queries Asset health calculated insight and returns enriched results with Asset and Account fields.')
    public static List<Result> getCriticalAssets(List<Request> request) {

        List<String> assetIds = new List<String>();

        String ciName = 'Asset_Health_Score__cio';
        String filters = '[Health_Status__c=Critical]';
        ConnectApi.CdpQueryInput queryInput = new ConnectApi.CdpQueryInput();

        ConnectApi.CdpQueryOutput output = ConnectApi.CdpQuery.queryCalculatedInsights(ciName, null, null, null, filters, null, null);

        List<Object> results = output.data;

        for(Object o: results){
            String jsonStr = JSON.serialize(o);
            Map<String, Object> insight = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
            String assetId = (String) insight.get('AssetId__c');
            if(assetId != null){
                assetIds.add(assetId);
            }
        }

        // Query Asset and related Account
        Map<Id, Asset> assetsById = new Map<Id, Asset>([
            SELECT Id, Name, AccountId, Account.Name
            FROM Asset
            WHERE Id IN :assetIds
            WITH SYSTEM_MODE
        ]);

        // Build results
        List<Result> outputResults = new List<Result>();

        for(Object o: results){
            String jsonStr = JSON.serialize(o);
            Map<String, Object> insight = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
            String assetId = (String) insight.get('AssetId__c');
            
            Result r = new Result();
            r.assetId = assetId;

            Asset a = assetsById.get(assetId);
            if (a != null) {
                r.assetName = a.Name;
                r.accountId = a.AccountId;
                r.accountName = (a.Account != null) ? a.Account.Name : null;
                Object temp = insight.get('AssetTemperatureNumber__c');
                r.assetTemperature = (temp == null) ? null : (Decimal) temp;
                r.healthStatus = (String) insight.get('Health_Status__c');
            }
            outputResults.add(r);
        }
        return outputResults;
    }
}