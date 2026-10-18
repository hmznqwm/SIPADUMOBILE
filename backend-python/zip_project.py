import zipfile
import os

source_dirs = ['backend', 'mobile', 'artikel']
output_filename = r'c:\Users\hmznq\Downloads\Data_Uji_Coba_DCCE_Final_Fix.zip'

excludes = ['.env', '__pycache__', 'node_modules', 'build', '.dart_tool', '.pub-cache', 'ios/Pods', 'android/.gradle', '.idea', '.vscode']

def should_exclude(path):
    for ex in excludes:
        if ex in path:
            return True
    return False

with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for s_dir in source_dirs:
        for root, dirs, files in os.walk(f"../{s_dir}"):
            if should_exclude(root):
                continue
            for file in files:
                file_path = os.path.join(root, file)
                if should_exclude(file_path):
                    continue
                zipf.write(file_path, os.path.relpath(file_path, ".."))

print(f"Successfully created {output_filename}")
