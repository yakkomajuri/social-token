pragma solidity^0.5.0;

// Defines SocialToken contract to allow calls
contract SocialToken {
       
       // Checks if an address is whitelisted in the SocialToken system
       function isWhitelisted(address _ad) external view returns(bool) { }
}

// A pool of funds to cover transaction fees of users in the SocialToken system
contract FeePool {
    
    //Substitute for address of SocialToken
    SocialToken tokenContract = SocialToken([ADDRESS HERE]);
    
   // Sends ETH to wallet requesting funds
   function getEther() public {
   
        // Wallet must be whitelisted
        require(tokenContract.isWhitelisted(msg.sender));
        
        // Balance must be low enough, ideally a function would exist to set the threshold
        require(msg.sender.balance < 0.01 ether);
        
        // Transfer funds to wallet
        msg.sender.transfer(0.05 ether);
    }
    
}
