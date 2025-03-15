import argparse
import os
import subprocess


def get_address_from_objdump(elf_file, symbol):
    result = subprocess.run(
        ["riscv64-unknown-elf-objdump", "-t", elf_file], capture_output=True, text=True
    )
    for line in result.stdout.splitlines():
        if symbol in line:
            return int(line.split()[0], 16)
    return None


def annotate_dump(signature_file, elf_file):
    begin_signature = get_address_from_objdump(elf_file, "begin_signature")
    end_signature = get_address_from_objdump(elf_file, "end_signature")

    if begin_signature is None or end_signature is None:
        print(f"Symbols not found in {elf_file}")
        return

    address = begin_signature
    annotated_lines = []

    with open(signature_file, "r") as sig_file:
        for line in sig_file:
            annotated_lines.append(f"{hex(address)}: {line.strip()}")
            address += 4

    output_file = signature_file + ".annotated"
    with open(output_file, "w") as out_file:
        out_file.write("\n".join(annotated_lines))
    print(f"Annotated file created: {output_file}")


def process_directory(root_dir):
    for subdir, _, files in os.walk(root_dir):
        elf_file = None
        signature_file = None

        for file in files:
            if file.endswith(".elf"):
                elf_file = os.path.join(subdir, file)
            elif file.endswith(".signature"):
                signature_file = os.path.join(subdir, file)

        if elf_file and signature_file:
            annotate_dump(signature_file, elf_file)
        elif signature_file:
            print(f"No ELF file found for {signature_file}")


def main():
    parser = argparse.ArgumentParser(
        description="""
        Annotate memory dumps with addresses. Parses all subdirectories from the given root.
        Expects a .signature with a corresponding .elf in the same directory.
        Designed to annotate riscof signatures."""
    )
    parser.add_argument(
        "root_dir", type=str, help="Root directory to search for .signature files"
    )
    args = parser.parse_args()

    if not os.path.isdir(args.root_dir):
        print("Invalid root directory")
        return

    process_directory(args.root_dir)


if __name__ == "__main__":
    main()
