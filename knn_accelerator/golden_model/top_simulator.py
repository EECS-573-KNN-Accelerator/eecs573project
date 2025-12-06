import sys

# -------------------------------------------------------------
# Configuration
# -------------------------------------------------------------
BIT_WIDTH = 17 

def int_to_bits(val):
    """ Convert integer to list of bits (0 or 1), MSB first. """
    val = val & ((1 << BIT_WIDTH) - 1) 
    return [(val >> i) & 1 for i in reversed(range(BIT_WIDTH))]

def build_stream(q_point, r_point):
    """ Interleaves bits Q and R points MSB -> LSB """
    qx = int_to_bits(q_point[0])
    qy = int_to_bits(q_point[1])
    qz = int_to_bits(q_point[2])
    rx = int_to_bits(r_point[0])
    ry = int_to_bits(r_point[1])
    rz = int_to_bits(r_point[2])

    stream = []
    for i in range(BIT_WIDTH):
        bit_pos_idx = i + 1 
        stream.append((qx[i], rx[i], 0b01, bit_pos_idx)) # X
        stream.append((qy[i], ry[i], 0b10, bit_pos_idx)) # Y
        stream.append((qz[i], rz[i], 0b11, bit_pos_idx)) # Z
    return stream

def run_bdu(stream, threshold):
    cycles = 0
    
    # We now track the signed difference per dimension
    diff_x = 0
    diff_y = 0
    diff_z = 0
    
    # Total Manhattan Distance
    total_dist = 0
    
    # Reconstruction registers
    r_x = 0
    r_y = 0
    r_z = 0
    
    done = False

    print(f"{'Cyc':<4} | {'Dim':<3} | {'Q':<1} {'R':<1} | {'Diff Val':<10} | {'Total Dist'}")
    print("-" * 50)

    for q_bit, r_bit, code, b in stream:
        if done:
            break

        # ---------------------------------------------------
        # MSB-First Serial Subtraction
        # diff = (diff * 2) + (q_bit - r_bit)
        # ---------------------------------------------------
        if code == 0b01:   # X
            diff_x = (diff_x << 1) + (q_bit - r_bit)
            r_x = ((r_x << 1) | r_bit) & ((1 << BIT_WIDTH) - 1)
            dim_str = "X"
        elif code == 0b10: # Y
            diff_y = (diff_y << 1) + (q_bit - r_bit)
            r_y = ((r_y << 1) | r_bit) & ((1 << BIT_WIDTH) - 1)
            dim_str = "Y"
        elif code == 0b11: # Z
            diff_z = (diff_z << 1) + (q_bit - r_bit)
            r_z = ((r_z << 1) | r_bit) & ((1 << BIT_WIDTH) - 1)
            dim_str = "Z"
            
        # Calculate current instantaneous Manhattan Distance
        # |x1-x2| + |y1-y2| + |z1-z2|
        total_dist = abs(diff_x) + abs(diff_y) + abs(diff_z)

        cycles += 1
        
        # Debug trace
        # We show the specific dimension's current diff value
        curr_dim_diff = diff_x if code == 0b01 else (diff_y if code == 0b10 else diff_z)
        print(f"{cycles:<4} | {dim_str:<3} | {q_bit} {r_bit} | {curr_dim_diff:<10} | {total_dist}")

        # ---------------------------------------------------
        # Check Termination
        # ---------------------------------------------------
        # Note: In Manhattan distance, the distance can fluctuate 
        # up and down as bits are processed. Strict early termination 
        # is riskier here, but we apply it if requested.
        if total_dist >= threshold:
            done = True
        elif cycles >= BIT_WIDTH * 3:
            done = True

    valid = 1 if total_dist < threshold else 0
    return cycles, valid, total_dist, r_x, r_y, r_z

# -----------------------------
if __name__ == "__main__":
    # Test: Q=1, R=2. Expected Dist per dim = 1. Total = 3.
    q = (1, 1, 1)
    r = (2, 2, 2)
    REF_POINTS = np.random.randint(0, MAX_COORD_VAL, size=(N, DIMENSIONS), dtype=np.uint32)
    stream = build_stream(q, r)
    threshold = 100 
    
    cycles, valid, dist, x, y, z = run_bdu(stream, threshold)

    print("-" * 50)
    print("FINAL RESULTS:")
    print(f"Cycles:   {cycles}")
    print(f"Valid:    {valid}")
    print(f"Distance: {dist}")
    print(f"Reconstructed R: ({x}, {y}, {z})")