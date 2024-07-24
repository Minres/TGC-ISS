import argparse
import re


def simplify_trace(input_file, output_file):
    with open(input_file, "r") as infile, open(output_file, "w") as outfile:
        for line in infile:
            # Enhanced regex to match the instruction number, mode, and PC
            match = re.search(r"\[\d+\] \[[MI]\]: (0x[0-9A-Fa-f]+)", line)
            if match:
                pc = match.group(1).lower()
                outfile.write(f"{pc}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Simplify a trace from an instruction set simulator."
    )
    parser.add_argument("input_file", type=str, help="The input trace file")
    parser.add_argument(
        "output_file", type=str, help="The output file for the simplified trace"
    )

    args = parser.parse_args()
    simplify_trace(args.input_file, args.output_file)


if __name__ == "__main__":
    main()
