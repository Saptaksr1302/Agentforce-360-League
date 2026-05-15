// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Test portfolio value - Calculate total value of all active financial accounts

// Test 1: With default (Active status, no account type filter)
System.debug('=== Test 1: Default (Active status, all account types) ===');
PortfolioValueCalculator.InputRequest input1 = new PortfolioValueCalculator.InputRequest();
// Leave status and accountType empty to use default 'Active' and all types
List<PortfolioValueCalculator.InputRequest> requests1 = new List<PortfolioValueCalculator.InputRequest>{input1};
List<PortfolioValueCalculator.ValueResult> valueResult1 = 
    PortfolioValueCalculator.calculatePortfolioValue(requests1);
System.debug('Total Portfolio Value (All types, Active): $' + valueResult1[0].totalValue);

/* Test 2: Filter by account type (Mortgage) - now supported via invocable input */
System.debug('\n=== Test 2: Filter by Account Type = Mortgage ===');
PortfolioValueCalculator.InputRequest input2 = new PortfolioValueCalculator.InputRequest();
input2.accountType = 'Mortgage';
input2.status = 'Active';
List<PortfolioValueCalculator.InputRequest> requests2 = new List<PortfolioValueCalculator.InputRequest>{input2};
List<PortfolioValueCalculator.ValueResult> valueResult2 = 
    PortfolioValueCalculator.calculatePortfolioValue(requests2);
System.debug('Total Portfolio Value (Mortgage, Active): $' + valueResult2[0].totalValue);

// Test 3: Explicitly set Active status without account type
System.debug('\n=== Test 3: Explicitly Active status, all account types ===');
PortfolioValueCalculator.InputRequest input3 = new PortfolioValueCalculator.InputRequest();
input3.status = 'Active';
List<PortfolioValueCalculator.InputRequest> requests3 = new List<PortfolioValueCalculator.InputRequest>{input3};
List<PortfolioValueCalculator.ValueResult> valueResult3 = 
    PortfolioValueCalculator.calculatePortfolioValue(requests3);
System.debug('Total Portfolio Value (All types, Active): $' + valueResult3[0].totalValue);

System.debug('\n=== SUCCESS: All tests completed successfully! ===');
