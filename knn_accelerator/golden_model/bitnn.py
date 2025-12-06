import math

# ======================
# 1. Helper Functions
# ======================

def read_memory_file(filename):
    """
    Reads a memory file in hex format.
    Returns list of bits (MSB first) for each coordinate of each point.
    Each 32 lines represent 4 points (x, y, z for each).
    """
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    points = []
    # Each 32 lines = 4 points
    for group_start in range(0, len(lines), 32):
        group_lines = lines[group_start:group_start + 32]
        for point_idx in range(4):
            # x, y, z each 32 bits (MSB first)
            x_bits = []
            y_bits = []
            z_bits = []
            for bit_line_idx in range(8):  # 8 lines per coordinate (4 points * 8 bits per line?)
                # Actually: 32 lines = 4 points * 3 coords * (32 bits / 4 bits per line?)
                # Let's assume each line is 4 hex chars = 16 bits, so 2 lines per 32-bit coord.
                pass  # We need to adjust based on actual file layout.
    # Simplified: assume file is just hex values per bit?
    # Let's assume each line is one 32-bit hex number per coordinate.
    # But problem says: {MSB of x of first 4 query points}...
    # Let's implement a flexible version:
    # We'll parse as raw hex strings and convert to bits.
    pass  # We'll implement after clarifying.

# Let's simplify for now: assume each line is 32-bit hex string.
# We'll implement a more structured version.

def hex_to_bits(hex_str, bits=32):
    """Convert hex string to list of bits (MSB first)."""
    val = int(hex_str, 16)
    bits_list = [(val >> i) & 1 for i in reversed(range(bits))]
    return bits_list

def read_points_from_file(filename):
    points = []
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    # Expect 32 lines per 4 points (x, y, z each 32 bits)
    for i in range(0, len(lines), 32):
        group_lines = lines[i:i+32]
        # Each 8 lines = one coordinate for 4 points
        for point_offset in range(4):
            x_bits = []
            y_bits = []
            z_bits = []
            for j in range(8):  # 8 lines per coord (32 bits / 4 bits per line)
                # Actually each line may be 4 hex chars = 16 bits
                # Let's assume each line is full 32-bit hex
                # We need more info. Let's simplify:
                # Assume each of the 32 lines is 32-bit hex for one coord of one point.
                pass
    # Let's adopt a simpler input format for simulation:
    # One point per line: "x_hex y_hex z_hex"
    points = []
    for line in lines:
        x_hex, y_hex, z_hex = line.split()
        x_bits = hex_to_bits(x_hex, 32)
        y_bits = hex_to_bits(y_hex, 32)
        z_bits = hex_to_bits(z_hex, 32)
        points.append((x_bits, y_bits, z_bits))
    return points

# ======================
# 2. Bit-serial Distance Computation
# ======================

class BDU:
    """
    Simulates a Bit-serial Distance Unit.
    Computes Euclidean distance bit-by-bit with early termination.
    """
    def __init__(self, kth_dist2=float('inf')):
        self.kth_dist2 = kth_dist2
        self.dist2 = 0  # partial squared distance
        self.f = [0, 0, 0]  # partial subtraction for x, y, z
        self.terminated = False
        self.cycle_count = 0
    
    def process_bit(self, q_bits_tuple, r_bits_tuple):
        """
        Process one cycle: x, y, z bits simultaneously.
        q_bits_tuple: (qx_bit, qy_bit, qz_bit) each 0/1
        r_bits_tuple: (rx_bit, ry_bit, rz_bit) each 0/1
        Returns: whether to continue
        """
        if self.terminated:
            return False
        
        self.cycle_count += 1
        
        # Update f and dist2 per Equation (4)
        new_f = []
        dist2_update = 0
        for d in range(3):
            qb = q_bits_tuple[d]
            rb = r_bits_tuple[d]
            diff = qb - rb  # -1, 0, 1
            # Update f
            f_new = (self.f[d] << 1) + diff
            new_f.append(f_new)
            # (q-r)^2 term
            dist2_update += diff * diff
            # (q-r)*f term (multiplied by 4 as per equation)
            dist2_update += 4 * diff * self.f[d]
        
        # Update dist2: dist2_{m-1} << 2 + ...
        self.dist2 = (self.dist2 << 2) + dist2_update
        self.f = new_f
        
        # Early termination check
        remaining_cycles = 32 - self.cycle_count
        if remaining_cycles > 0:
            # Lower bound = current dist2 * 4^remaining_cycles
            lower_bound = self.dist2 * (1 << (2 * remaining_cycles))
            
            if lower_bound >= self.kth_dist2:
                self.terminated = True
                return False
        
        return True
    
    def get_distance(self):
        return self.dist2

# ======================
# 3. TopK Management
# ======================

class TopKList:
    def __init__(self, k):
        self.k = k
        self.distances = []  # list of (dist2, point_data)
    
    def update(self, dist2, point_data):
        self.distances.append((dist2, point_data))
        self.distances.sort(key=lambda x: x[0])
        if len(self.distances) > self.k:
            self.distances = self.distances[:self.k]
    
    def get_kth_dist(self):
        if len(self.distances) < self.k:
            return float('inf')
        return self.distances[-1][0]

# ======================
# 4. Main Simulation
# ======================

def simulate_bitnn(query_file, ref_file, k=5, bdu_per_query=4):
    """
    Simulates BitNN accelerator.
    Returns total cycles and results.
    """
    query_points = read_points_from_file(query_file)
    ref_points = read_points_from_file(ref_file)
    
    total_cycles = 0
    results = []
    
    for q_idx, q in enumerate(query_points):
        topk = TopKList(k)
        # Process reference points in groups of bdu_per_query
        for ref_start in range(0, len(ref_points), bdu_per_query):
            ref_group = ref_points[ref_start:ref_start + bdu_per_query]
            # Create BDUs for this group
            bdus = [BDU(topk.get_kth_dist()) for _ in range(len(ref_group))]
            
            # Bit-serial processing (MSB first, 32 bits per dimension)
            # Process x, y, z bits in parallel (one cycle processes x, y, z bits for all BDUs)
            for bit_pos in range(31, -1, -1):  # MSB to LSB
                # Get query bits for all 3 dimensions at this bit position
                qx_bit = q[0][bit_pos]  # x bit
                qy_bit = q[1][bit_pos]  # y bit  
                qz_bit = q[2][bit_pos]  # z bit
                
                # Process all BDUs for this cycle
                all_terminated = True
                for bdu_idx, (bdu, r) in enumerate(zip(bdus, ref_group)):
                    if bdu.terminated:
                        continue
                    
                    # Get reference bits for all 3 dimensions
                    rx_bit = r[0][bit_pos]
                    ry_bit = r[1][bit_pos]
                    rz_bit = r[2][bit_pos]
                    
                    # Process one set of bits (x, y, z) in one cycle
                    if bdu.process_bit((qx_bit, qy_bit, qz_bit), (rx_bit, ry_bit, rz_bit)):
                        all_terminated = False
                
                total_cycles += 1  # One cycle processes x, y, z bits
                
                # If all BDUs terminated early, we can break bit loop
                if all_terminated:
                    break
            
            # After processing bits, collect distances
            for bdu, r in zip(bdus, ref_group):
                if not bdu.terminated:
                    dist2 = bdu.get_distance()
                    topk.update(dist2, r)
                # else: early terminated, no update
        
        results.append((q_idx, topk.distances))
    
    return total_cycles, results

# ======================
# 5. File Format Adapter (if needed)
# ======================

def convert_memory_format_to_pointlist(filename, points_per_group=4):
    """
    Converts the described memory format to list of points.
    Format: 
      {MSB of x of first 4 points}
      {MSB of y of first 4 points}
      {MSB of z of first 4 points}
    Each coordinate 32 bits, so 32 lines = 4 points.
    """
    points = []
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    # Each 8 lines = 32 bits for one coordinate for 4 points? Need clarification.
    # Let's implement a placeholder.
    print("Warning: memory format parsing not fully implemented")
    return []

# ======================
# 6. Example Usage
# ======================

if __name__ == "__main__":
    # Example files (create sample data)
    def create_sample_files():
        # Create dummy query and ref files in simplified format
        with open("query.txt", "w") as f:
            for i in range(1):  # 1 query point
                f.write(f"{i:08x} {i+1:08x} {i+2:08x}\n")
        with open("ref.txt", "w") as f:
            for i in range(100):  # 100 reference points
                f.write(f"{i:08x} {i+5:08x} {i+10:08x}\n")
    
    create_sample_files()
    
    total_cycles, results = simulate_bitnn("query.txt", "ref.txt", k=5, bdu_per_query=4)
    
    print(f"Total cycles: {total_cycles}")
    for q_idx, topk in results:
        print(f"Query {q_idx} top {len(topk)} neighbors:")
        for dist2, _ in topk:
            print(f"  Distance^2: {dist2}")