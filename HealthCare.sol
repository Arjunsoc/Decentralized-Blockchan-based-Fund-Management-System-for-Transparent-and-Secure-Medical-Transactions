// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HealthCareStore is Ownable {

    constructor(address initialOwner) Ownable(initialOwner) {}

    uint public pidCount;
    uint public withdrawCount;
    uint public doctorCount;
    uint public donorCount;
    uint public donationTransferCount;

    struct Patient {
        uint256 time;
        uint256 insuranceAmount;
        uint256 donatedAmount;
        string name;
        string disease;
        string doctorName;
        string ipfsHash;
        address doctorAddress;
        address patientID;
        bool pidAvailable;
        bool doctorSignature;
    }

    struct Doctor {
        address docAdress;
        string docName;
        string docSpecialization;
    }

    struct withdrawHistory {
        address pid;
        string doctorName;
        uint256 time;
        uint256 amount;
        string patientName;
    }

    struct donationHistory {
        address pid;
        address donorAddress;
        uint256 time;
        uint256 amount;
        string patientName;
    }

    struct donationTransferHistory {
        address pid;
        uint256 time;
        uint256 amount;
        string patientName;
    }

    event newPatientCreated(string name, address pid, uint256 insuredAmount);
    event usedInsurance(address pid, uint256 amount);
    event receivedDonation(address indexed donor, address pid, uint256 amountReceived);

    mapping(address => bool) public doctorList;
    mapping(address => uint256) public donorList;
    mapping(uint => address) public pidList;
    mapping(uint => address) public docAddressList;
    mapping(address => Patient) public patientList;
    mapping(address => Doctor) public doctorDetailList;
    mapping(uint => donationHistory) public donationHistoryList;
    mapping(uint => withdrawHistory) public withdrawHistoryList;
    mapping(uint => donationTransferHistory) public donationTransferList;

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // DOCTOR FUNCTIONS
    function setDoctor(address _docAddress, string memory _name, string memory _spec) public onlyOwner {
        require(!doctorList[_docAddress]);
        doctorList[_docAddress] = true;
        doctorDetailList[_docAddress] = Doctor(_docAddress, _name, _spec);
        doctorCount++;
        docAddressList[doctorCount] = _docAddress;
    }

    function doctorSign(address _pid) public {
        require(doctorList[msg.sender]);
        patientList[_pid].doctorSignature = true;
        patientList[_pid].doctorAddress = msg.sender;
        patientList[_pid].doctorName = doctorDetailList[msg.sender].docName;
    }

    // PATIENT FUNCTIONS
    function setPatientData(string memory _name, string memory _disease, string memory _ipfsHash) public payable onlyOwner {
        address pid = address(bytes20(keccak256(abi.encodePacked(msg.sender, block.timestamp))));
        patientList[pid] = Patient(block.timestamp, msg.value, 0, _name, _disease, ' ', _ipfsHash, address(0), pid, true, false);
        pidCount++;
        pidList[pidCount] = pid;
        emit newPatientCreated(_name, pid, msg.value);
    }

    // INSURANCE AMOUNT FUNCTION
    function withdrawInsurance(address _pid, uint256 _amountRequired) public {
        require(doctorList[msg.sender]);
        require(patientList[_pid].doctorAddress == msg.sender);
        require(patientList[_pid].insuranceAmount >= _amountRequired);

        address payable recepientDoctor = payable(msg.sender);
        patientList[_pid].insuranceAmount -= _amountRequired;
        withdrawCount++;
        withdrawHistoryList[withdrawCount] = withdrawHistory(_pid, patientList[_pid].doctorName, block.timestamp, _amountRequired, patientList[_pid].name);
        recepientDoctor.transfer(_amountRequired);
        emit usedInsurance(_pid, _amountRequired);
    }

    // DONOR FUNCTION
    function donateAmount(address _pid) public payable {
        require(msg.sender.balance >= msg.value);
        patientList[_pid].donatedAmount = msg.value;
        donorList[msg.sender] = msg.value;
        donorCount++;
        donationHistoryList[donorCount] = donationHistory(_pid, msg.sender, block.timestamp, msg.value, patientList[_pid].name);
        emit receivedDonation(msg.sender, _pid, msg.value);
    }

    function transferDonations(address _pid, uint256 _amountRequired) public onlyOwner {
        patientList[_pid].donatedAmount -= _amountRequired;
        patientList[_pid].insuranceAmount += _amountRequired;
        donationTransferCount++;
        donationTransferList[donationTransferCount] = donationTransferHistory(_pid, block.timestamp, _amountRequired, patientList[_pid].name);
    }
}
