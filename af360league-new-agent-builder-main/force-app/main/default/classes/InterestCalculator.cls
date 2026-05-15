public class InterestCalculator {
    @InvocableMethod(label='Calculate YTD Interest Paid' 
                     description='Returns total interest paid for a specified fiscal year. If no year is provided, uses the current fiscal year.')
    public static List<InterestResult> calculateYTDInterest(List<InputRequest> requests) {
        List<InterestResult> results = new List<InterestResult>();
        
        for(InputRequest request : requests) {
            // Determine the account ID from either accountId or FinancialAccountNumber
            String accountId = request.accountId;
            
            if (accountId == null || accountId == '') {
                // Look up account ID from FinancialAccountNumber
                if (request.financialAccountNumber != null && request.financialAccountNumber != '') {
                    List<FinancialAccount> accounts = [
                        SELECT Id
                        FROM FinancialAccount 
                        WHERE FinancialAccountNumber = :request.financialAccountNumber
                        LIMIT 1
                    ];
                    
                    if (accounts.size() > 0) {
                        accountId = accounts[0].Id;
                    } else {
                        // No account found with this number, skip this request
                        continue;
                    }
                } else {
                    // Neither accountId nor FinancialAccountNumber provided, skip
                    continue;
                }
            }
            
            Integer fiscalYear = request.fiscalYear;
            
            // If no fiscal year provided, get it from the account's most recent transaction
            if (fiscalYear == null) {
                List<AggregateResult> fiscalYearResult = [
                    SELECT FISCAL_YEAR(TransactionDate) fiscalYear
                    FROM FinancialAccountTransaction 
                    WHERE FinancialAccountId = :accountId 
                    GROUP BY FISCAL_YEAR(TransactionDate)
                    ORDER BY MAX(TransactionDate) DESC
                    LIMIT 1
                ];
                
                if (fiscalYearResult.size() > 0) {
                    fiscalYear = (Integer)fiscalYearResult[0].get('fiscalYear');
                } else {
                    fiscalYear = Date.today().year(); // Fallback to current year
                }
            }
            
            // Use aggregate query to sum interest directly
            List<AggregateResult> interestSum = [
                SELECT SUM(Interest_Amount__c) totalInterest
                FROM FinancialAccountTransaction 
                WHERE FinancialAccountId = :accountId 
                AND FISCAL_YEAR(TransactionDate) = :fiscalYear
            ];
            
            Decimal totalInterest = interestSum.size() > 0 && interestSum[0].get('totalInterest') != null 
                ? (Decimal)interestSum[0].get('totalInterest') 
                : 0;
            
            InterestResult result = new InterestResult();
            result.accountId = accountId;
            result.ytdInterest = totalInterest;
            result.fiscalYear = fiscalYear;
            results.add(result);
        }
        
        return results;
    }
    
    // Input wrapper class for invocable method parameters
    public class InputRequest {
        @InvocableVariable(label='Account ID' 
                          description='Optional: The Financial Account ID to calculate interest for. Either Account ID or Financial Account Number must be provided.')
        public String accountId;
        
        @InvocableVariable(label='Financial Account Number' 
                          description='Optional: The Financial Account Number to calculate interest for. Either Account ID or Financial Account Number must be provided.')
        public String financialAccountNumber;
        
        @InvocableVariable(label='Fiscal Year' 
                          description='Optional: The fiscal year to calculate interest for (e.g., 2025). If not provided, uses the current fiscal year.')
        public Integer fiscalYear;
    }
    
    // Output wrapper class for invocable method results
    public class InterestResult {
        @InvocableVariable(label='Account ID' 
                           description='The Financial Account ID that the interest was calculated for')
        public String accountId;
        
        @InvocableVariable(label='YTD Interest Paid' 
                           description='Total interest amount paid in the specified fiscal year')
        public Decimal ytdInterest;
        
        @InvocableVariable(label='Fiscal Year' 
                           description='The fiscal year used for the interest calculation')
        public Integer fiscalYear;
    }
}