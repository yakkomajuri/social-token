pragma solidity^0.5.0;

contract Foundation is Owned {
    
    modifier onlyFoundation() {  
        require(isFoundation[msg.sender]);
        _;
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
