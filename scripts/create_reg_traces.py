import argparse
import os
import shutil
import subprocess
from pathlib import Path


def validate_elf_file(filepath: str) -> str:
    if not os.path.isfile(filepath):
        raise argparse.ArgumentTypeError(f"{filepath} is not a valid file.")

    # Use the 'file' command to check if it's an ELF file
    result = subprocess.run(
        ["file", filepath], capture_output=True, text=True, check=False
    )
    if "ELF" not in result.stdout:
        raise argparse.ArgumentTypeError(f"{filepath} is not a valid ELF file.")

    return filepath


def run_test_and_move_output(elf_file: str, backend: str, isa: str = "tgc5c") -> None:
    # Call 'test' with the specified backend mode
    os.chdir(Path(__file__).parent.parent)
    sim_path = "build/Debug/dbt-rise-tgc/tgc-sim"
    run_command = [
        sim_path,
        "-f",
        elf_file,
        "--backend",
        backend,
        "--isa",
        isa,
        "-p",
        "build/Debug/dbt-rise-plugins/pctrace/pctrace.so=dbt-rise-tgc/contrib/instr/TGC5C_instr.yaml",
        "-i",
        "10000",
    ]
    print(f"Running: \n{' '.join(run_command)}")
    try:
        subprocess.run(run_command, check=False, timeout=10)
    except subprocess.TimeoutExpired:
        print("Execution timed out")

    # Move the output.trc file
    if os.path.exists("output.trc"):
        shutil.move("output.trc", f"Debug/{backend}.trc")
    else:
        print(
            f"output.trc does not exist after running with backend {backend}, so it cannot be renamed."
        )


def create_shortened_diff_files(backend: str) -> None:
    file1_path = "Debug/interp.trc"
    file2_path = f"Debug/{backend}.trc"

    def validate_file(filepath: str) -> str:
        if not os.path.isfile(filepath):
            raise ValueError(f"{filepath} is not a valid file.")
        return filepath

    file1_path = validate_file(file1_path)
    file2_path = validate_file(file2_path)

    with open(file1_path, "r", encoding="utf8") as file1, open(
        file2_path, "r", encoding="utf8"
    ) as file2:
        lines1 = file1.readlines()
        lines2 = file2.readlines()

    diff_index = -1
    for index, (line1, line2) in enumerate(zip(lines1, lines2)):
        if line1 != line2:
            diff_index = index
            break

    if diff_index == -1:
        print("The files are identical.")
        return

    start_index = max(0, diff_index - 5)
    end_index = min(len(lines1), diff_index + 6)

    shortened_lines1 = lines1[start_index:end_index]
    shortened_lines2 = lines2[start_index:end_index]

    with open("Debug/short_interp.trc", "w", encoding="utf8") as short_file1:
        short_file1.writelines(shortened_lines1)

    with open(f"Debug/short_{backend}.trc", "w", encoding="utf8") as short_file2:
        short_file2.writelines(shortened_lines2)


def create_disassembly(elf_file_path: str) -> None:
    def validate_file(filepath: str) -> str:
        if not os.path.isfile(filepath):
            raise ValueError(f"{filepath} is not a valid file.")
        return filepath

    elf_file_path = validate_file(elf_file_path)

    output_file_path = "Debug/dut.dis"
    with open(output_file_path, "w", encoding="utf8") as output_file:
        subprocess.run(
            [
                "riscv64-unknown-elf-objdump",
                "-d",
                "-Mnumeric",
                "-Mno-aliases",
                elf_file_path,
            ],
            stdout=output_file,
            check=True,
        )


def main(args: argparse.Namespace) -> None:
    elf_file = args.elf_file
    backend = args.backend
    isa = args.isa

    # Set environment variable
    os.environ["REGDUMP"] = "True"

    # Run the tests and move the output files
    run_test_and_move_output(elf_file, "interp", isa)
    run_test_and_move_output(elf_file, backend, isa)
    create_shortened_diff_files(backend)
    create_disassembly(elf_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process an ELF file with a specified backend. Generates register traces for interp and the specified backend"
    )
    parser.add_argument(
        "elf_file", type=validate_elf_file, help="The ELF file to be processed."
    )
    parser.add_argument(
        "--backend",
        type=str,
        default="amsjit",
        help="The backend to be used. Default is amsjit.",
        required=False,
    )
    parser.add_argument(
        "--isa",
        type=str,
        default="tgc5c",
        help="The isa to be used. Default 'tgc5c'",
        required=False,
    )
    main(args=parser.parse_args())
