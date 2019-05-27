pragma solidity^0.5.0;

contract SocialToken {
       function isWhitelisted(address _ad) external view returns(bool) { }
}

contract FeePool {
    
    
    SocialToken tokenContract = SocialToken([ADDRESS HERE]);
    
    function getEther() public {
        require(tokenContract.isWhitelisted(msg.sender));
        require(msg.sender.balance < 0.01 ether);
        msg.sender.transfer(0.01 ether);
    }
    
}
