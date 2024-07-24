import argparse


def simplify_trace(input_file, output_file):
    with open(input_file, "r") as infile, open(output_file, "w") as outfile:
        for line in infile:
            # Split the line by the first comma and take the PC part
            pc = line.split(",")[0].strip().lower()
            outfile.write(f"{pc}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Simplify traces from instruction set simulators."
    )
    parser.add_argument("input_file", type=str, help="The input trace file")
    parser.add_argument(
        "output_file", type=str, help="The output file for the simplified trace"
    )

    args = parser.parse_args()
    simplify_trace(args.input_file, args.output_file)


if __name__ == "__main__":
    main()
