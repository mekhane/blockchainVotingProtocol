import json
import sys
import os
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator

def generate_graph():
    # 1. Encontrar el archivo JSON más reciente
    poll_prefix = f"FTC_VOTE_{datetime.now().strftime('%Y%m%d')}"
    json_filename = f"{poll_prefix}_results.json"
    graph_filename = f"{poll_prefix}_grafica_votos.png"

    if not os.path.exists(json_filename):
        print(f"Error: No se encontró el archivo de resultados JSON: {json_filename}")
        sys.exit(1)

    # 2. Leer los datos del resultado del recuento
    try:
        with open(json_filename, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error al leer el archivo JSON: {e}")
        sys.exit(1)

    if not data:
        print("No hay datos para graficar.")
        sys.exit(0)

    # Leer la pregunta del archivo de opciones para el título
    options_filename = f"{poll_prefix}_options.json"
    question_text = "Resultados de la Votación"
    if os.path.exists(options_filename):
        try:
            with open(options_filename, 'r') as f_opt:
                options_data = json.load(f_opt)
                question_text = options_data.get('question', question_text)
        except:
            pass

    # 3. Preparar y ORDENAR datos por número de votos (de mayor a menor)
    # Convertir el diccionario a una lista de tuplas (opción, conteo)
    sorted_items = sorted(data.items(), key=lambda item: item[1], reverse=True)

    options = [item[0] for item in sorted_items]
    counts = [item[1] for item in sorted_items]

    # 4. Configurar colores
    colors = ['#2CA1A5', '#36C5C9', '#5ACFD3', '#7EDADD', '#A2E4E6', '#C7EFF0', '#0F3738', '#227E81', '#051414', '#EBF9FA']
    current_colors = colors[:len(options)]

    # 5. Crear la gráfica
    fig, ax = plt.subplots(figsize=(10, 6))

    # Crear las barras, redondeando los bordes con edgecolor y linewidth
    bars = ax.bar(
        options,
        counts,
        color=current_colors,
        edgecolor='#222222', # Borde más oscuro para el efecto redondeado
        linewidth=0.8
    )

    # Añadir las etiquetas de conteo encima de cada barra
    for bar in bars:
        yval = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2, yval + 0.1, int(round(yval)), ha='center', va='bottom', fontsize=12)

    # 6. Configurar la apariencia
    ax.set_ylabel('Número de Votos', fontsize=14)
    ax.set_title(f"{question_text}\n(Generado el {datetime.now().strftime('%Y-%m-%d')})", fontsize=16)
    ax.set_xlabel('Opciones de Voto', fontsize=14)

    # Forzar que las marcas del eje Y sean solo números enteros.
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

    # Ajustar límite Y
    max_count = max(counts) if counts else 0
    y_limit = max(1.0, max_count * 1.2)
    ax.set_ylim(0, y_limit)

    # Configurar el marco de la tabla (Axis spine)
    for spine in ax.spines.values():
        spine.set_linewidth(1.5)  # Engrosar el borde
        spine.set_edgecolor('#555555') # Color del borde

    plt.tight_layout()

    # 7. Guardar la gráfica
    plt.savefig(graph_filename)
    print(f"Gráfica guardada como {graph_filename}")

if __name__ == "__main__":
    generate_graph()
