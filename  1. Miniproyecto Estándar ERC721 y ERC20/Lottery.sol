
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Un usuario se registra en el sorteo de lotería comprando tokens ERC20

contract Lottery is ERC20, Ownable{
    address public nft;
    address public winnerAddress;

    // user_contract relaciona la dirección del usuario que compra los tokens con el contrato desplegado
    mapping(address user =>address contrato)user_contract; 

    // relaciona cada usuario con el listado de número de tickets que tiene
    mapping(address user => uint[] ticketIds) user_ticketID;

    // realaciona un número de ticket con su usuario
    mapping(uint ticketId => address ticketOwner) ticketID_user;

    // almacena todos los números de tickets que se han comprado
    uint[] purchasedTickets;

    // Declarar el constructor con nombre y símbolo del token
    constructor() ERC20("ConquerLottery", "CNQ") Ownable(msg.sender) {
       // Minteamos tokens que van a ir a la dirección de este contrato de Lottery
        _mint(address(this), 10000);
        // Desplegamos el contrato de la colección de NFTs dentro de este constructor
        nft = address(new NFTs());
    }

    // Recibe como parámetro el número de tokens que se van a comprar y devuelve el precio total de la compra
    function tokenPrice(uint _numTokens) internal pure returns (uint){
        return _numTokens * 0.5 ether;
    }

    // Para mintear tokens y solo podrá hacerlo el propietario del contrato Lottery
    function mint(uint _numTokens) public onlyOwner {
        _mint(address(this), _numTokens);
    }

    // Registrar usuarios:
    // Cada vez que un usuario compre tokens para comprar tickets de lotería, se va a llamar automáticamente a esta función para registrarlo
    function userRegister() internal{
        // Similar a Factory: Se crea una nueva dirección correspondiente al ticket que se cree en ese momento
        // Para que tenga algún poder de gestión, se despliega un contrato únicamente para él (Ticket)
        address secondContract = address (new Tickets(msg.sender, address(this), nft));
        // Almacenamos en el mapping la dirección del usuario y la que se ha creado para este contrato
        user_contract[msg.sender] = secondContract; 
    }

    // Obtener la información del contrato de un usuario
    function usersInfo (address _user) public view returns(address){
        // Si saliera la dirección 0, significaría que este usuario no tiene tickets de nuestra lotería.
        return user_contract[_user]; 
    }

    // Función para comprar tokens ERC20
    // Se registra un usuario cuando compre tokens ERC20 por primera vez. Hay que asegurarse de que no se registran varias veces
    function buyTokensERC20(uint _numTokens) public payable {
        // Si el usuario no está registrado, al pasar su dirección al mapping, devolverá la address 0
        if(user_contract[msg.sender] == address(0))
        {
            userRegister();
        }

        // Comprobamos que hay tokens suficientes en el contrato para venderlos
        require (balanceOf(address(this))>= _numTokens, "Not enough tokens") ;
        uint price = tokenPrice(_numTokens);

        // Comprobamos que el usuario tiene saldo suficiente para comprar los tokens
        require(msg.value >= price, "Not enough ethers");

        // Calculamos los ethers que le sobran después de su compra
        uint returnValue = msg.value - price; 
        // Le transferimos al usuario los ethers sobrantes
        payable(msg.sender).transfer(returnValue);
        // Le transferimos desde la dirección interna del contrato a la del msg.sender, los tokens que ha comprado
        _transfer(address(this), msg.sender, _numTokens);

    }

    // Precio de cada ticket en número de tokens nuestros
    function ticketPrice() public pure returns (uint) {
        return 2;
    }


    function buyTicket (uint _numTickets) public {
        // precio total = cantidad de tickets por su precio
        uint totalPrice = _numTickets*ticketPrice();

        // comprobar que tiene tickets ERC20 suficientes
        require(balanceOf(msg.sender) >= totalPrice);

        // hacer el pago en tokens ERC20
        _transfer(msg.sender, address(this), totalPrice);

        // Generar los boletos comprados de forma aleatoria
        for (uint i=0; i< _numTickets; i++){
            // generación de número aleatorio menor que 10.000
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i)))%10000;
            
            // Llamamos a Tickets y le pasamos la dirección del contrato del usuario que está ejecutando la función y minteamos el ticket
            Tickets(user_contract[msg.sender]).mintTicket(msg.sender, random);
            
            // Añadimos el nuevo ticket minteado al array de todos los números de tickets
            purchasedTickets.push(random);

            // Asignamos el ticket y el usuario que los ha comprado a los mappings que hemos creado para llevar este control
            ticketID_user[random]=msg.sender;
            user_ticketID[msg.sender].push(random);
        }
    }

    // devuelve los números de ticket que tiene comprados el usuario
    function viewTickets(address _owner) public view returns (uint[]memory ticketsIds){
        return user_ticketID[_owner];
    }

    // Generar el ganador del sorteo de lotería y solo la puede ejecutar el propietario del contrato de lotería
    function generateWinner() public onlyOwner {
        // Comprobaremos que alguien ha comprado boletos
        uint totalPurchasedTickets = purchasedTickets.length;
        require(totalPurchasedTickets > 0, "No tickets purchased");

        // Generamos un número aleatorio entre 0 y el total de números comprados, para que devuelva el índice del array ganador
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp))) % totalPurchasedTickets;

        // El boleto ganador será el correspondiente al índice generado aleatoriamente
        uint winnerTicketId = purchasedTickets[randomIndex];

        // Obtenemos la dirección del usuario propietario del ticket ganador
        winnerAddress = ticketID_user[winnerTicketId];

        // Vamos a darle un premio: el 90% del balance - address(this).balance - en ethers
        payable(winnerAddress).transfer(address(this).balance*90/100);

        // El 10% se lo llevará el owner. No se obtiene el 10% porque ya se envía todo el saldo restante.
        payable(owner()).transfer(address(this).balance);
    }
}

// Este ontrato NFTs se despliega cuando hacemos el despliegue del contrato de lotería, así que el msg.sender es el contrato de lotería
contract NFTs is ERC721 {
    address public lotteryContract;
    constructor() ERC721("ConquerTicket", "TCNQ"){
        lotteryContract = msg.sender;
    }

    // _owner: dirección del propietario del ticket
    // _ticketID: identificador del ticket
    // Se utiliza dentro de mintTickets del contrato Tickets
    function safeMint(address _owner, uint _ticketID) public {
        // Comprobación de seguridad: la función que llame aquí tenga la dirección del contrato de este owner
        // Para acceder a una función de un contrato sin heredar de él:
             // NombreContrato(direccionContrato).funcionALaQueQuieroAcceder.
        require(msg.sender == Lottery(lotteryContract).usersInfo(_owner), "You dont have access");
        _safeMint(_owner, _ticketID);
    } 
}

contract Tickets {
    struct Data {
        address owner; 
        address lotteryContract;
        address NFTContract; 
        address userContract;
    }

    Data public userData;

    constructor(address _owner, address _lotteryContract, address _NFTContract){
        userData = Data (_owner, _lotteryContract, _NFTContract, address(this));
    }

    // Se utiliza cuando compremos un boleto
    function mintTicket(address _owner, uint _ticketID) public {
        // Esta función solo va a poder ser llamada por el contrato Lottery
        require(msg.sender == userData.lotteryContract, "You dont have permissions");
        // Para acceder a una función de un contrato que no pertenece a este y sin heredar de él:
        // NombreContrato(direccionContrato).funcionALaQueQuieroAcceder
        NFTs(userData.NFTContract).safeMint(_owner,_ticketID);
    }
}