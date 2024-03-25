// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract MultisigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTx(address indexed owner, uint indexed txId, address indexed to, uint value, bytes data);
    event ConfirmTx(address indexed owner, uint indexed txId);
    event ExecutedTx(address indexed owner, uint indexed txId);
    event RevokeConfirmation(address indexed  owner, uint indexed txId);

    // Almacenar los propietarios de la cartera
    address[] public owners;
    
    // mapping de direcciones que almacenará si una dirección es de owner o no
    // se hace así porque es más óptimo en términos de gas buscar en un mapping que en un array
    mapping (address => bool) isOwner;

    // Número de confirmaciones mínimo para que se lleve a cabo la transacción
    uint public numConfirmations;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numberConfirmations;
    }

    // array que contendrá todas las transacciones
    Transaction[] public transactions;

    // Modificadores
    // Comprobar que ejecuta alguno de los propietarios de la cartera
    modifier onlyOwner(){
        require(isOwner[msg.sender], "You are not owner");
        _;
    }

    // Comprobar que existe la transacción
    modifier txExists(uint txId){
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    // Comprobar que la transacción no ha sido ya confirmada
    modifier txNotConfirmed(uint txId){
        require(!isConfirmed[txId][msg.sender], "Transaction already confirmed");
        _;
    }

    // Comprobar que la transacción no ha sido ejecutada
    modifier txNotExecuted(uint txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    // mapping con id de la transacción, dirección que confirma y booleano que indica que está confirmada
    // TODO: revisar porque si en este mapping solo se almacenan los confirmados, ¿qué aporta el bool?
    mapping (uint id => mapping (address initTx => bool confirmed)) isConfirmed;



    constructor(address[] memory owners_, uint numConfirmations_) payable {
        require(owners_.length > 0, "owners required");
        require(numConfirmations_ > 0 && numConfirmations_ <= owners_.length, "invalid number of require confirmations");

        // recorrremos el array de propietarios para comprobar varias cosas
        for (uint i = 0; i < owners_.length; i++) 
        {
            address owner = owners_[i];

            // no puede ser la dirección cero
            require(owner != address(0), "invalid owner");

            // no se puede añadir dos veces a un mismo propietario
            require(!isOwner[owner], "owner is not unique");

            // si cumple todas las condiciones, lo añadimos tanto al mapping como al array
            owners.push(owner);
            isOwner[owner] = true;
        }
        numConfirmations = numConfirmations_;
    }

    // se ejecuta automáticamente cuando el contrato recibe ethers

    receive () external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // solo puede ser ejecutada por los propietarios de la cartera, y no podemos usar Ownable de OpenZeppelin porque está pensado para un solo propietario
    function submitTx(address to, uint value, bytes memory data) public onlyOwner{
        uint transactionId = transactions.length;
        transactions.push(Transaction(to, value, data, false, 0));

        emit SubmitTx(msg.sender, transactionId, to, value, data);
    }

    // A la función confirmTx pueden llamar solo los propietarios de la cartera multifirma.
    // Cuando uno de los propietarios ejecuta esta función, aumentaremos en una unidad el número de confirmaciones de la tx
    // método para confirmar la transacción
    // utilizaremos los modificadores pertinentes para comprobar que la transacción existe, no está confirmada ni ejecutada
    function confirmTx(uint txId) public onlyOwner txExists(txId) txNotConfirmed(txId) txNotExecuted(txId) { 
        // Esta es la transacción que estamos intentando confirmar
        Transaction storage txn = transactions[txId]; // de tipo storage para que se almacene el valor de la variable y no se elimine cuando salgamos de la función
        txn.numberConfirmations++;

        // vamos a indicar que el propietario msg.sender nos ha confirmado la transacción
        isConfirmed[txId][msg.sender] = true;

        // emitimos el evento de confirmación de transacciones
        emit ConfirmTx(msg.sender, txId);
    }

    // Ejercutar la transacción
    // Comprobamos que la tx existe y no ha sido ejecutada
    function executeTx(uint txId) public onlyOwner txExists(txId) txNotExecuted(txId) {
        Transaction storage txn = transactions[txId]; // tipo storage para que lo que hagamos dentro e esta variable se guarde en la BC

        require(txn.numberConfirmations >= numConfirmations, "Cannot execute transaction. Not enough confirmations");
        txn.executed = true;

        // Vamos a realizar la transacción propiamente dicha con la función call que devuelve un bool que dice el estado y una variable de tipo data
        (bool success, ) = txn.to.call {value: txn.value} (
            txn.data
        );

        require(success, "Transaction failed");
        // Si la transacción ha ido correctamente, emitimos el evento
        emit ExecutedTx(msg.sender, txId);
    }

    // Funcion para revocar una confirmación que hemos aceptado previamente
    // Sólo se podrá revocar si la transacción no ha sido ya ejecutada
    function revokeConfirmation(uint txId) public onlyOwner txExists(txId) txNotExecuted(txId) {
        Transaction storage txn = transactions[txId];
        require(isConfirmed[txId][msg.sender], "Transaction is not confirmed");

        txn.numberConfirmations--;
        isConfirmed[txId][msg.sender] = false;   

        // emitimos evento para que se entere la blockchain
        emit RevokeConfirmation(msg.sender, txId);    
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint txId) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirm){
        Transaction memory txn = transactions[txId]; // en el vídeo pone storage pero dudo que sea necesario porque no hace falta que quede en la BC
        return (txn.to, txn.value, txn.data, txn.executed, txn.numberConfirmations);
    }
}