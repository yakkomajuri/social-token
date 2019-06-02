contract Owned {

    // CURRENT CHAIRPERSON SUCCESSION SYSTEM IS WEAK - FIX BEFORE USING
    
    // Chairperson has more permissions than any other address
    address public chairperson;
    
    // Used to transfer chairperson rights
    address public newOwner;
    
    // nextInLine becomes chairperson if chairperson is voted out
    address public nextInLine;
    
    
    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor(address _chairperson, address _nextInLine) public {
    
        // Requires that the contract is set-up by a third-party for a more secure/democratic process
        require (msg.sender != _chairperson);
        chairperson = _chairperson;
        nextInLine = _nextInLine;
    }

    modifier onlyChairperson {
        require(msg.sender == chairperson);
        _;
    }

    // Appoint new chairperson
    function transferOwnership(address _newOwner) public onlyChairperson {
        newOwner = _newOwner;
    }
    
    
    // Accept chairpersonship
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(chairperson, newOwner);
        chairperson = newOwner;
        newOwner = address(0);
    }
    
    // Set nextInLine
    function selectNextInLine(address _ad) public {
        require(msg.sender == nextInLine);
        nextInLine = _ad;
    }
    
    
}

contract Foundation is Owned {
    
    // FLUID ELECTION MODEL - FOUNDATION IS ALWAYS UNDERGOING SIMPLE MAJORITY ELECTIONS
    
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
    
    // Mechanism keeps track of all addresses that have been voted on
    // This allows for removing the votes of members that are expelled since mappings are not iterable
    address[] public addressesVotedOn;

    uint8 public numberOfVoters;
    
    // Vote to add an address to the foundation
    function voteToAdd(address _ad) public onlyFoundation {
    
        // msg.sender must not have voted to add this address yet
        require(hasVotedToAdd[msg.sender][_ad] == false);
        
        // Address to be added must not already be part of the foundation
        require(isFoundation[_ad] == false);
        
        // Prevent user from voting again
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
    function voteToRemove(address _ad) public onlyFoundation {
    
        // msg.sender must not have voted to remove this address yet
        require(hasVotedToRemove[msg.sender][_ad] == false);
        
        // Address to be removed must already be part of the foundation
        require(isFoundation[_ad]);
        
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
    
    // Remove your vote for a given address - fluid election allows for mind changes
    function removeMyVote(address _ad, uint8 _choice) public onlyFoundation {
    
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
            removeMemberVotes(_ad);
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
    function isFoundationMember(address _ad) external view returns(bool) {
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
