# Taller: Patrón BFF (Backend For Frontend) y Resiliencia en Sistemas Distribuidos

Este proyecto implementa un sistema distribuido para demostrar las ventajas del patrón **BFF (Backend For Frontend)** frente a las consultas directas a microservicios desde dispositivos móviles. Se enfoca en la eficiencia de red, latencia en la UI y manejo resiliente de errores.

## 🏗️ Arquitectura Técnica

### 1. Backend (Python/FastAPI)
- **Microservicios (Puertos 8001-8003):** 3 servicios independientes (Restaurantes, Pedidos, Perfil) que simulan carga real mediante un `asyncio.sleep(1.0)`.
- **Servidor BFF (Puerto 8000):** Actúa como API Gateway. Realiza agregación de datos consultando los microservicios de forma concurrente mediante `httpx` y `asyncio.gather`.
- **Automatización:** El script `run_all.py` gestiona el ciclo de vida de los 4 procesos y detecta automáticamente la IP local para la conectividad móvil.

### 2. Frontend (Flutter)
- **Patrones de Carga:** 
  - **Carga Directa:** El móvil orquesta múltiples llamadas HTTP. Expuesto a latencia acumulada y mayor consumo de batería/datos.
  - **Carga BFF:** Una única petición delegada al servidor, reduciendo el overhead de conexión (TCP handshake, SSL negociation) en redes móviles.
- **Resiliencia:** Implementación de timeouts (5s) y bloques `try-catch` para evitar estados de error técnicos (pantalla roja) y ofrecer una UX amigable.

---

## 📋 Requisitos Previos

- **Python 3.10+** (con `fastapi`, `uvicorn`, `httpx`).
- **Flutter SDK** (actualizado).
- **Entorno Linux (Kali)** configurado con los permisos de Android SDK.

---

## 🚀 Guía de Ejecución

### Paso 1: Levantar el Ecosistema Backend
1. Abre una terminal en la raíz del proyecto.
2. Ejecuta el orquestador:
   ```bash
   python3 run_all.py
   ```
3. **Importante:** Toma nota de la dirección IP que aparecerá en el recuadro: `🌍 TU IP LOCAL ES: 192.168.X.X`.

### Paso 2: Configurar y Ejecutar el Móvil
1. Conecta tu celular mediante USB y activa la **Depuración USB**.
2. Asegúrate de que el PC y el móvil estén en la **misma red Wi-Fi**.
3. En el archivo `bff/lib/main.dart`, actualiza la constante `host`:
   ```dart
   static const String host = "192.168.X.X"; // La IP obtenida en el Paso 1
   ```
4. Abre otra terminal y lanza la aplicación:
   ```bash
   cd bff
   flutter run
   ```

---

## 📱 Consideraciones para Móviles Físicos

### 1. Conectividad y Firewall (Kali Linux)
Por defecto, las distribuciones como Kali pueden bloquear puertos entrantes. Si la app no conecta:
```bash
sudo ufw allow 8000:8003/tcp
# O desactivar temporalmente
sudo ufw disable
```

### 2. Acceso a Localhost
- En **Emulador Android**, se usa `10.0.2.2`.
- En **Dispositivo Físico**, DEBES usar la IP privada de tu PC (`192.168.x.x`).

### 3. NDK / Build Errors
Si experimentas errores de NDK al compilar (`CXX1101`), borra la carpeta corrupta detectada por Flutter Fix:
```bash
rm -rf /home/drax/Android/Sdk/ndk/versión_corrupta
```

---

## 📊 Puntos Clave para la Sustentación

1. **Latencia:** Muestra cómo el BFF mantiene tiempos consistentes (~1000ms) mientras que la carga directa puede variar según la calidad de la señal y el número de conexiones simultáneas.
2. **Interactividad:** Usa los **Toggles** de la app para mostrar cómo el BFF filtra dinámicamente qué servicios consultar, optimizando el ancho de banda.
3. **Resiliencia:** Cierra el script `run_all.py` mientras la app corre para demostrar la captura de excepciones y el mensaje de error amigable: *"¡Ups! La señal se perdió"*.

---
*Desarrollado para el Laboratorio de Sistemas Distribuidos - Mayo 2026*
