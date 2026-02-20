# Explicación del Laboratorio: Mini-MapReduce en GCP

Este documento detalla el contenido de la guía `mini_mapreduce_flask_gcp_20260215173028.pdf` y cómo se ha implementado en este proyecto.

## Estructura del Documento

La guía se divide en 9 páginas que cubren desde el modelo conceptual hasta la ejecución final.

### 1. Arquitectura del Sistema
El sistema utiliza un modelo **Master-Worker**:
- **Master (Orchestrator)**: Encargado de dividir el trabajo (Split), enviar tareas a los workers y consolidar los resultados (Reduce).
- **Workers (Mappers)**: Nodos paralelos que reciben fragmentos de texto, cuentan las palabras localmente y devuelven un diccionario JSON.
- **GCS (Cloud Storage)**: Almacén centralizado donde reside el archivo de entrada.

### 2. Pasos de Implementación

#### Paso 1: Almacenamiento (Cloud Storage)
Se crea un bucket y se sube un archivo de texto. 
*   *Implementación*: Se creó el bucket `data-processing-487312-mapreduce-bucket` mediante Terraform.

#### Paso 2: Red e Infraestructura (Compute Engine)
Configuración de una VPC y reglas de firewall para permitir el tráfico en el puerto **5000**.
*   *Implementación*: Terraform configuró la red `mapreduce-network` y abrió los puertos 22 (SSH) y 5000 (Flask).

#### Paso 3: Entorno de Software
Instalación de `python3-venv`, `flask`, `requests` y `google-cloud-storage` en todos los nodos.
*   *Implementación*: Se automatizó mediante el script `remote_setup.sh`.

#### Paso 4: Código del Worker (Map)
El worker expone un endpoint `/map` que recibe JSON con texto, usa `collections.Counter` para contar palabras y retorna el resultado.
*   *Archivo*: `app/worker.py`

#### Paso 5: Código del Master (Reduce)
El master descarga el archivo de GCS, lo divide en partes iguales según el número de workers, realiza peticiones HTTP POST en paralelo y finalmente agrega todos los contadores en uno solo.
*   *Archivo*: `app/master.py`

#### Paso 6: Ejecución
Se inician los servicios en los 4 nodos y se invoca el proceso mediante `curl` al Master.
*   *Comando*: `curl http://<IP_MAESTRO>:5000/run`

## Resumen Técnico
El proyecto demuestra los principios de **Sistemas Distribuidos** y **IaaS (Infrastructure as Code)** al automatizar la creación de recursos en la nube y coordinar la computación distribuida mediante APIs RESTful.

---
*Este análisis fue generado tras procesar la documentación técnica del laboratorio.*
