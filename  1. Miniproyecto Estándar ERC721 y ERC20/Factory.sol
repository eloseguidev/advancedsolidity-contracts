//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Fabrica de smartcontracts
// Útil por ejemplo en caso de una aseguradora. Cada tomador de seguro tendría su propio SC a su nombre y pudiera gestionar la póliza y los servicios suscritos.
contract Factory {
    mapping (address =>address) public user_contract;

    
    function factory() public  {
        address secondContract = address (new Contrato(msg.sender, address(this)));
        
        /// Devuelve la dirección del contrato que se ha desplegado para la dirección indicada
        user_contract[msg.sender] = secondContract;
    }
}

contract Contrato {
    struct Datos {
        address owner;
        address padre;
    }

    Datos public datos;
    constructor(address _owner, address _padre){
        datos.owner = _owner;
        datos.padre = _padre;
    }
}