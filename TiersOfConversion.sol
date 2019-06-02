contract TiersOfConversion {
    
    // Defines the parameters to be kept track of for each user
    struct User {
        uint8 tier;
        uint numberOfTransactions;
        uint numberOfUniqueAddresses;
        uint timeInPlatform;
        uint joinedTimestamp;
    }
    
    mapping(address => User) users;
    
    // ARBITRARY VALUES FOR EXAMPLE ONLY
    uint constant maxTransactions = 10000;
    uint constant maxAddresses = 1000;
    uint constant maxTime = 730 days;
    
    // Tier calculated after every transaction --> not efficient, model must be improved
    // Suggestion: wallet keeps track of tier off-chain and calls to update once as the tier increases
    function calculateTier(address update) internal {
            uint8 newTier = 0;
            
            // Checks current time vs. time user joined system
            users[update].timeInPlatform = block.timestamp - users[update].joinedTimestamp;
            
            // Sets score for n(transactions)
            uint nPctg = uint(100*users[update].numberOfTransactions / maxTransactions);
            
            // Sets score for distinct addresses
            uint addressesPctg = uint(100*users[update].numberOfUniqueAddresses / maxAddresses);
                      
                      
            // Sets score for time
            uint timePctg = uint(100*users[update].timeInPlatform / maxTime);
            
            // Gets score out of 100
            uint score = 100*(nPctg + addressesPctg + timePctg)/ 300;
            
            // Maps score to tier
            if(score < 20) {
                newTier = 1;
            }
            else if(score < 40) {
                newTier = 2;
            } 
            else if(score < 60) {
                newTier = 3;
            }           
            else if(score < 80) {
                newTier = 4;
            }
            else {
                newTier = 5;
            }
            
            // Updates tier
            users[update].tier = newTier;
    }
    
}
