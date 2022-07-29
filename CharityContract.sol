pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

//Charity donation smart contract

contract Charity {
    address payable owner;
    struct project{
        string projectName;
        address payable projectAddress;
        uint256 totalDonation;
    }
    //e se, arrivati a far inserire, la gente scrive in modo diverso??
    mapping(string => project[]) charitiesMap;
    string[] charitiesArr;
   
    constructor() public {
        owner = msg.sender;
    }

    // Restricts access only to user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to owner');
        _;
    }

    // Helper functions
    // Return project index on success, length otherwise
    function findProject(string memory _charity, string memory _project) internal view returns(uint){
        uint i;
        for (i = 0; i < charitiesMap[_charity].length; i++)
            if ((keccak256(abi.encodePacked(charitiesMap[_charity][i].projectName))) == (keccak256(abi.encodePacked(_project))))
                return i;
        return i;
    }

    // Return charity index on success, length otherwise
    /* function findCharity(string memory _charity) public view returns(uint){
        uint i;
        for (i = 0; i < charitiesArr.length; i++)
            if ((keccak256(abi.encodePacked(charitiesArr[i]))) == (keccak256(abi.encodePacked(_charity))))
                return i;
        return i;
    } */

    // Charity validation
    // Non credo serva davvero
    modifier validateCharity(string memory _charity){
        require (charitiesMap[_charity].length > 0, 'Cant find requested charity');
        _;
    }

    // Project validation
    modifier validateProject(string memory _charity, string memory _project){
        require (findProject(_charity, _project) < charitiesMap[_charity].length, 'Cant find requested project');
        _;
    }

    // Validates that the amount to transfer is not zero.
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0');
        _;
    }

    // All charities
    // Mi serve davvero?
    function getAllCharities() public view returns(string[] memory){
        return charitiesArr;
    }

    // All projects
    function getAllProjects(string memory _charity) public view 
    validateCharity(_charity) returns(project[] memory){
        return charitiesMap[_charity];
    }

    // All donations
    function getDonations(string memory _charity, string memory _project) public view
    validateCharity(_charity) validateProject(_charity, _project) returns(uint256) {
        return charitiesMap[_charity][findProject(_charity, _project)].totalDonation;
    }

    //Donation
    function deposit(string memory _charity, string memory _project) public
    validateCharity(_charity) validateProject(_charity, _project) validateTransferAmount() payable {
        uint256 donationAmount = msg.value;
        uint proTmp = findProject(_charity, _project);

        charitiesMap[_charity][proTmp].projectAddress.transfer(donationAmount);

        charitiesMap[_charity][proTmp].totalDonation += donationAmount;
    }

    // Add new charity address
    function addCharity(string memory _charity, string memory _projectN, address payable _projectA) public
    restrictToOwner(){
        // Preparo l'oggetto
        project memory tmp;
        tmp.projectName = _projectN;
        tmp.projectAddress = _projectA;
        tmp.totalDonation = 0;
        // Usando push se esiste
        charitiesMap[_charity].push(tmp);
        if (charitiesMap[_charity].length == 1)
            charitiesArr.push(_charity);
    }

    // Destroys the contract and renders it unusable.
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }
}