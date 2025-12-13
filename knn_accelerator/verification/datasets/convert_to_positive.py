import csv
import sys

def convert_negatives_to_positives(input_file, output_file=None):
    """
    Convert all negative numbers to positive in a CSV file.
    
    Args:
        input_file: Path to input CSV file
        output_file: Path to output CSV file (if None, adds '_positive' suffix)
    """
    # Set default output filename if not provided
    if output_file is None:
        if input_file.endswith('.csv'):
            output_file = input_file.replace('.csv', '_positive.csv')
        else:
            output_file = input_file + '_positive.csv'
    
    try:
        # Read the input CSV
        with open(input_file, 'r') as infile:
            # Read all rows
            rows = []
            for line in infile:
                line = line.strip()
                if not line:  # Skip empty lines
                    continue
                
                # Split by comma
                values = line.split(',')
                
                # Convert each value
                converted_values = []
                for val in values:
                    val = val.strip()
                    if val.startswith('-'):
                        # Remove negative sign
                        converted_val = val[1:]
                    else:
                        converted_val = val
                    converted_values.append(converted_val)
                
                rows.append(converted_values)
        
        # Write to output CSV
        with open(output_file, 'w', newline='') as outfile:
            writer = csv.writer(outfile)
            writer.writerows(rows)
        
        print(f"Successfully converted {input_file} to {output_file}")
        print(f"Processed {len(rows)} rows")
        
        # Show a few examples
        if rows:
            print("\nFirst 3 rows (before → after):")
            with open(input_file, 'r') as infile:
                original_lines = [line.strip() for line in infile if line.strip()]
                for i in range(min(3, len(rows))):
                    print(f"  Original: {original_lines[i]}")
                    print(f"  Converted: {','.join(rows[i])}")
                    print()
        
        return output_file
        
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    # Check command line arguments
    if len(sys.argv) < 2:
        print("Usage: python convert_csv_negatives.py <input_csv_file> [output_csv_file]")
        print("\nExamples:")
        print("  python convert_csv_negatives.py data.csv")
        print("  python convert_csv_negatives.py data.csv positive_data.csv")
        print("\nIf output file is not specified, '_positive' will be appended to input filename.")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    convert_negatives_to_positives(input_file, output_file)

if __name__ == "__main__":
    main()