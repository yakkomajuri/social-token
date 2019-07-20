contract SocialToken is ERC20Interface, Foundation, TiersOfConversion {
    
    modifier onlyChairperson() {  
        require(msg.sender == chairperson);
        _;
    }
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint private _totalSupply;
    uint public cap;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) whitelisted;
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
        balances[chairperson] = _totalSupply;
        if (_safety) {
            require (msg.sender != chairperson);
        }
        maxTime = _maxTime;
        maxAddresses = _maxAddresses;
        maxTransactions = _maxTxs;
        cap = _cap;
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
    
    function isWhitelisted(address _ad) external view returns(bool) {
        return whitelisted[_ad];
    }
}
