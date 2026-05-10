from fastapi import FastAPI
import httpx
import time
import asyncio
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Habilitamos CORS para evitar problemas con Flutter Web o llamadas desde el móvil
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MICROSERVICES = {
    "1": ("Restaurantes", "http://localhost:8001/data"),
    "2": ("Pedidos", "http://localhost:8002/data"),
    "3": ("Perfil", "http://localhost:8003/data")
}

@app.get("/bff")
async def bff_consolidated(active_services: str = "1,2,3"):
    start_time = time.time()
    
    # Filtramos qué servicios llamar basados en el parámetro
    selected_indices = active_services.split(",")
    urls_to_call = [MICROSERVICES[i][1] for i in selected_indices if i in MICROSERVICES]
    
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url, timeout=5.0) for url in urls_to_call]
        
        try:
            responses = await asyncio.gather(*tasks, return_exceptions=True)
            results = []
            
            for res in responses:
                if isinstance(res, Exception):
                    results.append({"error": str(res)})
                else:
                    results.append(res.json())
                    
        except Exception as e:
            return {"status": "error", "message": str(e)}

    end_time = time.time()
    
    return {
        "source": "BFF Server",
        "total_latency_ms": int((end_time - start_time) * 1000),
        "active_services_count": len(results),
        "results": results
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
