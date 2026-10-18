import os
import shutil
import time
import csv
import json
from unittest.mock import patch

# Setup environment to use benchmark db
os.environ["DATABASE_URL"] = "sqlite:///benchmark.db"

# Copy original db to benchmark db to ensure clean state
if os.path.exists("smartschedule.db"):
    shutil.copy("smartschedule.db", "benchmark.db")

# Import the FastAPI app and dependencies
from api.index import app
from fastapi.testclient import TestClient
from core.database import SessionLocal
from models.models import AjuanPengajaran, JadwalFinal

client = TestClient(app)

def run_experiment_A():
    results = []
    # N sizes to test
    Ns = [10, 20, 30, 50, 100, 200]
    
    with patch("routers.engine.sync_supabase_to_sqlite_for_csp") as mock_sync_in, \
         patch("routers.engine.sync_generated_to_supabase") as mock_sync_out:
        
        for n in Ns:
            for rep in range(1, 6):
                # Clean up benchmark db for each run
                db = SessionLocal()
                # Remove all JadwalFinal
                db.query(JadwalFinal).delete()
                
                # Prevent engine.py from auto-generating extra AjuanPengajaran
                from models.models import MataKuliah
                db.query(MataKuliah).delete()
                
                # Get all AjuanPengajaran with explicit ordering for deterministic subset selection
                all_ajuan = db.query(AjuanPengajaran).order_by(AjuanPengajaran.id.asc()).all()
                
                selected = all_ajuan[:n]
                selected_ids = {a.id for a in selected}
                
                # Set selected to diajukan, rest to ditolak to ignore them
                db.query(AjuanPengajaran).filter(AjuanPengajaran.id.in_(selected_ids)).update({"status": "diajukan"}, synchronize_session=False)
                db.query(AjuanPengajaran).filter(~AjuanPengajaran.id.in_(selected_ids)).update({"status": "ditolak"}, synchronize_session=False)
                
                # CLEAR JADWAL FINAL BEFORE EACH REPETITION
                db.query(JadwalFinal).delete()
                db.commit()
                
                # Verify exactly N before calling engine
                actual_n = db.query(AjuanPengajaran).count()
                db.close()
                
                # Measure time
                start_time = time.perf_counter()
                
                response = client.post("/api/engine/csp", json={"scope": "global", "force_replan": True, "apply_to_db": True})
                
                runtime_ms = (time.perf_counter() - start_time) * 1000
                
                res_data = response.json()
                scheduled = res_data.get("total_scheduled", 0)
                unresolved = res_data.get("total_unresolved", 0)
                completion_rate = res_data.get("success_rate", 0)
                
                # Extract new metrics
                candidate_checks = res_data.get("candidate_checks", 0)
                overlap_rejections = res_data.get("overlap_rejections", 0)
                capacity_rejections = res_data.get("capacity_rejections", 0)
                building_hours_rejections = res_data.get("building_hours_rejections", 0)
                scss_score = res_data.get("scss_score", 100.0)
                
                results.append({
                    "N": n,
                    "replikasi": rep,
                    "runtime_ms": round(runtime_ms, 3),
                    "scheduled": scheduled,
                    "unresolved": unresolved,
                    "completion_rate_pct": completion_rate,
                    "candidate_checks": candidate_checks,
                    "overlap_rejections": overlap_rejections,
                    "capacity_rejections": capacity_rejections,
                    "building_hours_rejections": building_hours_rejections,
                    "scss_score": scss_score
                })
                
                print(f"Exp A - N={n}, Rep={rep}, Time={runtime_ms:.2f}ms, Scheduled={scheduled}, Unresolved={unresolved}")

    # Write to CSV
    with open("../artikel/hasil_uji_DCCE_Lengkap.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    
    return results

if __name__ == "__main__":
    run_experiment_A()
