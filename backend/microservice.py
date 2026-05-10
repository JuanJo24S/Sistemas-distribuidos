from fastapi import FastAPI
import asyncio
import time
import os

app = FastAPI()

# Obtenemos el nombre del servicio de las variables de entorno para que sea dinámico
SERVICE_NAME = os.getenv("SERVICE_NAME", "Microservicio Genérico")
SLEEP_TIME = float(os.getenv("SLEEP_TIME", "1.0"))

@app.get("/data")
async def get_data():
    # Simulamos latencia intencional como pide el taller
    await asyncio.sleep(SLEEP_TIME)
    return {
        "service": SERVICE_NAME,
        "timestamp": time.time(),
        "status": "online"
    }

if __name__ == "__main__":
    import uvicorn
    # Escuchamos en 0.0.0.0 para permitir conexiones desde el emulador/celular
    port = int(os.getenv("PORT", "8001"))
    uvicorn.run(app, host="0.0.0.0", port=port)
