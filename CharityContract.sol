pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

/*
    Charity donation Ethereum smart contract
    Each charity association must ask for at least one project
    A project can be supported by many associations, but it wont be linekd
    Charities and projects are stored with their name and address
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
        string name;
        address payable addr;
        uint256 totalDonation;
    }
    // Charity mapping
    mapping(string => address) charityToAddr;
    mapping(address => string) addrToCharity;
    // Charities array, frontend porpouse
    string[] charitiesArr;
    // Mapping one charity to many projects
    // !!Cannot have udt as key value!!
    mapping(string => project[]) charitiesMap;
   
    constructor() public {
        owner = msg.sender;
    }

    // Restricts access only to user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to owner');
        _;
    }

    // Check if access address is charity owner
    modifier restrictToAdmin(){
        string memory charityN = findCharity();
        require (bytes(charityN).length != 0, 'You are not an already known charity association');
        _;
    }

    // --> Helper functions <--

    // Find project index by charity and project name
    // Return project index on success, full length otherwise
    function findProject(string memory _charity, string memory _project) internal view returns(uint){
        uint i;
        for (i = 0; i < charitiesMap[_charity].length; i++)
            if ((keccak256(abi.encodePacked(charitiesMap[_charity][i].name))) == (keccak256(abi.encodePacked(_project))))
                return i;
        return i;
    }

    // Find project index by charity name and project address
    // Return project index on success, full length otherwise
    function findProjectAddr(string memory _charity, address payable _project) internal view returns(uint){
        uint i;
        for (i = 0; i < charitiesMap[_charity].length; i++)
            if (charitiesMap[_charity][i].addr == _project)
                return i;
        return i;
    }

    // Find charity index by address
    // Return charity name on success, empty string otherwise
    function findCharity() public view returns(string memory){
        return(addrToCharity[msg.sender]);
    }

    // Check id charity exist
    // Non so se funziona
    modifier validateCharity(string memory _charity){
        /* charitiesMap[_charity] key is project[]
        Charities are always added with at least one project
        If array's length isnt > 0 it means it does not exist */
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
        // Return an array of struct, ts pipe will do his job
        return charitiesMap[_charity];
    }

    // All _project's donations
    function getDonations(string memory _charity, string memory _project) public view
    validateCharity(_charity) validateProject(_charity, _project) returns(uint256) {
        return charitiesMap[_charity][findProject(_charity, _project)].totalDonation;
    }

    // Donation
    function donate(string memory _charity, string memory _project) public
    validateCharity(_charity) validateProject(_charity, _project) validateTransferAmount() payable {
        uint256 donationAmount = msg.value;
        // Finding project index
        uint proTmp = findProject(_charity, _project);
        // Donating to project
        charitiesMap[_charity][proTmp].addr.transfer(donationAmount);
        // Update total donation
        charitiesMap[_charity][proTmp].totalDonation += donationAmount;
    }

    // Add new charity
    function addCharity(string memory _charity, address _charityAddr, string memory _project, address payable _projectAddr) public
    restrictToOwner() {
        // Filling struct
        project memory tmp;
        tmp.name = _project;
        tmp.addr = _projectAddr;
        tmp.totalDonation = 0;
        // map[id].push() add new key -> value
        charitiesMap[_charity].push(tmp);
        // its first _charity's project, add to mapping
        charityToAddr[_charity] = _charityAddr;
        addrToCharity[_charityAddr] = _charity;
        charitiesArr.push(_charity);
    }

    // Add new project address
    function addProject(string memory _project, address payable _projectAddr) public
    restrictToAdmin() {
        string memory charityN = findCharity();
        // Check if charity is reusing an address (cant have different project with same address) or a name
        require(findProjectAddr(charityN, _projectAddr) == charitiesMap[charityN].length, 'You\'ve already used this address');
        require(findProject(charityN, _project) == charitiesMap[charityN].length, 'You\'ve already used this name');
        // Filling struct
        project memory tmp;
        tmp.name = _project;
        tmp.addr = _projectAddr;
        tmp.totalDonation = 0;
        // map[id].push() add new project
        charitiesMap[charityN].push(tmp);
    }

    // Destroys contract
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }
}