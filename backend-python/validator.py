import sys
import os
os.environ["DATABASE_URL"] = "sqlite:///benchmark.db"
from core.database import SessionLocal
from models.models import JadwalFinal, AjuanPengajaran, Ruangan

def parse_time(t_str):
    """Convert 'HH:MM' to minutes since midnight for easy comparison"""
    if not t_str: return 0
    h, m = map(int, t_str.split(':'))
    return h * 60 + m

def is_overlap(s1, e1, s2, e2):
    """Check if time range 1 overlaps with time range 2"""
    return max(s1, s2) < min(e1, e2)

def is_travel_buffer_violated(s_start, s_end, s_gedung, e_start, e_end, e_gedung):
    if s_gedung != e_gedung and s_gedung and e_gedung:
        if s_end > e_start - 10 and e_end > s_start - 10:
            return True
    return False

def validate_schedule():
    db = SessionLocal()
    schedules = db.query(JadwalFinal).all()
    
    if not schedules:
        print("No schedules found to validate.")
        return
        
    print(f"Validating {len(schedules)} final schedules...")
    
    room_conflicts = 0
    dosen_conflicts = 0
    kelas_conflicts = 0
    capacity_conflicts = 0
    room_type_conflicts = 0
    travel_conflicts = 0
    
    ruangan_list = db.query(Ruangan).all()
    ruangan_map = {r.nama: r for r in ruangan_list}
    
    ajuan_list = db.query(AjuanPengajaran).all()
    ajuan_map = {f"{a.mata_kuliah_id}_{a.kelas_nama}": a for a in ajuan_list}
    
    for s in schedules:
        if s.ruangan_nama in ruangan_map:
            room = ruangan_map[s.ruangan_nama]
            if (s.jumlah_mahasiswa or 0) > room.kapasitas:
                capacity_conflicts += 1
                
            aj = ajuan_map.get(f"{s.mata_kuliah_id}_{s.kelas_nama}")
            req_type = "Kelas Teori"
            if aj:
                m_name = (aj.mata_kuliah_nama or "").lower()
                if "lab" in m_name or "praktikum" in m_name or "flutter" in m_name or "pemrograman" in m_name or "algoritma" in m_name:
                    req_type = "Laboratorium Komputer"
            
            if req_type == "Laboratorium Komputer" and room.tipe_ruangan != "Laboratorium Komputer":
                room_type_conflicts += 1
            elif req_type == "Kelas Teori" and room.tipe_ruangan not in ["Kelas Teori", "Laboratorium Komputer"]:
                room_type_conflicts += 1
                
    for i in range(len(schedules)):
        for j in range(i + 1, len(schedules)):
            s1 = schedules[i]
            s2 = schedules[j]
            
            if s1.hari != s2.hari: continue
                
            start1 = parse_time(s1.jam_mulai)
            end1 = parse_time(s1.jam_selesai)
            start2 = parse_time(s2.jam_mulai)
            end2 = parse_time(s2.jam_selesai)
            
            if is_overlap(start1, end1, start2, end2):
                if s1.ruangan_nama == s2.ruangan_nama and "Daring" not in s1.ruangan_nama:
                    room_conflicts += 1
                if s1.dosen_id == s2.dosen_id:
                    dosen_conflicts += 1
                if s1.kelas_nama == s2.kelas_nama:
                    kelas_conflicts += 1
            
            # Travel Buffer check
            if s1.dosen_id == s2.dosen_id or s1.kelas_nama == s2.kelas_nama:
                if is_travel_buffer_violated(start1, end1, s1.gedung_nama, start2, end2, s2.gedung_nama):
                    travel_conflicts += 1
                    
    print("\n--- VALIDATION REPORT (ITC 2019 STYLE) ---")
    print(f"Total Scheduled   : {len(schedules)}")
    print(f"Room Overlaps     : {room_conflicts}")
    print(f"Lecturer Overlaps : {dosen_conflicts}")
    print(f"Class Grp Overlaps: {kelas_conflicts}")
    print(f"Capacity Overloads: {capacity_conflicts}")
    print(f"Room Type Mismat. : {room_type_conflicts}")
    print(f"Travel Buffer Vio.: {travel_conflicts}")
    print("------------------------------------------")
    if room_conflicts == 0 and dosen_conflicts == 0 and kelas_conflicts == 0 and capacity_conflicts == 0 and room_type_conflicts == 0 and travel_conflicts == 0:
        print("STATUS: FEASIBLE (All Hard Constraints Satisfied)")
    else:
        print("STATUS: INFEASIBLE (Hard Constraints Violated)")
    print("------------------------------------------")
    
    with open("../artikel/validasi_independen.txt", "w") as f:
        f.write("--- VALIDATION REPORT (ITC 2019 STYLE) ---\n")
        f.write("1. HARD CONSTRAINTS VERIFICATION\n")
        f.write(f"Total Scheduled   : {len(schedules)}\n")
        f.write(f"Room Overlaps     : {room_conflicts}\n")
        f.write(f"Lecturer Overlaps : {dosen_conflicts}\n")
        f.write(f"Class Grp Overlaps: {kelas_conflicts}\n")
        f.write(f"Capacity Overloads: {capacity_conflicts}\n")
        f.write(f"Room Type Mismat. : {room_type_conflicts}\n")
        f.write(f"Travel Buffer Vio.: {travel_conflicts}\n")
        f.write("------------------------------------------\n")
        if room_conflicts == 0 and dosen_conflicts == 0 and kelas_conflicts == 0 and capacity_conflicts == 0 and room_type_conflicts == 0 and travel_conflicts == 0:
            f.write("STATUS: FEASIBLE (All Hard Constraints Satisfied)\n")
        else:
            f.write("STATUS: INFEASIBLE (Hard Constraints Violated)\n")
        f.write("------------------------------------------\n\n")
        f.write("2. SOFT CONSTRAINTS EVALUATION (SCSS FORMULA)\n")
        f.write("SCSS is independently verified by engine counting the following:\n")
        f.write("Formula: SCSS = ((Waktu_Favorit_Terpenuhi + Gedung_Favorit_Terpenuhi) / Total_Preferensi_Diajukan) * 100%\n")
        f.write("Where Total_Preferensi_Diajukan = (Jumlah_Ajuan_Dengan_Waktu_Pref + Jumlah_Ajuan_Dengan_Gedung_Pref)\n")
        
    db.close()

if __name__ == "__main__":
    validate_schedule()
