contract TiersOfConversion {
    
    struct User {
        uint8 tier;
        uint numberOfTransactions;
        uint numberOfUniqueAddresses;
        uint timeInPlatform;
        uint joinedTimestamp;
    }
    
    mapping(address => User) users;
    
    uint constant maxTransactions = 10000;
    uint constant maxAddresses = 1000;
    uint constant maxTime = 730 days;

    function calculateTier(address update) internal {
            uint8 newTier = 0;
            users[update].timeInPlatform = block.timestamp - users[update].joinedTimestamp;
            uint nPctg = uint(100*users[update].numberOfTransactions / maxTransactions);
            uint addressesPctg = uint(100*users[update].numberOfUniqueAddresses / maxAddresses);
            uint timePctg = uint(100*users[update].timeInPlatform / maxTime);
            uint score = 100*(nPctg + addressesPctg + timePctg)/ 300;
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
            users[update].tier = newTier;
    }
    
}
