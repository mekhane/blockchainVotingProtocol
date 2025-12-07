Implementing a Voting System on the Feathercoin (FTC) Blockchain

This development is based on the paper published on this blog titled "Blockchain Voting Strategy." Please refer to this document for more information on this idea: https://habican.blogspot.com/2015/07/estrategia-de-voto-en-la-cadena-de.html For a demonstration example, visit https://habican.blogspot.com/2025/11/implentacion-de-voto-sobre-cadena-de.html

Download the necessary software from https://github.com/FeatherCoin/Feathercoin/releases/tag/v0.19.1.1 and place it in the same folder as our files. Install the required dependencies if you don't already have them installed.

0. The first step is to create a wallet for voting. You'll find it very easy to do this in feathercoin-qt, the core graphical interface for this cryptocurrency.

The name of this wallet—in our example—is "votingWallet," and you will need to have sufficient funds to send the transactions. Encrypt the wallet if you want to prevent it from being emptied if someone or something were to access your local .dat file on your computer. The cost of voting will be the transaction fees, as the funds are returned to the wallet once the voting is complete, leaving the entries on the blockchain as the official record of the results. The correlation between the questions and answers is the result displayed.

We will only ask one question per program run, with multiple possible answers and multiple unique voters. The rule is one vote per person.

1. Go to the folder where the program is located, for example:

cd /home/username/votingFTC/

You will need two terminals if you want to view the information of the running node. The contents, along with the program to start the Feathercoin node, include the following files:

generate_graphs.py, vote_protocol.sh, and unlock_wallet.py

Download these files here, and the necessary files from the repository linked above. Place them in the same folder.

2. Now, start a Feathercoin node in one of the terminals that indexes transactions in the memory pool using the command:

./feathercoind -txindex=1

and load your wallet:

./feathercoin-cli loadwallet "votingWallet"

Now we must wait for our node to synchronize. If this is the first time you are starting the node, you will have to wait a long time.

We are now ready to begin once the node is synchronized. Now we will run a Python script that allows you to unlock your wallet for the time you specify; the default is 10 minutes.

python3 unlock_wallet.py

Enter your chosen wallet password and we'll run the following script to start the protocol. Let the voting begin!

./vote_protocol.sh

Now we need to enter the question, the possible answers (in quotes if they include spaces), and the number of voters. If invalid votes are anticipated, it's advisable to specify that option here as well.

Now we wait a little over a minute for the transactions with the necessary information for the consultation to propagate. At this point, funds are allocated so that each address can cast its vote, and the addresses representing the answers to the question are prepared.

Once the wait is over, the voting begins. Now people must vote in turn. If necessary, physical ballots should be placed in a ballot box, and then the analog consultation is uploaded to the blockchain.

After the voting is complete, we wait for the transaction confirmations. The speed of this confirmation varies depending on the network and the node. After 300 seconds, we will be asked if we want to continue even without the three confirmations, to which we can answer yes, as they are rarely canceled once the first confirmation is received.

Once this confirmation is complete, the count begins and the results are generated in a file called RESULTS.md.

In addition, we will find in the application folder an electoral roll with the addresses used to vote (voters_ids.txt) and .json files containing the voting data, options, and results, along with a generated .png graphic file showing the number of votes per option.

All of this work is published under a Creative Commons license and is purely educational and experimental. Programmed with assistance from Google Gemini. November 2025.
______________________________________________________________________________________________________________________

Implentación de voto sobre cadena de bloques de criptomoneda Feathercoin (FTC)

Este desarrollo esta basado en el papel publicado en este blog denominado "Estrategia de voto en cadena de Bloques"  
Ruego consulte este documento para mas información sobre esta idea: https://habican.blogspot.com/2015/07/estrategia-de-voto-en-la-cadena-de.html
Para ver el ejemplo demostración visita https://habican.blogspot.com/2025/11/implentacion-de-voto-sobre-cadena-de.html


Descarga el software necesario en https://github.com/FeatherCoin/Feathercoin/releases/tag/v0.19.1.1 
y ponlo en la misma carpeta que nuestros archivos. Instala las dependencias requeridas si no las tienes ya instaladas.

0.- Lo primero es crear una cartera para la votación. En feathercoin-qt, la interfaz gráfica core de esta criptomoneda encontraras muy sencillo hacerlo. 

El nombre de esta cartera es -en nuestro ejemplo-  "votingWallet", y necesitaras disponer de fondos necesarios para enviar las transacciones. Encripta la cartera si quieres prevenir que se vacie si alguien o algo accediera a tu archivo local .dat en tu ordenador. El coste de la votación será el de las comisiones para las transacciones ya que los fondos se recuperan en la cartera una vez finalizada la votación, dejando como actas de resultados las inscripciones en la cadena de bloques. Su correlación con las preguntas y respuestas es el resultado arrojado. 

Solo realizaremos una pregunta por ejecución del programa, con múltiples respuestas posibles y múltiples votantes únicos. La regla es de un voto por persona.

1.- Vamos a la carpeta donde esta el programa, por ejemplo:

cd /home/usuario/votacionFTC/


Necesitaras dos terminales si quieres ver la información del nodo corriendo. El contenido es, junto al programa para levantar el nodo de feathercoin, los siguentes archivos:


generate_graphs.py  vote_protocol.sh  unlock_wallet.py


Descarga aquí estos archivos, y los archivos necesarios del repositorio enlazado mas arriba. Ponlos en la misma carpteta.

2.- Ahora arrancamos un nodo de Feathercoin en una de las terminales que indexe las transacciones en la piscina de memoria mediante el comando


./feathercoind -txindex=1


y cargamos nuestro monedero:


./feathercoin-cli loadwallet "votingWallet"


Ahora debemos esperar a que nuestro nodo este sincronizado. Si es la primera vez que arrancas el nodo deberemos esperar mucho. 

Ya tenemos todo listo para comenzar una vez el nodo este sicronizado. Ahora vamos a correr un script de python que permite desbloquer tu cartera durante el tiempo que especifiques, en el caso por defecto son 10 minutos.


python3 unlock_wallet.py


Pon la contraseña elegida para la cartera y comenzamos corriendo el siguiente script que incia el protocolo. ¡Que comienze la votación!


./vote_protocol.sh


Ahora debemos introducir la pregunta, las respuestas posibles (entrecomilladas si incluyen espacios en blanco) y el número de votantes. Si se preveen votos no validos es conveniente establecer aqui también esa última opción.

Ahora esperamos algo mas de un minuto a que se propagen las transacciones con la información necesaria para el desarrollo de la consulta. En este momento se ponen fondos para que cada dirección pueda ejercer su voto, y se preparan las direcciones que representan las respuestas a la pregunta.

Una vez transcurrida la espera comienza la votación. Ahora deben votar por turno las personas. Si es preciso se deben establecer papeletas fisicas en una urna y posteriormente se realiza el volcado de la consulta analógica en la cadena de bloques.

Hecha la votación, ahora esperamos a la confirmación de las transacciones. La velocidad de esta confirmación varía en funcion de la red y del nodo. Transcurridos 300 segundos se nos preguntará si queremos continuar aún sin las tres confirmaciones, a lo que podemos responder que sí pues rara vez son canceladas una vez la primera confirmacion entra. 

Una vez terminada esta confirmación comienza el recuento y se generan los resultados en un archivo RESULTS.md

Además encontraremos generados en la carpeta de la aplicación un padron electoral con las direcciones empleadas para votar voters_ids.txt y archivos .json incluyendo los datos de la votación, las opciones, y los resultados, junto a un archivo gráfico generado .png con el número de votos por opción.

Todo este trabajo esta publicado bajo licencia Creative Commons y su caracter es puramente educativo y experimental. 
Programado con asistencia de google gemini. Noviembre 2025. 


