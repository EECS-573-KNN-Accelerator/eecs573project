import numpy as np
import csv

def reverse_msb_bitplanes(hex_csv_file, num_blocks=71, num_bits=17, block_size=64):
    """
    Converts MSB bit-plane hex format back to [x,y,z] points.
    
    Args:
        hex_csv_file: Path to synthetic_msb_bitplanes_64points_20bit_hex.csv
        num_blocks: Number of 64-point blocks
        num_bits: Number of MSB bits used (17)
        block_size: Points per block (64)
    
    Returns:
        points: (num_blocks * block_size, 3) array of [x,y,z] coordinates
    """
    
    # Read hex values
    hex_data = []
    with open(hex_csv_file, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            hex_data.append(row)
    
    hex_data = np.array(hex_data, dtype=str).flatten()
    
    # Convert hex to uint64
    bitplanes = np.array([int(h, 16) for h in hex_data], dtype=np.uint64)
    
    # Reconstruct points
    total_points = num_blocks * block_size
    points = np.zeros((total_points, 3), dtype=np.int64)
    
    idx = 0
    for b in range(num_blocks):
        for bit_pos in reversed(range(num_bits)):
            for f in range(3):  # 3 features
                # Extract 64-bit packed value
                packed_bits = bitplanes[idx]
                idx += 1
                
                # Unpack bits (MSB first)
                for i in range(block_size):
                    bit = int((packed_bits >> (63 - i)) & 1)
                    point_idx = b * block_size + i
                    points[point_idx, f] |= (bit << bit_pos)
    
    return points


if __name__ == "__main__":
    # Read and convert
    points = reverse_msb_bitplanes("synthetic_msb_bitplanes_64points_20bit_hex.csv")
    
    # Save as formatted JSON-style output
    with open("python_sim_dataset.csv", "w", newline="") as f:
        f.write("r_list = [\n")
        for i, point in enumerate(points):
            f.write(f"[{point[0]}, {point[1]}, {point[2]}]")
            if i < len(points) - 1:
                f.write(",\n")
            else:
                f.write("\n")
        f.write("]\n")
    
    print(f"Reconstructed {points.shape[0]} points")
    print("Saved to python_sim_dataset.csv")
    print("\nFirst 5 points:")
    print(points[:5])
    print("\nLast 5 points:")
    print(points[-5:])