import numpy as np

# -----------------------------
# Load data
# -----------------------------
data = np.load("oxford_2015-03-17-11-08-44_stereo_left.npy")
N = data.shape[0]

# -----------------------------
# Shift data to positive
# -----------------------------
min_val = data.min()
data_shifted = data - min_val
print("Minimum value shifted to 0.")

# -----------------------------
# Extract first 3 SIFT features
# -----------------------------
descriptors = data_shifted.reshape(N, 32, 128)
first_3_features = descriptors[:, 0, :3]

# Save shifted features
np.save("first3_features_shifted.npy", first_3_features)
np.savetxt("first3_features_shifted.csv", first_3_features, delimiter=",", fmt="%.6f")

# -----------------------------
# Scale and convert to integers (remove decimals)
# -----------------------------
scale = 1000000  # adjust if needed to fit 20 bits
data_scaled = first_3_features * scale

# Convert to integers (truncate decimals)
data_int = np.round(data_scaled).astype(np.int32)
np.save("first3_features_scaled_int.npy", data_int)
np.savetxt("first3_features_scaled_int.csv", data_int, delimiter=",", fmt="%d")

# -----------------------------
# Convert to 20-bit binary strings
# -----------------------------
data_bin20 = np.vectorize(lambda x: format(x, '020b'))(data_int)
np.savetxt("first3_features_scaled_bin20.csv", data_bin20, delimiter=",", fmt="%s")
print("Saved 20-bit binary representation.")

# -----------------------------
# MSB bit-plane 64-bit numbers (20 bits per feature)
# -----------------------------
block_size = 64
num_blocks = N // block_size  # drop leftover points
num_bits = 17  # use 20 bits for each number
msb_rows = []

for b in range(num_blocks):
    block = data_int[b*block_size:(b+1)*block_size, :]  # shape (64, 3)
    
    # Loop over bit positions: MSB (19) → LSB (0)
    for bit_pos in reversed(range(num_bits)):
        for f in range(3):  # feature 1,2,3
            bits = [(block[i, f] >> bit_pos) & 1 for i in range(block_size)]
            num = 0
            for bit in bits:
                num = (num << 1) | bit
            msb_rows.append(num)

msb_rows = np.array(msb_rows, dtype=np.uint64)

# Save MSB bit-plane results
np.save("msb_bitplanes_64points_20bit.npy", msb_rows)
np.savetxt(
    "msb_bitplanes_64points_20bit_bin.csv",
    np.vectorize(lambda x: format(x, '064b'))(msb_rows),
    delimiter=",",
    fmt="%s"
)

#convert to hex
np.savetxt(
    "msb_bitplanes_64points_20bit_hex.csv",
    np.vectorize(lambda x: format(x, '016X'))(msb_rows),
    delimiter=",",
    fmt="%s"
)

print("All files saved successfully:")
print("- Shifted features (.npy, .csv)")
print("- Scaled integer features (.npy, .csv)")
print("- 20-bit binary features (.csv)")
print("- MSB bit-plane 64-bit numbers (.npy, .csv)")
print("Total MSB rows:", msb_rows.shape[0])
