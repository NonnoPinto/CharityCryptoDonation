pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

/*
    Charity donation Ethereum smart contract
    Each charity association must ask for at least one project
    A project can be supported by many associations, but it wont be linekd
    Charities and projects are stored with their names
    RULES:
        - no spaces
        - every word starts with capital letter
        - acronym only for most famous assocations
        - e.g. Corce Rossa -> CroceRossa
*/

contract Charity {
    // Smart contract owner 
    address payable owner;
    // Project struct
    struct project{
        string projectName;
        address payable projectAddress;
        uint256 totalDonation;
    }
    // Mapping one charity to many projects
    mapping(string => project[]) charitiesMap;
    // String to better navigate in charities
    string[] charitiesArr;
   
    constructor() public {
        owner = msg.sender;
    }

    // Restricts access only to user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to owner');
        _;
    }

    // --> Helper functions <--
    // Find project index by charity and project name
    // Return project index on success, length otherwise
    function findProject(string memory _charity, string memory _project) internal view returns(uint){
        uint i;
        for (i = 0; i < charitiesMap[_charity].length; i++)
            if ((keccak256(abi.encodePacked(charitiesMap[_charity][i].projectName))) == (keccak256(abi.encodePacked(_project))))
                return i;
        return i;
    }

    // Finda charity index by name
    // Return charity index on success, length otherwise
    /* function findCharity(string memory _charity) public view returns(uint){
        uint i;
        for (i = 0; i < charitiesArr.length; i++)
            if ((keccak256(abi.encodePacked(charitiesArr[i]))) == (keccak256(abi.encodePacked(_charity))))
                return i;
        return i;
    } */

    // Check id charity exist
    modifier validateCharity(string memory _charity){
        /* charitiesMap[_charity] is string[]
        charities are always added with at least one project
        if array's length isnt > 0 it means it does not exist */
        require (charitiesMap[_charity].length > 0, 'Cant find requested charity');
        _;
    }

    // Project validation
    modifier validateProject(string memory _charity, string memory _project){
        // Returned index has to be < length, otherwise for loop has ended without finding it
        require (findProject(_charity, _project) < charitiesMap[_charity].length, 'Cant find requested project');
        _;
    }

    // Validates that the amount to transfer is not zero
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0');
        _;
    }

    // All charities
    function getAllCharities() public view returns(string[] memory){
        return charitiesArr;
    }

    // All _charity's projects
    function getAllProjects(string memory _charity) public view 
    validateCharity(_charity) returns(project[] memory){
        return charitiesMap[_charity];
    }

    // All _project's donations
    function getDonations(string memory _charity, string memory _project) public view
    validateCharity(_charity) validateProject(_charity, _project) returns(uint256) {
        return charitiesMap[_charity][findProject(_charity, _project)].totalDonation;
    }

    // Donation
    function deposit(string memory _charity, string memory _project) public
    validateCharity(_charity) validateProject(_charity, _project) validateTransferAmount() payable {
        uint256 donationAmount = msg.value;
        // Finding project index
        uint proTmp = findProject(_charity, _project);
        // Donating for project
        charitiesMap[_charity][proTmp].projectAddress.transfer(donationAmount);
        // Update total donation
        charitiesMap[_charity][proTmp].totalDonation += donationAmount;
    }

    // Add new project address
    function addCharity(string memory _charity, string memory _projectN, address payable _projectA) public
    restrictToOwner(){
        project memory tmp;
        // Filling struct
        tmp.projectName = _projectN;
        tmp.projectAddress = _projectA;
        tmp.totalDonation = 0;
        // map[id].push() add new key -> value if it's _charity first project
        // add to already existing key otherwise
        charitiesMap[_charity].push(tmp);
        // if its first _charity's project, add to array
        if (charitiesMap[_charity].length == 1)
            charitiesArr.push(_charity);
    }

    // Destroys contract
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }
}