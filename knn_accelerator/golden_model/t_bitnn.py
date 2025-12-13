import math
import csv
import matplotlib.pyplot as plt

K = 3
NUM_BITS = 32
NUM_BDU = 64

def BDU(q_coor_tuple, r_coor_tuple, threshold):

    cycles = 0
    f = [0,0,0]
    dist2 = 0
    lower2 = 0
    currLower = 0

    for i in range (NUM_BITS - 1, -1, -1):
        dist2 = dist2 << 2

        h = [0,0,0]

        for d in range(3):
            
            h = [0,0,0]

            q_bit = (q_coor_tuple[d] >> i) & 1
            r_bit = (r_coor_tuple[d] >> i) & 1

            dist2 += (q_bit - r_bit) ** 2
            dist2 += ((q_bit - r_bit)*f[d]) << 2

            f[d] = (f[d] << 1) + (q_bit - r_bit)

            lower2 = dist2 * (2 ** (2*(i)))

            for j in range(3):
                if f[j] == 0:
                    h[j] = 0
                else:
                    h[j] = (2 * abs(f[j])) - 1

                lower2 -= h[j] * (2 ** (2*(i)))

            if dist2 > lower2:
                currLower = dist2
            else:
                currLower = lower2

            cycles += 1
            
            if d == 2 and threshold <= currLower:
                if r_coor_tuple == [98485, 89328, 87016]:
                    print(i, dist2, threshold, currLower)
                # print(dist2, currLower)
                return False, cycles, currLower
    
    return True, cycles, dist2

# 81225 + 466489

def TopKupdate (oldTopK, r_coor, newdist2):
    newTopK = []
    newTopK = oldTopK
    newTopK.append((newdist2, r_coor))
    newTopK.sort()
    if(len(newTopK) > K):
        newTopK = newTopK[:K]

    threshold = newTopK[-1][0]

    return newTopK, threshold


def simulateBitNN(q_list, r_list):

    total_cycles = 0

    # >>> Stats arrays for logging <<< 
    query_indices = []
    early_list = []
    full_list = []
    avg_cycles_list = []
    max_cycles_list = []
    threshold_list = []

    query_id = 0
    
    for q in q_list:
        query_id += 1
        threshold = 9999999999999
        TopK = []
        
        query_early = 0
        query_full = 0
        query_cycles = []
        
        for r in range(0, len(r_list), NUM_BDU):
            done = [False] * NUM_BDU
            cycles = [0] * NUM_BDU
            dist2 = [0] * NUM_BDU

            for i in range(NUM_BDU):
                # print("r: ", r)
                # print(r+i)
                done[i], cycles[i], dist2[i] = BDU(q, r_list[r+i], threshold)
                
                # Track early vs full terminations
                if done[i] is False:
                    query_early += 1
                else:
                    query_full += 1

            for i in range(NUM_BDU):
                if done[i]:
                    # print(threshold, dist2[i])
                    TopK, threshold = TopKupdate(TopK, r_list[r+i], dist2[i])
        

            max_cycles = max(cycles)
            total_cycles += max_cycles
            query_cycles.extend(cycles)

            total_cycles += NUM_BDU # latency for shifting things into TopK
        
        avg_cyc = sum(query_cycles) / len(query_cycles)
        max_cyc = max(query_cycles)
        
        print(f"\n=== Query {query_id} Statistics ===")
        print(f"  Query Coordinates     : {q}")
        print(f"  Early terminated BDUs : {query_early}")
        print(f"  Full BDUs completed   : {query_full}")
        print(f"  Avg BDU cycles        : {avg_cyc:.2f}")
        print(f"  Max BDU cycles        : {max_cyc}")
        print(f"  Final TopK threshold  : {threshold}")
        print(f"  TopK list             : {TopK}")
        
        # >>> Save stats <<<
        query_indices.append(query_id)
        early_list.append(query_early)
        full_list.append(query_full)
        avg_cycles_list.append(avg_cyc)
        max_cycles_list.append(max_cyc)
        threshold_list.append(threshold)
    
    # ============ GRAPHS ============
    def save_graph(x, y, title, ylabel, filename):
        plt.figure(figsize=(10, 4))
        plt.plot(x, y)
        plt.title(title)
        plt.xlabel("Query Index")
        plt.ylabel(ylabel)
        plt.grid(True)

        # Add more ticks (20 evenly spaced ticks)
        step = max(1, len(x) // 20)
        plt.xticks(range(0, len(x)+1, step), rotation=45)

        plt.tight_layout()
        plt.savefig(filename)
        plt.close()

    save_graph(query_indices, early_list,
               "Early Terminated BDUs per Query",
               "Early Terminations",
               "t_bitnn_early_terminations.png")

    save_graph(query_indices, full_list,
               "Full BDU Evaluations per Query",
               "Full Evaluations",
               "t_bitnn_full_terminations.png")

    save_graph(query_indices, avg_cycles_list,
               "Average BDU Cycles per Query",
               "Average Cycles",
               "t_bitnn_avg_cycles.png")

    save_graph(query_indices, max_cycles_list,
               "Max BDU Cycles per Query",
               "Max Cycles",
               "t_bitnn_max_cycles.png")

    save_graph(query_indices, threshold_list,
               "TopK Threshold per Query",
               "Threshold Value",
               "t_bitnn_thresholds.png")

    print("\nSaved graphs:")
    print(" t_bitnn_early_terminations.png")
    print(" t_bitnn_full_terminations.png")
    print(" t_bitnn_avg_cycles.png")
    print(" t_bitnn_max_cycles.png")
    print(" t_bitnn_thresholds.png")
    
    return total_cycles


if __name__ == "__main__":
    
    
    # Load reference points from synthetic_knn_data.csv
    r_list = []
    with open("../verification/datasets/synthetic_knn_data.csv", 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            r_list.append([int(v) for v in row])

    # cut to 4544 point 
    r_list = r_list[:4544]
    # Load query points from synthetic_knn_query.csv
    q_list = []
    with open("../verification/datasets/synthetic_knn_query.csv", 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            q_list.append([int(v) for v in row])
    # cut to 4544 point
    q_list = q_list[:4544]

    # q_list = [[103478, 97132, 92140]]
    
    # print(f"Loaded {len(r_list)} reference points")
    # print(f"Loaded {len(q_list)} query points")
    
    total_cycles = simulateBitNN(q_list, r_list)

    print(total_cycles)
