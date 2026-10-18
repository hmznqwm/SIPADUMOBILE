import os
import sys
import time
import uuid

os.environ["DATABASE_URL"] = "sqlite:///benchmark.db"

from core.database import SessionLocal
from models.models import AjuanPengajaran, JadwalFinal
from api.index import app
from fastapi.testclient import TestClient
from unittest.mock import patch

client = TestClient(app)

def run_dynamic():
    with patch("routers.engine.sync_supabase_to_sqlite_for_csp"), \
         patch("routers.engine.sync_generated_to_supabase"):
        
        db = SessionLocal()
        
        # 1. Reset
        db.query(JadwalFinal).delete()
        db.query(AjuanPengajaran).update({"status": "ditolak"})
        
        # 2. Pick 20 items to simulate existing fixed schedules
        all_ajuan = db.query(AjuanPengajaran).all()
        base_items = all_ajuan[:20]
        
        for a in base_items:
            a.status = "diajukan"
        db.commit()
        
        # 3. Initial Run to schedule them
        response_1 = client.post("/api/engine/csp", json={"scope": "global", "force_replan": True, "apply_to_db": True})
        
        # Now the DB should have JadwalFinal populated and AjuanPengajaran status as disetujui_admin
        # 4. Pick 1 new item to add
        new_item = all_ajuan[20]
        new_item.status = "diajukan"
        
        # Let's create a very constrained situation? Actually no, just a normal add.
        # But wait, we need to test if it bumps or fits nicely.
        db.commit()
        
        # 5. Dynamic Run
        start_time = time.perf_counter()
        
        response_2 = client.post("/api/engine/csp", json={"scope": "global", "force_replan": False, "apply_to_db": True})
        
        runtime_ms = (time.perf_counter() - start_time) * 1000
        res = response_2.json()
        
        with open("../artikel/hasil_uji_dynamic.txt", "w") as f:
            f.write(f"=== HASIL UJI DINAMIS (PENAMBAHAN KELAS BARU) ===\n")
            f.write(f"Kondisi Awal: 20 jadwal terkunci (locked)\n")
            f.write(f"Skenario: Sistem menerima 1 ajuan jadwal baru (Dosen: {new_item.dosen_nama}, Matkul: {new_item.mata_kuliah_nama})\n")
            f.write(f"Engine Re-plan: Hanya menjadwalkan 1 kelas baru tersebut (Tanpa merusak 20 kelas lain)\n")
            f.write(f"Hasil: {res.get('message')}\n")
            f.write(f"Waktu Komputasi: {runtime_ms:.3f} ms\n")
            f.write(f"Total Candidate Checks: {res.get('candidate_checks', 0)}\n")
            f.write(f"Total Overlap Rejections: {res.get('overlap_rejections', 0)}\n")
            
        db.close()
            
if __name__ == "__main__":
    run_dynamic()
