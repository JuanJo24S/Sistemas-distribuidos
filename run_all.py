import subprocess
import time
import sys
import os
import socket

def get_local_ip():
    try:
        # Crea un socket temporal para detectar la IP de la interfaz activa
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def run_services():
    processes = []
    local_ip = get_local_ip()
    
    # Configuración de los microservicios
    services = [
        {"name": "Restaurantes", "port": "8001"},
        {"name": "Pedidos", "port": "8002"},
        {"name": "Perfil", "port": "8003"},
    ]
    
    print("="*50)
    print(f"🌍 TU IP LOCAL ES: {local_ip}")
    print(f"👉 USA ESTA IP EN Flutter (lib/main.dart)")
    print("="*50)
    print("\n🚀 Iniciando Microservicios...")
    for svc in services:
        env = os.environ.copy()
        env["SERVICE_NAME"] = svc["name"]
        env["PORT"] = svc["port"]
        p = subprocess.Popen(
            [sys.executable, "backend/microservice.py"],
            env=env
        )
        processes.append(p)
        print(f"✅ {svc['name']} corriendo en puerto {svc['port']}")

    print("🚀 Iniciando Servidor BFF en puerto 8000...")
    bff_p = subprocess.Popen([sys.executable, "backend/bff.py"])
    processes.append(bff_p)
    print("✅ BFF Listo.")

    try:
        print("\n🔥 Todos los servicios están activos. Presiona Ctrl+C para detenerlos.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Deteniendo servicios...")
        for p in processes:
            p.terminate()
        print("👋 ¡Adiós!")

if __name__ == "__main__":
    run_services()
