pragma solidity^0.5.0;

contract PresidedByChairperson {
    
    address public chairperson;
    address public newOwner;
    address public nextInLine;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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

// Fluid Consensus model - Foundation is always undergoing election
contract Foundation is PresidedByChairperson {

    // Keeps track of current Foundation members
    mapping(address => bool) isFoundation;
    
    // Prevents a double-vote to add an address to the Foundation
    mapping(address => mapping(address => bool)) hasVotedToAdd;
    
    // Prevents a double-vote to remove an address to the Foundation
    mapping(address => mapping(address => bool)) hasVotedToRemove;
    
    // Number of votes received by an address to become a part of the Foundation
    mapping(address => uint8) public votesToAdd;
    
    // Number of votes received by an address to be removed from the Foundation
    mapping(address => uint8) public votesToRemove;
    
    // Used to remove votes of excluded Foundation members
    address[] public addressesVotedOn;

    // Current number of Foundation members
    uint8 public numberOfVoters;
    
    // Functionalities only available to Foundation members
    modifier onlyFoundation() {  
        require(isFoundation[msg.sender]);
        _;
    }
    
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
