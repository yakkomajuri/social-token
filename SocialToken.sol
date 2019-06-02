pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ApproveCallAndFallBack.sol";
import "./ERC20Interface.sol";
import "./Foundation.sol";
import "./TiersOfConversion.sol";


contract SocialToken is ERC20Interface, Foundation, TiersOfConversion {

    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint public cap = 5000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
// ----------------------- BEGINNING OF MODIFICATIONS TO STD ERC20 CONTRACT --------------------------------
    
    modifier onlyChairperson() {  
        require(msg.sender == chairperson);
        _;
    }
    
    // Only whitelisted addresses can receive tokens
    mapping(address => bool) whitelisted;
    
    // Blacklisted addresses can never use the system again
    mapping(address => bool) blacklisted;

    constructor() public {
        symbol = "SOCIAL";
        name = "Social Token";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        
        // All tokens initially assigned to Chairperson
        balances[chairperson] = _totalSupply;
        emit Transfer(address(0), chairperson, _totalSupply);
    }
    
    // Returns the fee for a user based on the respective Tier of Conversion
    // Useful to inform the backend of the conversion app
    function getConversionFee(address ad) public view returns (uint8){
        
        // Fee is 0% for Tier 5
        if (users[ad].tier == 5) return 0;
        
        // Fee decreases linearly accross tiers from 20% to 0%
        return (100 - (users[ad].tier * 20))/4;
    }
    
    // Foundation members can add addresses to the whitelist
    function addToWhitelist(address toAdd) public onlyFoundation {
    
        // Make sure address is not blacklisted
        require(blacklisted[toAdd] == false);
        
        // Add to whitelist, set-up user's joining time
        whitelisted[toAdd] = true;
        users[toAdd].joinedTimestamp = block.timestamp;
        users[toAdd].tier = 1;
    }
    
    // Removing an address from the whitelist can be done by any foundation member
    // Removing from whitelist does not reset time joined in case of malicious action
    function removeFromWhitelist(address toRemove) public onlyFoundation {
        whitelisted[toRemove] = false;
    }
    
    // Only Chairperson can blacklist addresses
    function addToBlackList(address toAdd) public onlyChairperson {
        blacklisted[toAdd] = true;
    }

    // Chairperson can emit more tokens if collateral > current supply
    function updateSupply(uint newSupply) public onlyChairperson {
        require (newSupply > _totalSupply);
        
        // Chairperson gets additional tokens
        balances[chairperson] = balances[chairperson].add(newSupply - _totalSupply);
        _totalSupply = newSupply;
    }   
    
    // Burning is used to control the overcollateral
    function burn(uint numberOfTokens) public onlyChairperson {
    
        // Burns can only happen from the Chairperson's account - circulating supply never affected
        require(balances[chairperson] > numberOfTokens);
        balances[chairperson] = balances[chairperson].sub(numberOfTokens);
    }


// ----------------------- END OF MODIFICATIONS TO STD ERC20 CONTRACT --------------------------------

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require (whitelisted[to] || isFoundation[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        require (balances[to] <= cap || isFoundation[to]);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require (whitelisted[to] || isFoundation[to]);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        require (balances[to] <= cap || isFoundation[to]);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function () external payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyChairperson returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(chairperson, tokens);
    }
}
