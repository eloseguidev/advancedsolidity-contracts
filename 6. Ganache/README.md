# Guion de la clase de instalación y uso de Ganache
## Descarga e instalación de Ganache cli
- Buscar en google: ganache cli
	+ https://www.npmjs.com/package/ganache-cli
	+ ganache cli es un cliente en la terminal y tenemos que tener nodejs y npm instalados
- Vamos a la página de nodejs e instalamos la última versión estable, no la más reciente
	+ este instalable instala tanto nodejs como npm

- Para comprobar si se ha instalado bien, abrimos la terminal:
	+ node -v y si sale la versión es que está instalado bien
	+ npm -v

- Ahora que tenemos ambos instalados, podemos instalar ganache cli
	- sudo npm install ganache --global
	- clear limpiamos la terminal
	
## Ejecutar Ganache en la terminal
- Arrancamos ganache desde la terminal
	+ escribir ganache en la terminal, esto arranca el cliente
	+ es una blockchain local que se ha creado al ejecutar el comando ganache
	+ se ve que hay una batería de cuentas con 1000  con sus respectivas claves privadas y la frase semilla de la cartera de las 12 cuentas
	+ también tenemos el Chain Id
	+ Dirección IP de esta red local y el puerto que está escuchando al que se conecta el cliente ganache
	+ ganache nos permite probar aplicaciones descentralizadas, no solo contratos inteligentes
	+ ganache también nos permite hacerlo de forma más gráfica con interfaz de usuario
## Instalar y utilizar la interfaz gráfica de Ganache
- Instalamos la interfaz gráfica de ganache
	+ https://archive.trufflesuite.com/ganache/
	+ Los mismos datos que hemos visto en la consola lo vemos en la interfaz gráfica aunque el puerto es diferente
		- Blocks simula los bloques que se van minando en nuestra red local
		- Se verás las transacciones que van teniendo lugar
		- Logs
	+ Esta aplicación nos permite crear workspaces. Vamos a crear uno
- Creamos un workspace:
	+ nombre: Conquer
	+ Los proyectos de truffle los veremos más adelante
	+ En la pestaña de server no hace falta modificar nada
	+ Accounts & keys: para indicar el balance inicial de cada cuenta y cuántas cuentas. Permite cambiar mnemonic pero no hace falta.
	+ En Chain y Advanced no modificar nada
	+ En Advanced, podemos indicar que se vuelquen los logs a un fichero físico
	+ Start y con esto ya tendríamos nuestra blockchain local montada

- Hacemos un contrato en remix para probarlo
	+ Compilar
	+ Publicar cambiando el Environment:
		- Dev - Ganache Provider
		- Indicar el puerto que nos ha dado ganache gráfico
		- Se indican las 10 cuentas en remix pero de 600 eth cada una
		- Si da un error de gas en remix al probar, cambiar la versión del compilador a la 0.8.19
		- Se prueba el contraro en remix igual que hasta ahora
		- La misma prueba se puede hacer con el cliente de la terminal

## Unir Ganache y Metamask
- Vamos a unir ganache con metamask
	+ En metamask, agregar una red manualmente:
		- Nombre: Ganache
		- URL: la del RCP server de ganache
		- Identificador de cadena: Network Id
		- Símbolo de la moneda: ETH
		- Importamos una de las cuentas a metamask:
			· Importar cuenta y para esto sirve la clave privada

- Vamos a probar ganache con metamask
	+ Compilamos
	+ Desplegamos utilizando injected provider
	+ Hacer las pruebas en remix y se interactúa con metamask