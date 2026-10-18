import csv
with open('../artikel/hasil_uji_DCCE_Lengkap.csv', 'r') as f:
    reader = csv.DictReader(f)
    print('| N | Repetisi | Time | Sched | Unres | Cand. | Overlap | Cap. | Hours | SCSS (%) |')
    for row in reader:
        print(f"| {row['N']} | {row['replikasi']} | {row['runtime_ms']} | {row['scheduled']} | {row['unresolved']} | {row['candidate_checks']} | {row['overlap_rejections']} | {row['capacity_rejections']} | {row['building_hours_rejections']} | {row['scss_score']} |")
