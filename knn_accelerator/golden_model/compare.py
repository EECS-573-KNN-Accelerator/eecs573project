import re
import sys

def extract_topk_coordinates(line):
    """Extract coordinates from a TopK list line."""
    # Pattern to match coordinates: [num, num, num]
    coord_pattern = r'\[(\d+),\s*(\d+),\s*(\d+)\]'
    
    # Find all coordinate matches
    matches = re.findall(coord_pattern, line)
    
    # Convert to tuples of integers
    coordinates = []
    for match in matches:
        x, y, z = int(match[0]), int(match[1]), int(match[2])
        coordinates.append((x, y, z))
    
    return coordinates

def compare_files(file1_path, file2_path):
    """Compare two files for TopK list matches."""
    total_coords_evaluated = 0
    matches_count = 0
    first_mismatch_found = False
    first_mismatch = None
    
    try:
        with open(file1_path, 'r') as file1, open(file2_path, 'r') as file2:
            lines1 = file1.readlines()
            lines2 = file2.readlines()
            
            # Find all TopK list lines in both files
            topk_lines1 = [(i, line.strip()) for i, line in enumerate(lines1) if 'TopK list' in line]
            topk_lines2 = [(i, line.strip()) for i, line in enumerate(lines2) if 'TopK list' in line]
            
            print(f"Found {len(topk_lines1)} TopK list lines in {file1_path}")
            print(f"Found {len(topk_lines2)} TopK list lines in {file2_path}")
            
            # Use the smaller number of lines as reference
            min_lines = min(len(topk_lines1), len(topk_lines2))
            
            if min_lines == 0:
                print("No TopK list lines found in one or both files!")
                return
            
            print(f"\nComparing {min_lines} TopK list entries...")
            
            for idx in range(min_lines):
                line_num1, line1 = topk_lines1[idx]
                line_num2, line2 = topk_lines2[idx]
                
                coords1 = extract_topk_coordinates(line1)
                coords2 = extract_topk_coordinates(line2)
                
                # Check if both have the same number of coordinates
                if len(coords1) != len(coords2):
                    print(f"\nMismatch at entry {idx+1}:")
                    print(f"  File1 (line {line_num1+1}): {len(coords1)} coordinates")
                    print(f"  File2 (line {line_num2+1}): {len(coords2)} coordinates")
                    if not first_mismatch_found:
                        first_mismatch = {
                            'entry': idx + 1,
                            'file1': {'line': line_num1 + 1, 'coords': coords1},
                            'file2': {'line': line_num2 + 1, 'coords': coords2},
                            'reason': f"Different number of coordinates: {len(coords1)} vs {len(coords2)}"
                        }
                        first_mismatch_found = True
                    continue
                
                total_coords_evaluated += len(coords1)
                
                # Compare each coordinate pair
                all_match = True
                mismatch_details = []
                
                for j, (coord1, coord2) in enumerate(zip(coords1, coords2)):
                    if coord1 == coord2:
                        matches_count += 1
                    else:
                        all_match = False
                        mismatch_details.append({
                            'position': j + 1,
                            'coord1': coord1,
                            'coord2': coord2
                        })
                
                if not all_match and not first_mismatch_found:
                    first_mismatch = {
                        'entry': idx + 1,
                        'file1': {'line': line_num1 + 1, 'coords': coords1},
                        'file2': {'line': line_num2 + 1, 'coords': coords2},
                        'mismatches': mismatch_details
                    }
                    first_mismatch_found = True
        
        # Calculate and print results
        print("\n" + "="*60)
        print("COMPARISON RESULTS")
        print("="*60)
        
        if total_coords_evaluated > 0:
            match_percentage = (matches_count / total_coords_evaluated) * 100
            print(f"Total coordinates evaluated: {total_coords_evaluated}")
            print(f"Coordinates matched: {matches_count}")
            print(f"Match percentage: {match_percentage:.2f}%")
        else:
            print("No coordinates were evaluated!")
        
        if first_mismatch:
            print("\n" + "="*60)
            print("FIRST MISMATCH FOUND")
            print("="*60)
            print(f"At TopK entry #{first_mismatch['entry']}")
            print(f"File1 (line {first_mismatch['file1']['line']}):")
            for i, coord in enumerate(first_mismatch['file1']['coords']):
                print(f"  Position {i+1}: {coord}")
            
            print(f"\nFile2 (line {first_mismatch['file2']['line']}):")
            for i, coord in enumerate(first_mismatch['file2']['coords']):
                print(f"  Position {i+1}: {coord}")
            
            if 'reason' in first_mismatch:
                print(f"\nReason: {first_mismatch['reason']}")
            elif 'mismatches' in first_mismatch:
                print("\nMismatched coordinates:")
                for mismatch in first_mismatch['mismatches']:
                    print(f"  Position {mismatch['position']}:")
                    print(f"    File1: {mismatch['coord1']}")
                    print(f"    File2: {mismatch['coord2']}")
        
        if matches_count == total_coords_evaluated and total_coords_evaluated > 0:
            print("\n✓ All coordinates match perfectly!")
            
    except FileNotFoundError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python compare_topk.py <file1.txt> <file2.txt>")
        print("Example: python compare_topk.py output1.txt output2.txt")
        sys.exit(1)
    
    file1_path = sys.argv[1]
    file2_path = sys.argv[2]
    
    print(f"Comparing files:")
    print(f"  File 1: {file1_path}")
    print(f"  File 2: {file2_path}")
    print()
    
    compare_files(file1_path, file2_path)

if __name__ == "__main__":
    main()