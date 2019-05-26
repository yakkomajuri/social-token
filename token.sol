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
    address public chairperson;
    address public newOwner;
    address public nextInLine;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(address _chairperson, address _nextInLine) public {
        require (msg.sender != _chairperson);
        chairperson = _chairperson;
        nextInLine = _nextInLine;
    }

    modifier onlyChairperson {
        require(msg.sender == chairperson);
        _;
    }

    function transferOwnership(address _newOwner) public onlyChairperson {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(chairperson, newOwner);
        chairperson = newOwner;
        newOwner = address(0);
    }
    
    function selectNextInLine(address _ad) public {
        require(msg.sender == nextInLine);
        nextInLine = _ad;
    }
    
    
}

contract Foundation is Owned {
    
    modifier onlyFoundation() {  
        require(isFoundation[msg.sender]);
        _;
    }

    constructor(address _owner1, address _owner2) public {
        isFoundation[msg.sender] = true;
        isFoundation[_owner1] = true;
        isFoundation[_owner2] = true;
        numberOfVoters = 3;
    }

    mapping(address => bool) isFoundation;
    mapping(address => mapping(address => bool)) hasVotedToAdd;
    mapping(address => mapping(address => bool)) hasVotedToRemove;
    mapping(address => uint8) public votesToAdd;
    mapping(address => uint8) public votesToRemove;
    
    address[] public addressesVotedOn;

    uint8 public numberOfVoters;
    
    function voteToAdd(address _ad) public onlyFoundation {
        require(hasVotedToAdd[msg.sender][_ad] == false,
        "this");
        require(isFoundation[_ad] == false,
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
        require(isFoundation[_ad]);
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
            isFoundation[_ad] = true;
        }
        else { }
    }
    
    function enoughVotesToRemove(address _ad) internal {
        if (votesToRemove[_ad] * 2 > numberOfVoters) {
            numberOfVoters -= 1;
            isFoundation[_ad] = false;
            removeOwnerVotes(_ad);
            if (_ad == chairperson) {
                chairperson = nextInLine;
                nextInLine = msg.sender;
            }
            else if (_ad == nextInLine) {
                nextInLine = msg.sender;
            }
        }
        else { }
    }
    
    function getOwners(address _ad) external view returns(bool) {
        return isFoundation[_ad];
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

contract SocialToken is ERC20Interface, Foundation, TiersOfConversion {
    
    modifier onlyChairperson() {  
        require(msg.sender == chairperson);
        _;
    }
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint public cap = 5000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) whitelisted;
    mapping(address => bool) blacklisted;

    constructor() public {
        symbol = "SOCIAL";
        name = "Social Token";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balances[chairperson] = _totalSupply;
        emit Transfer(address(0), chairperson, _totalSupply);
    }
    
    function getConversionFee(address ad) public view returns (uint8){
        if (users[ad].tier == 5) return 0;
        return (100 - (users[ad].tier * 20))/4;
    }
    
    function addToWhitelist(address toAdd) public onlyFoundation {
        require(blacklisted[toAdd] == false);
        whitelisted[toAdd] = true;
        users[toAdd].joinedTimestamp = block.timestamp;
        users[toAdd].tier = 1;
    }
    
        
    function removeFromWhitelist(address toRemove) public onlyFoundation {
        whitelisted[toRemove] = false;
    }
    
    function addToBlackList(address toAdd) public onlyChairperson {
        blacklisted[toAdd] = true;
    }

    function updateSupply(uint newSupply) public onlyChairperson {
        require (newSupply > _totalSupply);
        balances[chairperson] = balances[chairperson].add(newSupply - _totalSupply);
        _totalSupply = newSupply;
    }   
    
    function burn(uint numberOfTokens) public onlyChairperson {
        require(balances[chairperson] > numberOfTokens);
        balances[chairperson] = balances[chairperson].sub(numberOfTokens);
    }

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
