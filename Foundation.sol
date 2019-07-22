pragma solidity^0.5.0;

// WARNING: Current Chairperson Succession Mechanism is Weak - Do not use in production
contract PresidedByChairperson {
    
    // Chairperson has more permissions than any other address
    address public chairperson;

    // Used to transfer chairperson rights
    address public newChairperson;

    // nextInLine becomes chairperson if chairperson is voted out
    address public nextInLine;

    event LogChairpersonshipTransfer(address indexed _from, address indexed _to);

    // Chairperson has all 'powers' assigned to Foundation members and more
    modifier onlyChairperson {
        require(msg.sender == chairperson);
        _;
    }

    // Appoint new chairperson
    function transferChairpersonship(address _newChairperson) public onlyChairperson {
        newChairperson = _newChairperson;
    }
    
    // Accept chairpersonship
    function acceptChairpersonship() public {
        require(msg.sender == newChairperson);
        emit LogChairpersonshipTransfer(chairperson, newChairperson);
        chairperson = newChairperson;
        newChairperson = address(0);
    }
    
    // Set nextInLine
    function selectNextInLine(address _ad) public {
        require(msg.sender == nextInLine);
        nextInLine = _ad;
    }
    
    
}

// Fluid Consensus model - Foundation is always undergoing election
contract Foundation is PresidedByChairperson {

    // Keeps track of current Foundation members
    mapping(address => bool) private isFoundation;
    
    // Prevents a double-vote to add an address to the Foundation
    mapping(address => mapping(address => bool)) hasVotedToAdd;
    
    // Prevents a double-vote to remove an address to the Foundation
    mapping(address => mapping(address => bool)) hasVotedToRemove;
    
    // Number of votes received by an address to become a part of the Foundation
    mapping(address => uint8) public votesToAdd;
    
    // Number of votes received by an address to be removed from the Foundation
    mapping(address => uint8) public votesToRemove;
    
    // Mechanism keeps track of all addresses that have been voted on
    // This allows for removing the votes of members that are expelled since mappings are not iterable
    address[] public addressesVotedOn;

    // Current number of Foundation members
    uint8 public numberOfVoters;
    
    // Functionalities only available to Foundation members
    modifier onlyFoundation() {  
        require(isFoundation[msg.sender]);
        _;
    }
    
    // Vote to add an address to the foundation
    function voteToAdd(address _ad) external onlyFoundation {
        require(hasVotedToAdd[msg.sender][_ad] == false,
        "Member has already voted to add this address");
        require(!isFoundation[_ad],
        "Address is not already a Foundation member");

        // Prevent address from voting again
        hasVotedToAdd[msg.sender][_ad] = true;

        // Update tracking of distinct addresses undergoing election
        if (votesToAdd[_ad] == uint8(0)) {
            addressesVotedOn.push(_ad);

        // Election process resets after 15 distinct addresses have been voted on
        if (addressesVotedOn.length == 15) {
                reset();
            }
        }
        votesToAdd[_ad]++;
        enoughVotesToAdd(_ad);
    }
    
    // Vote to remove a member of the Foundation
    function voteToRemove(address _ad) external onlyFoundation {
        require(hasVotedToRemove[msg.sender][_ad] == false,
        "Member has already voted to remove this address");
        require(isFoundation[_ad],
        "Address is not a Foundation member");

        // Prevents user from voting again
        hasVotedToRemove[msg.sender][_ad] = true;

        // Update tracking of distinct addresses undergoing election
        if (votesToRemove[_ad] == uint8(0)) {
            addressesVotedOn.push(_ad);
        if (addressesVotedOn.length == 15) {
                reset();
            }
        }
        votesToRemove[_ad]++;
        enoughVotesToRemove(_ad);
    } 
    
    // Remove your vote for a given address - fluid consensus allows for a change of mind
    function removeMyVote(address _ad, uint8 _choice) external onlyFoundation {
        
        // Remove a vote to add a member
        if (_choice == 0) {
            require(hasVotedToAdd[msg.sender][_ad]);
            hasVotedToAdd[msg.sender][_ad] = false;
            votesToAdd[_ad]--;
        }
    
        // Remove your vote to remove a member
        if (_choice == 1) {
            require(hasVotedToRemove[msg.sender][_ad]);
            hasVotedToRemove[msg.sender][_ad] = false;
            votesToRemove[_ad]--;
        }
    }
    
    // If a simple majority is reached after any given vote, add address to Foundation
    function enoughVotesToAdd(address _ad) internal {
        if (votesToAdd[_ad] * 2 > numberOfVoters) {
            numberOfVoters += 1;
            isFoundation[_ad] = true;
        }
        else { }
    }

    // If a simple majority is reached after any given vote, remove address from Foundation
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

    // Informs other contracts who is in the Foundation
    function isAddressInFoundation(address _ad) external view returns(bool) {
        return isFoundation[_ad];
    }
    
    // Resets election process
    function reset() internal {
        for (uint i = 0; i < addressesVotedOn.length; i++) {
            votesToAdd[addressesVotedOn[i]] = 0;
            votesToRemove[addressesVotedOn[i]] = 0;
            delete addressesVotedOn[i];
        }
    }

    // Removes the votes for all addresses a member voted on before being removed from the Foundation
    function removeMemberVotes(address _ad) internal {
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
