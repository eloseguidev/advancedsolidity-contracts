// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract ConquerERC1155 is ERC1155Supply, Ownable{
    uint price = 0.05 ether;
    uint whiteListPrice = 0.02 ether;
    
    // Solo vamos a poder mintear un token para cada id
    uint maxSupply = 1;

    bool public whiteListStatus = true;

    mapping (address account => bool) public  whiteListMembers;

    constructor() Ownable(msg.sender) ERC1155("https://token-cdn-domain/"){}

    function uri(uint id) public view virtual override returns (string memory){
        // Comprobaremos que este id existe
        require(exists(id), "Nonexistent token");
        return string(abi.encodePacked(super.uri(id), Strings.toString(id), ".json"));
    }

    function whiteListMint(uint id) public payable {
        // Vamos a comprobar que el estado de la whitelist es true
        require(whiteListStatus, "White list is closed");
        require (whiteListMembers[msg.sender], "You are not allowed");

        mint(id);
    }

    function estandarMint(uint id) public payable {
        // No se puede mintear con este método porque la whitelist está abierta
        require(!whiteListStatus, "White list is opened");
        mint(id);
    }

    function mint (uint id) internal {
        uint applicablePrice = whiteListStatus ? whiteListPrice : price;
        // Vamos a comprobar que la persona que ejecuta esta función tiene fondos suficientes
        // Vamos a permitir que solo se mintee un token
        require(msg.value >= applicablePrice, "Not enough ethers");

        // Comprobamos si hemos llegado al tope de los tokens que podíamos mintear
        require(totalSupply(id) + 1 <= maxSupply, "Minted out");

        _mint(msg.sender, id, 1, "");

        // Devolver lo que sobra del msg.value a la persona que está comprando
        uint remainder = msg.value - applicablePrice;
        payable(msg.sender).transfer(remainder);
    }

    function mintBatch(uint[] memory ids, uint[] memory amounts) public payable {
        // No se puede mintear con este método porque la whitelist está abierta
        require(!whiteListStatus, "White list is opened");
        // Comprobemos que el que está ejecutando la función tiene suficiente dinero para mintear todos los tokens
        uint totalPrice;
        for (uint i = 0; i < ids.length; i++) 
        {
            totalPrice += amounts[i];
        }
        require(msg.value >= totalPrice, "Not enough ethers");

        // Comprobar que todos los identificadores no hayan alcanzado el total suply
        for (uint i = 0; i < ids.length; i++) 
        {
            require (totalSupply(ids[i]) + amounts[i] <= maxSupply, "Minted out");
        }

        require(msg.value >= totalPrice, "Not enough ethers");
        _mintBatch(msg.sender, ids, amounts, "");

        // Devolver lo que sobra del msg.value a la persona que está minteando
        uint remainder = msg.value - totalPrice;
        payable(msg.sender).transfer(remainder);
    }

    // Se añade la lista de miembros del address[] a la whitelist 
    function addMembers(address[] memory members) external onlyOwner{
        for (uint i = 0; i < members.length; i++) 
        {
            whiteListMembers[members[i]] = true;
        }
    }

    // El propietario puede modificar el estado de la white list
    function changeWhiteListStatus (bool status) external onlyOwner {
        whiteListStatus = status;
    }

    // Para que el owner pueda retirar los beneficios del contrato
    function withdraw () external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}