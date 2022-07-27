pragma solidity ^0.5.8;

//Charity donation smart contract

contract Charity {
    address payable owner;
    //può essere meglio un mapping?
    address payable[] public charityAddresses; //come fare per i singoli progetti?
    uint256[] public totalDonationsAmount;

    constructor() public {
        owner = msg.sender;
    }

    // Restricts access only to user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to owner');
        _;
    }

    // Validates that the sender originated the transfer is different than the target destination
    // -->mettere slashing?<--
    modifier validateDestination(address payable destinationAddress){
        //not to yout own
        require(msg.sender != destinationAddress, 'Sender and recipient cannot be the same.');
        //to charity in array
        bool find = false;
        for (uint256 i = 0; i < charityAddresses.length; i++)
            if (charityAddresses[i] == destinationAddress)
                find = true;
        require(find, 'Cant find address');
        _;
    }

    // Validates that the amount to transfer is not zero.
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0');
        _;
    }

    // Transmits the address of the donor and the amount donated.
    // -->Questo serve solo per potermi "abbonare" alle donazioni?<--
    event Donation(
        address indexed _donor,
        uint256 _value
    );

    //Donation
    //-->Da capire<--
    function deposit(address payable destinationAddress /*, address payable project  */) public
    validateDestination(destinationAddress) validateTransferAmount() payable {
        /* uint256 donationAmount = msg.value; */
        uint256 donationAmount = msg.value;

        destinationAddress.transfer(donationAmount);

        /* emit Donation(msg.sender, donationAmount); */

        //Non ne vedo la necessità... o sì?
        for (uint256 i = 0; i < charityAddresses.length; i++)
            if (charityAddresses[i]==destinationAddress)
                totalDonationsAmount[i] += donationAmount;

        /* if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = msg.sender;
        } */
    }

    // Add new charity address
    // Verificare che non ci sia già!!
    function addCharity(address payable _charity) public restrictToOwner(){
        charityAddresses.push(_charity);
        totalDonationsAmount.push(0);
    }

    // Add new charity's foundraising
    // -->Come distinguo l'associazione dai suoi progetti?<--
    /* function addFound(address payable _charity, address payable _project) public restrictToOwner(){
        charityAddresses[_charity].push(_project);
    } */

    // Destroys the contract and renders it unusable.
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }
}