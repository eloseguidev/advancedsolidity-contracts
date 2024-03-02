// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    // Representa el número de tokens que se van emitiendo
    uint public count;

    constructor() ERC721("Conquer NFTs", "CNFT")
    {}

    // Cada persona que ejecute esta función, va a mintear un NFT
    function mint(string memory tokenUri) external returns (uint){
        // Estamos emitiendo un token nuevo, así que aumentamos el contador
        count++;
        
        
        // Llamamos a la función safeMint del contrato ERC721 
        _safeMint(msg.sender, count); // count como identificador del token

        _setTokenURI(count, tokenUri); // identificador, uri

        return count;
    }
}