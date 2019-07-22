pragma solidity^0.5.0;

import "./SocialToken.sol";


contract TokenFactory {
    
    mapping (address => address[]) userTokens;
    mapping (address => string) contractName;
    
    event NewTokenCreated(address _creator, address _token);
    
    // Creates a new token of type SocialToken
    function createNewToken(
        string calldata _name, 
        string calldata _symbol, 
        uint8 _decimals, 
        address[4] calldata _foundation,
        uint _cap,
        uint _supply,
        uint _maxTxs,
        uint _maxTime,
        uint _maxAddresses,
        bool _safety
        ) 
        external
        {
        SocialToken tokenContract = new SocialToken (
            _name, 
            _symbol, 
            _decimals, 
            _foundation,
            _cap,
            _supply,
            _maxTxs,
            _maxTime,
            _maxAddresses,
            _safety
            );
        addUserToken(address(tokenContract), _name);
    }
    
    /* The following functionalities keep track on-chain of all tokens
    each user has created and a name assigned to them. It is used for a 
    serverless Token Factory application on a test network. This is
    gas-expensive and would ideally be done via a database if the contract
    existed on the mainnet. */

    function addUserToken(address _newToken, string memory _name) internal {
        contractName[_newToken] = _name;
        userTokens[msg.sender].push(_newToken);
        emit NewTokenCreated(msg.sender, address(_newToken));
    }
    
    function getUserTokens(address _user) public view returns (address[] memory) {
        return userTokens[_user];
    }
    
    function getContractName(address _contract) external view returns (string memory) {
        return contractName[_contract];
    }
}

