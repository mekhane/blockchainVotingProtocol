Implentación de voto sobre cadena de bloques de criptomoneda Feathercoin (FTC)

Este desarrollo esta basado en el papel publicado en este blog denominado "Estrategia de voto en cadena de Bloques"  
Ruego consulte este documento para mas información sobre esta idea: https://habican.blogspot.com/2015/07/estrategia-de-voto-en-la-cadena-de.html
Para ver el ejemplo demostración visita https://habican.blogspot.com/2025/11/implentacion-de-voto-sobre-cadena-de.html


Descarga el software necesario en https://github.com/FeatherCoin/Feathercoin/releases/tag/v0.19.1.1 
y ponlo en la misma carpeta que nuestros archivos. Instala las dependencias requeridas si no las tienes ya instaladas.

0.- Lo primero es crear una cartera para la votación. En feathercoin-qt, la interfaz gráfica core de esta criptomoneda encontraras muy sencillo hacerlo. 
El nombre de esta cartera es -en nuestro ejemplo-  "votingWallet", y necesitaras disponer de fondos necesarios para enviar las transacciones.  
Encripta la cartera si quieres prevenir que se vacie si alguien o algo accediera a tu archivo local .dat en tu ordenador.
El coste de la votación será el de las comisiones para las transacciones ya que los fondos se recuperan en la cartera una vez finalizada la votación, 
dejando como actas de resultados las inscripciones en la cadena de bloques. Su correlación con las preguntas y respuestas es el resultado arrojado. 
Solo realizaremos una pregunta por ejecución del programa, con múltiples respuestas posibles y múltiples votantes únicos. La regla es de un voto por persona.

1.- Primero vamos a la carpeta donde esta el programa, por ejemplo:

cd /home/usuario/votacionFTC_001/


Necesitaras dos terminales si quieres ver la información del nodo corriendo. 
El contenido es, junto al programa para levantar el nodo de feathercoin, los siguentes archivos:

feathercoin-cli  generate_graphs.py  vote_protocol.sh
feathercoind     unlock_wallet.py

Descarga aqui estos archivos.

2.- Ahora arrancamos un nodo de Feathercoin en una de las terminales que indexe las transacciones en la piscina de memoria mediante el comando

./feathercoind -txindex=1

y cargamos nuestro monedero:

./feathercoin-cli loadwallet "votingWallet"

Ahora debemos esperar a que nuestro nodo este sincronizado. Si es la primera vez que arrancas el nodo deberemos esperar mucho. 
Aunque existe una opcion para el recuento aun no teniendo las suficientes confirmaciones es posible que no funcione si el nodo no esta sincronizado.

Ya tenemos todo listo para comenzar. Ahora vamos a correr un script de python que permite desbloquer tu cartera durante el tiempo que especifiques, 
en el caso por defecto son 10 minutos.

python3 unlock_wallet.py


Pon la contraseña elegida para la cartera y comenzamos corriendo el siguiente script que incia el protocolo. ¡Que comienza la votación!

./vote_protocol.sh


Ahora debemos introducir la pregunta, las respuestas posibles (entrecomilladas si incluyen espacios en blanco) y el número de votantes. 
Si se preveen votos no validos es conveniente establecer aqui también esa última opción.

Ahora esperamos algo mas de un minuto a que se propagen las transacciones con la información necesaria para el desarrollo de la consulta. 
En este momento se ponen fondos para que cada dirección pueda ejercer su voto, y se preparan las direcciones que representan las respuestas a la pregunta.

Una vez transcurrida la espera comienza la votación. Ahora deben votar por turno las personas. Si es preciso se deben establecer papeletas fisicas en una urna 
y posteriormente se realiza el volcado de la consulta analógica en la cadena de bloques.

Hecha la votación, ahora esperamos a la confirmación de las transacciones. La velocidad de esta confirmación varía en funcion de la red y del nodo. 
Transcurridos 300 segundos se nos preguntará si queremos continuar aún sin las tres confirmaciones, a lo que podemos responder que sí pues rara vez son 
canceladas una vez la primera confirmacion entra. 

Una vez terminada esta confirmación comienza el recuento y se generan los resultados en un archivo RESULTS.md

Además encontraremos generados en la carpeta de la aplicación un padron electoral con las direcciones empleadas para votar voters_ids.txt y archivos .json 
incluyendo los datos de la votación, las opciones, y los resultados, junto a un archivo gráfico generado .png con el número de votos por opción.

Todo este trabajo esta publicado bajo licencia Creative Commons y su caracter es puramente educativo y experimental. 
Programado con asistencia de google gemini. Noviembre 2025. 


