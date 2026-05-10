from fastapi import FastAPI
import asyncio
import httpx
import time

app = FastAPI()

# --- MICROSERVICIOS ---
@app.get("/data")
async def get_data():
    await asyncio.sleep(1)  # Simula latencia de red/procesamiento
    return {"status": "success", "server_time": time.time()}

# --- BFF (Backend For Frontend) ---
@app.get("/bff")
async def bff_service():
    start_time = time.time()
    urls = [
        "http://localhost:8001/data",
        "http://localhost:8002/data",
        "http://localhost:8003/data"
    ]
    
    async with httpx.AsyncClient() as client:
        # Llamamos a los 3 micros en paralelo para ser eficientes
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
    
    data = [res.json() for res in responses]
    end_time = time.time()
    
    return {
        "source": "BFF",
        "total_latency_ms": int((end_time - start_time) * 1000),
        "payload": data
    }