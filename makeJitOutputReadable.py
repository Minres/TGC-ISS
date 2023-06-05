import re
import os
'''
This script takes all files that get dumped by the tcc backend when using the --dump-ir
option and replaces the Integers of addresses with their hex representation to allow
for easier debugging.
'''
current_dir = os.getcwd()  # Get the current directory

files_with_tcc_jit = [file for file in os.listdir(current_dir) if"jit" in file and not file.startswith("readable")]

for each in files_with_tcc_jit:  
    readable_file = f"readable_{each}"
    if os.path.exists(readable_file):
        os.remove(readable_file)
    with open(each, "r") as file:
        content = file.read()
for each in files_with_tcc_jit:
    with open(each, "r") as file:
        content = file.read()

    # Replace numbers ending with "U" by their hex representation
    content = re.sub(r'\b(\d+)U\b(?=U)?', lambda m: hex(int(m.group(1))), content)

    with open(f"readable_{each}", "w") as file:
        file.write(content)