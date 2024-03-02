// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// importamos contrato ReentrancyGuard para evitarun ataque por reentrancia
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MarketPlace20 is ReentrancyGuard{
    // Dirección que va a recibir las comisiones por utilizar este marketplace cada vez que se venda un NFT
    // immutable: una vez que se de un valor a esta variable, no podrá cambiar
    address payable public immutable feeAccount;
    uint public immutable feePercent;

    uint public tokenCount;

    // struct con las características de cada NFT
    struct Token {
        // Identificador del token dentro de este MarketPlace
        uint tokenId;
        IERC721 nft;
        // Identificador del token dentro de una colección
        uint nftId;
        uint price;
        // Dirección de la persona que está poniendo en venta este token
        address payable seller;
        // Indicar si el token se ha vendido o no
        bool sold;
    }

    // mapping para almacenarlo todo
    mapping (uint => Token) public tokens;

    // Se lanzará cada vez que se ofrezca a la venta un NFT
    // Indexed: podremos buscar luego por esa dirección
    event Offered(uint tokenId, address indexed nft, uint nftId, uint price, address indexed seller);

    // Se emitirá cuando se compre un NFT
    event Bought(uint tokenId, address indexed nft, uint nftId, address indexed seller, address indexed buyer);

    constructor (uint _feePercent) {
        // La persona que despliegue el contrato decidirá qué porcentaje se va a llevar de cada cosa
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    // Función para poner a la venta un nft. Protegida de ataque por reentrancia
    // price en ethers
    function offerToken(IERC721 nft, uint nftId, uint price) external nonReentrant {
        // Algunas comprobaciones de seguridad
        require(price > 0, "Invalid price");
        tokenCount++;

        // Cedemos nuestro NFT a este contrato inteligente para que lo venda
        // se hace un transferFrom por motivos de seguridad
        // Lo vamos a hacer de tal forma que el vendedor no pueda echarse para atrás

        nft.transferFrom(msg.sender, address(this), nftId);

        // instroducimos este nuevo nft ofertado, en el mapping de tokens
        tokens[tokenCount] = Token(tokenCount, nft, nftId, price, payable(msg.sender), false);

        // emitimos el evento de offer
        emit Offered(tokenCount, address(nft), nftId, price, msg.sender);
    }

    // Función que nos da el precio de cada NFT incrementando al valor inicial el porcentaje que se lleva el marketplace
    function getPrice(uint tokenId) view public returns(uint){
        return ((tokens[tokenId].price * (100 + feePercent)) / 100);
    }

    // Función comprar NFT
    function purchaseToken(uint tokenId) external payable nonReentrant {
        // Comprobaciones de seguridad
        require(tokenId > 0 && tokenId <= tokenCount, "Non exists");

        uint totalPrice = getPrice(tokenId);
        // Comprobamos que el comprador tiene saldo
        require(msg.value >= totalPrice, "Insufficient ethers");

        // Vamos a extraer la información de este token, porque tenemos que comprobar que está a la venta
        Token storage saleToken = tokens[tokenId];
        require(!saleToken.sold);

        // Vamos a transferir los ethers
        saleToken.seller.transfer(saleToken.price); //msg.sender le transfiere los ethers al seller

        // Vamos a transferir las fees al propietario del contrato (el marketplace, el owner)
        feeAccount.transfer(totalPrice - saleToken.price);

        // Marcamos el token como vendido
        saleToken.sold = true;

        // Una vez se han transferido los ethers, accedemos al contrato y transferimos el nft al comprador
        saleToken.nft.transferFrom(address(this), msg.sender, saleToken.nftId);

        emit Bought(saleToken.tokenId, address(saleToken.nft), saleToken.nftId, saleToken.seller, msg.sender);
    }
}