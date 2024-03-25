// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract MultisigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTx(
        address indexed owner,
        uint indexed txID, 
        address indexed to, 
        uint value, 
        bytes data
    );

    event ConfirmTx(address indexed owner, uint indexed txID);
    event ExecuteTx(address indexed owner, uint indexed txID);
    event RevokeConfirmation(address indexed owner, uint indexed txID);

    address[] public owners;
    mapping(address=>bool) isOwner;
    uint public numConfirmations;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numberConfirmations;
    }
    
    mapping(uint=> mapping(address=>bool)) public isConfirmed;
    Transaction [] public transactions; 

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not owner");
        _;
    }

    modifier txExists(uint _txID) {
        require(_txID<transactions.length, "Transaction does not exist");
        _;
    }

    modifier notConfirmed (uint _txID) {
        require(!isConfirmed[_txID][msg.sender], "Transaction already confirmed");
        _;
    }

    modifier notExecuted(uint _txID) {
        require(!transactions[_txID].executed, "Transaction already executed");
        _;
    }


    constructor(address[] memory _owners, uint _numConfirmatios) payable {
        require(_owners.length > 0, "owners required");

        require(_numConfirmatios >0 && _numConfirmatios<=_owners.length, 
        "invalid number of required confirmations"); 

        for(uint i = 0; i<_owners.length;i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmations = _numConfirmatios;
    }

    receive () external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }


    function submitTx (
        address _to, 
        uint _value, 
        bytes memory _data
        )  public onlyOwner {
        uint _transactionID = transactions.length;

        transactions.push(
            Transaction(
            _to, 
            _value, 
            _data, 
            false, 
            0));

        emit SubmitTx(msg.sender, _transactionID, _to, _value, _data);
    }

    function confirmTx(
        uint _txID
    ) public onlyOwner txExists(_txID) notConfirmed(_txID) notExecuted(_txID){
        Transaction storage transaction = transactions[_txID];
        transaction.numberConfirmations+=1;
        isConfirmed[_txID][msg.sender] = true; 

        emit ConfirmTx(msg.sender, _txID);
    }

    function executeTx(
        uint _txID
    ) public onlyOwner txExists(_txID) notExecuted(_txID){
        Transaction storage transaction = transactions[_txID];

        require(transaction.numberConfirmations >= numConfirmations, "Cannot execute transaction");
        transaction.executed = true; 

        (bool success, ) = transaction.to.call {value: transaction.value}(
            transaction.data
        ); 

        require(success, "Transaction failed");
        
        emit ExecuteTx(msg.sender, _txID);
    }

    function revokeConfirmation(
        uint _txID
    ) public onlyOwner txExists(_txID) notExecuted(_txID) {
        Transaction storage transaction = transactions[_txID];

        require(isConfirmed[_txID][msg.sender], "Transaction is not confirmed");

        transaction.numberConfirmations -=1;
        isConfirmed[_txID][msg.sender] = false;
         
        emit RevokeConfirmation(msg.sender, _txID);
    }

    function getOwners() public view returns (address []memory){
        return owners;
    }

    function getTransactionCount() public view returns (uint){
        return transactions.length;
    }

    function getTransaction(
        uint _txID
    ) 
        public 
        view 
        returns (
            address to, 
            uint value, 
            bytes memory data, 
            bool executed, 
            uint numberConfirmations)
    {
        Transaction storage transaction = transactions[_txID];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numberConfirmations
        );
    }



}