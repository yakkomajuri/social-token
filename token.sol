pragma solidity ^0.5.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Foundation {
    
    modifier onlyFoundation() {  
        require(isOwner[msg.sender]);
        _;
    }
    

    constructor(address _owner1, address _owner2) public {
        isOwner[msg.sender] = true;
        isOwner[_owner1] = true;
        isOwner[_owner2] = true;
        numberOfVoters = 3;
    }

    mapping(address => bool) isOwner;
    mapping(address => mapping(address => bool)) hasVotedToAdd;
    mapping(address => mapping(address => bool)) hasVotedToRemove;
    mapping(address => uint8) public votesToAdd;
    mapping(address => uint8) public votesToRemove;
    
    address[] public addressesVotedOn;

    uint8 public numberOfVoters;
    
    function voteToAdd(address _ad) public onlyFoundation {
        require(hasVotedToAdd[msg.sender][_ad] == false,
        "this");
        require(isOwner[_ad] == false,
        "that");
        hasVotedToAdd[msg.sender][_ad] = true;
        if (votesToAdd[_ad] == uint8(0)) {
            addressesVotedOn.push(_ad);
        if (addressesVotedOn.length == 15) {
                reset();
            }
        }
        votesToAdd[_ad]++;
        enoughVotesToAdd(_ad);
    }
    
    function voteToRemove(address _ad) public onlyFoundation {
        require(hasVotedToRemove[msg.sender][_ad] == false);
        require(isOwner[_ad]);
        hasVotedToRemove[msg.sender][_ad] = true;
        if (votesToRemove[_ad] == uint8(0)) {
            addressesVotedOn.push(_ad);
        if (addressesVotedOn.length == 15) {
                reset();
            }
        }
        votesToRemove[_ad]++;
        enoughVotesToRemove(_ad);
    } 
    
    function removeMyVote(address _ad, uint8 _choice) public onlyFoundation {
        if (_choice == 0) {
            require(hasVotedToAdd[msg.sender][_ad]);
            hasVotedToAdd[msg.sender][_ad] = false;
            votesToAdd[_ad]--;
        }
        if (_choice == 1) {
            require(hasVotedToRemove[msg.sender][_ad]);
            hasVotedToRemove[msg.sender][_ad] = false;
            votesToRemove[_ad]--;
        }
    }
    
    function enoughVotesToAdd(address _ad) internal {
        if (votesToAdd[_ad] * 2 > numberOfVoters) {
            numberOfVoters += 1;
            isOwner[_ad] = true;
        }
        else { }
    }
    
    function enoughVotesToRemove(address _ad) internal {
        if (votesToRemove[_ad] * 2 > numberOfVoters) {
            numberOfVoters -= 1;
            isOwner[_ad] = false;
            removeOwnerVotes(_ad);
        }
        else { }
    }
    
    function getOwners(address _ad) external view returns(bool) {
        return isOwner[_ad];
    }
    
    
    function reset() internal {
        for (uint i = 0; i < addressesVotedOn.length; i++) {
            votesToAdd[addressesVotedOn[i]] = 0;
            votesToRemove[addressesVotedOn[i]] = 0;
            delete addressesVotedOn[i];
        }
    }
    
    function removeOwnerVotes(address _ad) internal {
        address a;
        for (uint i = 0; i < addressesVotedOn.length; i++) {
            a = addressesVotedOn[i];
            if (hasVotedToRemove[_ad][a]) {
                votesToRemove[a]--;
            }
            if (hasVotedToAdd[_ad][a]){
                votesToAdd[a]--;
            }
        }
    }
    
}

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

contract SocialToken is ERC20Interface, Owned, Foundation, TiersOfConversion {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint public cap = 5000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) whitelisted;

    constructor() public {
        symbol = "SOCIAL";
        name = "Social Token";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function getConversionFee(address ad) public view returns (uint8){
        if (users[ad].tier == 5) return 0;
        return (100 - (users[ad].tier * 20))/4;
    }
    
    function addToWhitelist(address add) public onlyFoundation {
        whitelisted[add] = true;
        users[add].joinedTimestamp = block.timestamp;
        users[add].tier = 1;
    }

    function updateSupply(uint newSupply) public onlyFoundation {
        require (newSupply > _totalSupply);
        balances[owner] = balances[owner].add(newSupply - _totalSupply);
        _totalSupply = newSupply;
    }   
    
    function burn(uint numberOfTokens) public onlyOwner {
        require(balances[owner] > numberOfTokens);
        balances[owner] = balances[owner].sub(numberOfTokens);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require (whitelisted[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        require (balances[to] <= cap || isOwner[to]);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require (whitelisted[to]);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        require (balances[to] <= cap || isOwner[to]);
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

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
