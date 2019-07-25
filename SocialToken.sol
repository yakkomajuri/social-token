pragma solidity ^0.5.0;
import "./SafeMath.sol";
import "./ApproveCallAndFallBack.sol";
import "./ERC20Interface.sol";
import "./Foundation.sol";
import "./TiersOfConversion.sol";

contract SocialToken is ERC20Interface, Foundation, TiersOfConversion {

    using SafeMath for uint;

    // Token Specifications
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint private _totalSupply;

    // Cap on the number of tokens an address can hold at a given time
    // Cap is not valid for Foundation addresses 
    uint public cap;

    // Keeps track of balances and 'delegated' balances (allowance)
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // Only whitelisted addresses can receive tokens
    mapping(address => bool) whitelisted;

    // Blacklisted addresses can never use the system again
    mapping(address => bool) blacklisted;


    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals, 
        address[4] memory _foundation,
        uint _cap,
        uint _supply,
        uint _maxTxs,
        uint _maxTime,
        uint _maxAddresses,
        bool _safety
        ) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = _supply * 10**uint(decimals);
        for (uint i = 0; i < _foundation.length; i++) {
            isFoundation[_foundation[i]] = true;
        }
        chairperson = _foundation[0];
        nextInLine = _foundation[1];

        // All tokens initially assigned to Chairperson
        balances[chairperson] = _totalSupply;

        // 'Safety' on requires that the Chairperson not be the creator of the contract
        if (_safety) {
            require (msg.sender != chairperson);
        }
        maxTime = _maxTime;
        maxAddresses = _maxAddresses;
        maxTransactions = _maxTxs;
        cap = _cap;
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
    function addToWhitelist(address toAdd) external onlyFoundation {
        require(blacklisted[toAdd] == false,
        "Address is blacklisted");

        // Add to whitelist, set-up user's joining time and initial tier
        whitelisted[toAdd] = true;
        users[toAdd].joinedTimestamp = block.timestamp;
        users[toAdd].tier = 1;
    }
    
    // Removing an address from the whitelist can be done by any foundation member
    // Removing from whitelist does not reset time joined in case of malicious action
    function removeFromWhitelist(address toRemove) external onlyFoundation {
        whitelisted[toRemove] = false;
    } 

    // Only Chairperson can blacklist addresses
    function addToBlackList(address toAdd) external onlyChairperson {
        blacklisted[toAdd] = true;
    }

    // Chairperson can emit more tokens if collateral > current supply
    function updateSupply(uint newSupply) external onlyChairperson {
        require (newSupply > _totalSupply);

        // Chairperson gets additional tokens
        balances[chairperson] = balances[chairperson].add(newSupply - _totalSupply);
        
        _totalSupply = newSupply;
    }   
    
    // Burning is used to control the overcollateral
    function burn(uint numberOfTokens) external onlyChairperson {
        // Burns can only happen from the Chairperson's account - circulating supply never affected
        require(balances[chairperson] > numberOfTokens,
        "Chairperson does not have enough tokens to burn");
        balances[chairperson] = balances[chairperson].sub(numberOfTokens);
    }

   function isWhitelisted(address _ad) external view returns(bool) {
        return whitelisted[_ad];
    }

    // STANDARD ERC-20 FUNCTIONS ---------------------------------------

    function totalSupply() external view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        // Receiving address must be whitelisted or be a Foundation member
        require (whitelisted[to] || isFoundation[to],
        "Address is not yet accredited to use the system");
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        // Checks that the receiving address will not be over the cap after the transfer
        require (balances[to] <= cap || isFoundation[to],
        "Address limit reached");
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // Receiving address must be whitelisted or be a Foundation member
        require (whitelisted[to] || isFoundation[to],
        "Address is not yet accredited to use the system");
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        // Checks that the receiving address will not be over the cap after the transfer
        require (balances[to] <= cap || isFoundation[to],
        "Address limit reached");
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

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyChairperson returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(chairperson, tokens);
    }

    // Fallback function - do not accept transfers
    function () external payable {
        revert();
    }
}

