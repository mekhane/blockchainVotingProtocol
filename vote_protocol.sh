#!/bin/bash

# ==========================================================
# VOTACIÓN SOBRE BLOCKCHAIN - PROTOCOLO V0.10 (FIX COMPATIBILIDAD JQ)
# ==========================================================
# Este programa permite una aproximación segura al voto y recuento electrónico
# mediante inscripción de transacciones en la cadena de bloques de Feathercoin (FTC)
# pensado para el establecimiento de mesa electoral local, voto mediante transaccion
# y recuento en la cadena de bloques.

# --- CONFIGURACIÓN DE ENTORNO ---
WALLET_NAME="votingWallet"
CLI="./feathercoin-cli -rpcwallet=$WALLET_NAME"
POLL_PREFIX="FTC_VOTE_$(date +%Y%m%d)"
DATA_FILE="${POLL_PREFIX}_data.json"
OPTIONS_FILE="${POLL_PREFIX}_options.json"
VOTER_ID_FILE="voter_ids.txt"
RESULTS_FILE="RESULTS.md"
GRAPH_SCRIPT="generate_graphs.py"
REQUIRED_CONFIRMATIONS=3
REQUIRED_AMOUNT=1.00 # Cantidad exacta de FTC que cuenta como 1 voto válido.

# --- FUNCIONES NÚCLEO ---

cleanup() {
    echo "⚙️ Limpiando archivos de encuestas anteriores..."
    rm -f $DATA_FILE $OPTIONS_FILE $VOTER_ID_FILE $RESULTS_FILE $POLL_PREFIX*results.json *.png 2>/dev/null
    echo "✅ Archivos de encuestas anteriores eliminados."
}

interactive_setup() {
    echo "=========================================================="
    echo "      1. PREPARACIÓN INTERACTIVA DE LA CONSULTA"
    echo "=========================================================="

    NUM_QUESTIONS=1

    read -p "¿Cuál es la PREGUNTA (tema principal de la votación)? " QUESTION

    echo "--- INSTRUCCIÓN: Use comillas dobles para opciones con espacios ---"
    read -p "Defina las opciones de voto (Ej: \"APROBAR\", \"RECHAZAR\", \"ABSTENCIÓN\"). Escriba las opciones separadas por comas (mínimo 2): " OPTIONS_INPUT

    # 1. Parsear, limpiar y crear un array JSON de nombres de opciones
    OPTIONS_JSON_ARRAY=$(echo "[$OPTIONS_INPUT]" | jq -R '
        split(",") | .[] |
        # 1. Eliminar espacios iniciales/finales
        ltrimstr(" ") | rtrimstr(" ") |
        # 2. Eliminar corchete inicial/final (para el caso de que la entrada esté envuelta en ellos)
        ltrimstr("[") |
        rtrimstr("]") |
        # 3. FIX V0.10: Utilizar sub con bandera global ("g") para compatibilidad máxima con jq.
        sub("\""; ""; "g") |
        # 4. Eliminar espacios de nuevo
        ltrimstr(" ") | rtrimstr(" ") |
        select(length > 0)
    ' | jq -s '.')

    if [ "$(echo "$OPTIONS_JSON_ARRAY" | jq length)" -lt 2 ]; then
        echo "❌ ERROR: Debe definir al menos 2 opciones válidas."
        exit 1
    fi

    # Usar JQ para generar la estructura final de 'options' con sus claves OPT
    JSON_OPTIONS=$(echo "$OPTIONS_JSON_ARRAY" | jq '
        to_entries |
        map({
            "name": .value,
            "key": ("OPT" + (.key + 1 | tostring))
        })
    ')

    export QUESTION="$QUESTION"

    # 2. Crear el archivo de opciones
    echo '{
        "question":"'$QUESTION'",
        "num_questions":'$NUM_QUESTIONS',
        "options":'$JSON_OPTIONS'
    }' | jq . > $OPTIONS_FILE

    echo "✅ Configuración de la pregunta guardada en $OPTIONS_FILE."
    echo "=========================================================="
}

setup_poll_addresses() {
    echo "=========================================================="
    echo "      2. CREANDO DIRECCIONES DE VOTO (SETUP POLL)"
    echo "=========================================================="

    ADDRESS_LIST=$(jq -r '.options[] | "\(.key)|\(.name)"' $OPTIONS_FILE)

    TEMP_ADDRESSES_FILE=$(mktemp)

    echo "Direcciones generadas para esta encuesta:"

    echo "$ADDRESS_LIST" | while IFS='|' read -r KEY OPTION_NAME; do

        ADDRESS=$($CLI getnewaddress)

        echo -n '"'${KEY}'":"'${ADDRESS}'",' >> $TEMP_ADDRESSES_FILE
        echo "  > ${OPTION_NAME} (${KEY}): ${ADDRESS}"
    done

    TEMP_ADDRESSES=$(cat $TEMP_ADDRESSES_FILE)
    TEMP_ADDRESSES=${TEMP_ADDRESSES%,}
    rm $TEMP_ADDRESSES_FILE

    echo '{
        "creation_time": "$(date -u +%Y-%m-%dT%H:%M:%S)Z",
        "required_amount": '$REQUIRED_AMOUNT',
        "option_addresses": {'$TEMP_ADDRESSES'}
    }' | jq . > $DATA_FILE

    echo "SUCCESS: Poll configuration saved to $DATA_FILE."
    echo "ACTION: Distribuir $DATA_FILE de forma segura (la 'papeleta')."
    echo "=========================================================="
}

fund_voters() {
    echo "=========================================================="
    echo "      3. TRANSFIRIENDO IDS DE VOTANTE"
    echo "=========================================================="

    if [ ! -f $VOTER_ID_FILE ]; then
        echo "❌ ERROR: No se encontró el archivo de IDs de votante ($VOTER_ID_FILE). Abortando."
        exit 1
    fi

    VOTER_IDS_FILE_CONTENT=$(cat $VOTER_ID_FILE)

    # Asegurar el formato de punto decimal para JSON
    JSON_PARAM=$(LC_NUMERIC=C echo "$VOTER_IDS_FILE_CONTENT" | awk -v amount="$REQUIRED_AMOUNT" '
        BEGIN {
            json_string = "{"
            total_amount = amount + 0.01
        }
        {
            amount_str = sprintf("%.2f", total_amount)
            gsub(/,/, ".", amount_str)

            json_string = json_string "\"" $1 "\":" amount_str ","
        }
        END {
            sub(/,$/, "", json_string);
            json_string = json_string "}";
            print json_string
        }'
    )

    echo "Parámetros de sendmany generados: $JSON_PARAM"

    TXID_FUND=$($CLI sendmany "" "$JSON_PARAM" 2>&1)

    if echo "$TXID_FUND" | grep -q "error"; then
        echo "❌ ERROR al transferir IDs de votante. Detalles:"
        echo "$TXID_FUND"
        exit 1
    fi

    echo "✅ Transacción de fondos enviada. TXID: $TXID_FUND"
    echo "Esperando 80 segundos para la propagación de la transacción..."
    sleep 80
    echo "=========================================================="
}

send_vote() {
    OPTION_KEY=$1

    DEST_ADDR=$(jq -r --arg key "$OPTION_KEY" '.option_addresses[$key]' $DATA_FILE)

    if [ "$DEST_ADDR" == "null" ] || [ -z "$DEST_ADDR" ]; then
        echo "❌ ERROR: Clave de opción ($OPTION_KEY) no encontrada en el archivo de datos." >&2
        return 1
    fi

    # Redirigir todos los mensajes de debug a STDERR (>&2)
    echo "  > Ejecutando: VOTO N° $(($i + 1)) -> DESTINO ($DEST_ADDR) con $REQUIRED_AMOUNT FTC." >&2

    TXID_VOTE=$($CLI sendtoaddress "$DEST_ADDR" "$REQUIRED_AMOUNT" "" "" "false" 2>&1)

    if echo "$TXID_VOTE" | grep -q "error"; then
        echo "❌ ERROR al enviar voto. Detalles:" >&2
        echo "$TXID_VOTE" >&2
        return 1
    fi

    echo "✅ Voto enviado. TXID: $TXID_VOTE" >&2

    # SOLO la TXID pura va a STDOUT
    echo "$TXID_VOTE"
    return 0
}

secure_counting() {
    echo "=========================================================="
    echo "      5. RECUENTO SEGURO Y AUDITORÍA                      "
    echo "=========================================================="

    declare -g -A RESULT_COUNTS
    TOTAL_VOTOS_VALIDOS=0

    ADDRESSES_JSON=$(jq -r '.option_addresses' $DATA_FILE)

    TEMP_COUNTS_FILE=$(mktemp)

    echo "$ADDRESSES_JSON" | jq -r 'to_entries[] | "\(.key)|\(.value)"' | while IFS='|' read -r KEY ADDRESS; do

        OPTION_NAME=$(jq -r --arg key "$KEY" '.options[] | select(.key == $key) | .name' $OPTIONS_FILE)

        VOTE_COUNT=$($CLI listreceivedbyaddress 0 true true "$ADDRESS" | jq -r '.[] | .txids | length' 2>/dev/null)

        if [ -z "$VOTE_COUNT" ]; then
            VOTE_COUNT=0
        fi

        echo "$OPTION_NAME:$VOTE_COUNT" >> $TEMP_COUNTS_FILE

    done

    while IFS=':' read -r OPTION_NAME COUNT_VALUE; do

        RESULT_COUNTS[$OPTION_NAME]=$COUNT_VALUE
        TOTAL_VOTOS_VALIDOS=$((TOTAL_VOTOS_VALIDOS + COUNT_VALUE))
        echo "  > ${OPTION_NAME}: $COUNT_VALUE votos válidos encontrados."
    done < $TEMP_COUNTS_FILE

    rm $TEMP_COUNTS_FILE

    QUESTION_TEXT=$(jq -r '.question' $OPTIONS_FILE)

    echo "# RESULTADOS DE LA VOTACIÓN SEGURA FTC" > $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    echo "## PREGUNTA" >> $RESULTS_FILE
    echo "$QUESTION_TEXT" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    echo "## AUDITORÍA" >> $RESULTS_FILE
    echo "| Categoría | Votos |" >> $RESULTS_FILE
    echo "| :--- | :--- |" >> $RESULTS_FILE
    echo "| Votos Válidos | $TOTAL_VOTOS_VALIDOS |" >> $RESULTS_FILE
    echo "| Votos Duplicados | (Requiere análisis) |" >> $RESULTS_FILE
    echo "| Votos Inválidos/Monto Incorrecto | (Requiere análisis) |" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    echo "## RECUENTO FINAL" >> $RESULTS_FILE
    echo "| Opción | Votos |" >> $RESULTS_FILE
    echo "| :--- | :--- |" >> $RESULTS_FILE

    JSON_GRAPH_DATA='{'
    for OPTION_NAME in "${!RESULT_COUNTS[@]}"; do
        COUNT_VALUE=${RESULT_COUNTS[$OPTION_NAME]}
        echo "| $OPTION_NAME | $COUNT_VALUE |" >> $RESULTS_FILE
        JSON_GRAPH_DATA+='"'${OPTION_NAME}'":'${COUNT_VALUE}','
    done
    JSON_GRAPH_DATA=${JSON_GRAPH_DATA%,}
    JSON_GRAPH_DATA+='}'

    echo "$JSON_GRAPH_DATA" | jq . > "${POLL_PREFIX}_results.json"

    echo "" >> $RESULTS_FILE
    echo "Generado en $(date -u) UTC." >> $RESULTS_FILE

    echo "✅ Recuento y auditoría finalizados."
    echo "=========================================================="
}

# --------------------------------------------------------------------------------
#                   INICIO DEL PROTOCOLO
# --------------------------------------------------------------------------------

main() {
    POLL_PREFIX="FTC_VOTE_$(date +%Y%m%d)"
    DATA_FILE="${POLL_PREFIX}_data.json"
    OPTIONS_FILE="${POLL_PREFIX}_options.json"

    echo "=========================================================="
    echo "          INICIO DE PROTOCOLO DE VOTACIÓN SEGURO"
    echo "=========================================================="
    echo "ADVERTENCIA: REQUIERE que $WALLET_NAME esté desbloqueado y tenga > 1.05 FTC * número de votantes."

    # Si hay archivos de votación, el usuario quiere continuar. De lo contrario, iniciar desde cero.
    if [ ! -f "$DATA_FILE" ] || [ ! -f "$OPTIONS_FILE" ]; then
        cleanup
        interactive_setup
        setup_poll_addresses

        echo "=========================================================="
        echo "      3. GENERANDO IDs DE VOTANTE (Padrón)"
        echo "=========================================================="

        while true; do
            read -p "¿Cuántos VOTANTES/IDs desea generar? (Mínimo 1): " NUM_VOTERS_INPUT
            if [[ "$NUM_VOTERS_INPUT" =~ ^[0-9]+$ ]] && [ "$NUM_VOTERS_INPUT" -ge 1 ]; then
                NUM_VOTERS=$NUM_VOTERS_INPUT
                break
            else
                echo "❌ Entrada no válida. Por favor, ingrese un número entero mayor o igual a 1."
            fi
        done

        > $VOTER_ID_FILE

        for i in $(seq 1 $NUM_VOTERS); do
            $CLI getnewaddress -addresstype=legacy >> $VOTER_ID_FILE
        done

        echo "✅ Padrón creado con $NUM_VOTERS IDs de Votante únicos en $VOTER_ID_FILE."
        echo "=========================================================="

        fund_voters
    fi # Fin de la lógica de inicio/continuación

    echo "=========================================================="
    echo "      6. EMISIÓN INTERACTIVA DE VOTOS"
    echo "=========================================================="

    VOTER_IDS_ARRAY=($(cat $VOTER_ID_FILE 2>/dev/null))
    if [ ${#VOTER_IDS_ARRAY[@]} -eq 0 ]; then
        echo "❌ ERROR: No se encontraron IDs de votante. Finalizando el protocolo."
        exit 1
    fi

    LAST_TXID=""
    OPTIONS_MAP=$(jq -r '.options[] | "\(.name)"' $OPTIONS_FILE | tr '\n' ' ')

    echo "OPCIONES VÁLIDAS:"
    jq -r '.options[] | "\(.name)"' $OPTIONS_FILE | sed 's/^/  - /'
    echo "-------------------------------------"


    for i in "${!VOTER_IDS_ARRAY[@]}"; do
        VOTER_ID=${VOTER_IDS_ARRAY[i]}

        while true; do
            # 🎯 INSTRUCCIÓN CLAVE DE USO: Pedir al usuario que use comillas.
            read -p "VOTO N° $((i+1)). Escriba la OPCIÓN (Ej: opción con espacios): " OPTION_NAME_INPUT

            # Quitar comillas del input si existen, para la búsqueda en el JSON
            # Es un paso de limpieza redundante de seguridad
            CLEANED_INPUT=$(echo "$OPTION_NAME_INPUT" | sed 's/"//g')

            OPTION_KEY_INPUT=$(jq -r --arg name "$CLEANED_INPUT" \
                '.options[] | select(.name == $name) | .key' $OPTIONS_FILE)

            if [ -z "$OPTION_NAME_INPUT" ]; then
                echo "⚠️ No se introdujo opción. Saltando voto N° $((i+1))." >&2
                break
            fi

            if [ -n "$OPTION_KEY_INPUT" ] && [ "$OPTION_KEY_INPUT" != "null" ]; then
                break
            else
                echo "❌ Opción NO válida. Por favor, use una de las siguientes (Ej: opción con espacios): " >&2
                jq -r '.options[] | "\(.name)"' $OPTIONS_FILE | sed 's/^/  - /' >&2
            fi
        done

        if [ -z "$OPTION_NAME_INPUT" ]; then
            continue
        fi

        TXID_OUTPUT=$(send_vote "$OPTION_KEY_INPUT")

        if [ $? -ne 0 ]; then
            echo "❌ ERROR fatal al enviar voto N° $((i+1)). Continuando..." >&2
            continue
        fi

        LAST_TXID="$TXID_OUTPUT"
    done

    echo "Última TXID exitosa a verificar: $LAST_TXID"

    # 7. Bucle de Confirmación
    MAX_CONFIRM_RETRIES=30
    RETRY_DELAY=10
    CONFIRMATIONS=0
    RETRY_COUNT=0

    CLEAN_TXID=$(echo "$LAST_TXID" | tr -d '\n' | grep -oP '^[[:xdigit:]]{64}$')

    if [ -z "$CLEAN_TXID" ] || echo "$LAST_TXID" | grep -q "error"; then
        echo "❌ No se pudo obtener una última TXID válida para esperar confirmación. Asumiendo confirmación para continuar."
    else
        echo "Esperando confirmación para TXID: $CLEAN_TXID (Necesitas $REQUIRED_CONFIRMATIONS, MÁXIMO $((MAX_CONFIRM_RETRIES * RETRY_DELAY)) segundos)..."

        while [ "$CONFIRMATIONS" -lt "$REQUIRED_CONFIRMATIONS" ] && [ "$RETRY_COUNT" -lt "$MAX_CONFIRM_RETRIES" ]; do
            CONFIRMATIONS=$($CLI gettransaction "$CLEAN_TXID" | jq -r .confirmations 2>/dev/null)

            if [ -z "$CONFIRMATIONS" ] || [ "$CONFIRMATIONS" = "null" ]; then
                CONFIRMATIONS=0
            fi

            if [ "$CONFIRMATIONS" -lt "$REQUIRED_CONFIRMATIONS" ]; then
                echo "   > Confirmaciones: $CONFIRMATIONS/$REQUIRED_CONFIRMATIONS. Reintentando en $RETRY_DELAY segundos... (Intento $((RETRY_COUNT + 1))/$MAX_CONFIRM_RETRIES)"
                sleep "$RETRY_DELAY"
                RETRY_COUNT=$((RETRY_COUNT + 1))
            fi
        done

        # LÓGICA DE BYPASS DE CONFIRMACIÓN
        if [ "$CONFIRMATIONS" -ge "$REQUIRED_CONFIRMATIONS" ]; then
            echo "✅ Transacción confirmada en bloque ($CONFIRMATIONS confirmaciones)."
        else
            echo "❌ ADVERTENCIA: La Transacción ($CLEAN_TXID) solo tiene $CONFIRMATIONS/$REQUIRED_CONFIRMATIONS confirmaciones después de $MAX_CONFIRM_RETRIES reintentos."
            read -p "¿Desea proceder con el RECUENTO y la AUDITORÍA A PESAR de las bajas confirmaciones? (y/N): " PROCEED_COUNTING
            if [[ "$PROCEED_COUNTING" == "y" || "$PROCEED_COUNTING" == "Y" ]]; then
                echo "⚠️ Procediendo con el recuento, asumiendo que las transacciones serán válidas."
            else
                echo "❌ RECUENTO CANCELADO por la falta de confirmaciones. El protocolo finaliza aquí."
                exit 1
            fi
        fi
    fi

    # 8. RECUENTO SEGURO Y AUDITORÍA
    secure_counting

    # 9. GENERANDO GRÁFICOS Y RESULTADOS FINALES
    echo "=========================================================="
    echo "          9. GENERANDO GRÁFICOS Y RESULTADOS FINALES"
    echo "=========================================================="

    echo "Ejecutando script de graficado ($GRAPH_SCRIPT)..."
    python3 $GRAPH_SCRIPT

    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Falló la generación de gráficos. Asegúrate de tener 'generate_graphs.py' y la librería Matplotlib instalada (pip install matplotlib)."
    fi

    echo ""
    echo "=========================================================="
    echo "          FIN DE PROTOCOLO DE VOTACIÓN SEGURO             "
    echo "=========================================================="
}

# Ejecutar el proceso principal
main
 

_____________________________________________________________________ 

 

 

unlock_wallet.py

_____________________________________________________________________ 

import subprocess
import getpass
import sys
import time

# --- Configuration ---
WALLET_NAME = "votingWallet"

def secure_unlock():
    """Prompts for password securely and executes the Feathercoin unlock command."""
    print("--- Secure Wallet Unlock Script ---")

    # 1. Securely ask for the password without echoing it
    try:
        # Use getpass to hide the password input
        password = getpass.getpass(f"Enter password for wallet '{WALLET_NAME}': ")
    except Exception as e:
        print(f"Error during password input: {e}")
        return

    # 2. Define the unlock command
    # Unlocks for 600 seconds (10 minutes)
    unlock_time = 600
    command = [
        "./feathercoin-cli",
        # CRITICAL: Always specify the named wallet
        f"-rpcwallet={WALLET_NAME}",
        "walletpassphrase",
        password,
        str(unlock_time)
    ]

    print(f"Executing unlock command for {unlock_time} seconds...")

    # 3. Execute the command securely
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=False)

        if result.returncode == 0:
            print("\n✅ Wallet UNLOCKED successfully.")
            print("You now have 10 minutes to run your administrative scripts.")
        else:
            print("\n❌ WALLET UNLOCK FAILED. Error details:")
            print(result.stderr.strip())
            print("Possible causes: Incorrect password, wallet not loaded, or Feathercoin daemon not running.")

    except FileNotFoundError:
        print("\nERROR: 'feathercoin-cli' not found. Check your PATH or run this script from the Feathercoin directory.")

# Execute the script
if __name__ == "__main__":
    secure_unlock()
 
