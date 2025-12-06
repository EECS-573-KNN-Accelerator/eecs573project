import numpy as np
import csv

def generate_smooth_points(
    n_points=4599,
    dims=3,
    start_point=None,
    drift_scale=500
):
    """
    Generates smoothly varying synthetic dataset.
    Adjacent points remain close → good for KNN structure.
    """

    if start_point is None:
        start_point = np.random.randint(80000, 100000, size=dims)

    points = np.zeros((n_points, dims), dtype=float)
    points[0] = start_point

    for i in range(1, n_points):
        drift = np.random.normal(loc=0, scale=drift_scale, size=dims)
        drift = 0.7 * drift + 0.3 * np.random.normal(0, drift_scale/3, size=dims)
        points[i] = points[i - 1] + drift

    return points


def save_to_csv(filename, points):
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        for row in points:
            writer.writerow([int(v) for v in row])


# ------------------------------------------------------
# MAIN SCRIPT
# ------------------------------------------------------
if __name__ == "__main__":
    
    # -----------------------------
    # Generate smooth synthetic data
    # -----------------------------
    pts = generate_smooth_points(n_points=4599, dims=3)
    save_to_csv("synthetic_knn_data.csv", pts)
    print("Saved synthetic_knn_data.csv!")

    # convert floats → integers
    data_int = pts.astype(np.int64)

    # -----------------------------
    # Convert to 20-bit binary stringsll
    # -----------------------------
    data_bin20 = np.vectorize(lambda x: format(x, '020b'))(data_int)
    np.savetxt("synthetic_knn_data_bin20.csv", data_bin20, delimiter=",", fmt="%s")
    print("Saved 20-bit binary representation.")

    # -----------------------------
    # MSB bit-plane 64-bit packing
    # -----------------------------
    N = data_int.shape[0]
    block_size = 64
    num_blocks = N // block_size   # drop leftover
    num_bits = 17                  # use 17 MSB bits

    msb_rows = []

    for b in range(num_blocks):
        block = data_int[b*block_size:(b+1)*block_size, :]  # (64, 3)
        
        # Loop MSB → LSB (bit 16 → bit 0)
        for bit_pos in reversed(range(num_bits)):
            for f in range(3):  # 3 features
                # Collect 64 bits from this bit position
                bits = [(block[i, f] >> bit_pos) & 1 for i in range(block_size)]

                # Pack bits into a 64-bit integer
                num = 0
                for bit in bits:
                    num = (num << 1) | bit

                msb_rows.append(num)

    msb_rows = np.array(msb_rows, dtype=np.uint64)

    # Save MSB results
    np.save("synthetic_msb_bitplanes_64points_20bit.npy", msb_rows)
    np.savetxt(
        "synthetic_msb_bitplanes_64points_20bit_bin.csv",
        np.vectorize(lambda x: format(x, '064b'))(msb_rows),
        delimiter=",",
        fmt="%s"
    )

    # Hex version (16 hex chars = 64 bits)
    np.savetxt(
        "synthetic_msb_bitplanes_64points_20bit_hex.csv",
        np.vectorize(lambda x: format(x, '016X'))(msb_rows),
        delimiter=",",
        fmt="%s"
    )

    print("\nAll files saved successfully:")
    print("- synthetic_knn_data.csv")
    print("- synthetic_knn_data_bin20.csv")
    print("- synthetic_msb_bitplanes_64points_20bit.npy/.csv/.hex")
    print("Total MSB rows:", msb_rows.shape[0])
