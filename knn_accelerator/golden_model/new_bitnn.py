import math
import csv
import matplotlib.pyplot as plt


K = 3
NUM_BITS = 32
NUM_BDU = 64

# BDU Module
def BDU(q_coor_tuple, r_coor_tuple, threshold):

    cycles = 0
    f = [0,0,0]
    dist2 = 0
    lower2 = 0
    currLower = 0

    for i in range (NUM_BITS - 1, -1, -1):
        dist2 = dist2 << 2

        h = [0,0,0]

        lower2 = dist2 * (2 ** (2*(i)))

        for d in range(3):
            q_bit = (q_coor_tuple[d] >> i) & 1
            r_bit = (r_coor_tuple[d] >> i) & 1

            dist2 += (q_bit - r_bit) ** 2
            dist2 += ((q_bit - r_bit)*f[d]) << 2

            f[d] = (f[d] << 1) + (q_bit - r_bit)

            if f[d] == 0:
                h[d] = 0
            else:
                h[d] = (2 * abs(f[d])) - 1

            lower2 -= h[d] * (2 ** (2*(i)))

            if dist2 > lower2:
                currLower = dist2
            else:
                currLower = lower2

            cycles += 1
            
            if threshold <= currLower:
                # print(dist2, currLower)
                return False, cycles, currLower
    
    return True, cycles, dist2



# Takes in the old TopK list and updates it with the new r_coor and its distance2
def TopKupdate (oldTopK, r_coor, newdist2, valid, prevThreshold):
    newTopK = []
    newTopK = oldTopK
    newTopK.append((newdist2, r_coor, valid))
    newTopK.sort()
    if(len(newTopK) > K):
        newTopK = newTopK[:K]
    
    if newTopK[-1][2] is False:
        threshold = prevThreshold
    else:
        threshold = newTopK[-1][0]

    return newTopK, threshold


# Recomputes the distances of the old TopK with the new query point
def recomputeTopK(newQ, oldTopK, meanThreshold):

    newTopK = []
    cycles = 0
    
    for k in oldTopK:
        newdist2 = 0
        newdist2 += (newQ[0] - k[1][0]) ** 2
        newdist2 += (newQ[1] - k[1][1]) ** 2
        newdist2 += (newQ[2] - k[1][2]) ** 2
        cycles += 1

        if(newdist2 > meanThreshold):
            newTopK.append((newdist2, k[1], False))
        else:
            newTopK.append((newdist2, k[1], True))
    
    newTopK.sort() # sort based on distance

    if len(newTopK) == 0 or newTopK[-1][2] is False:
        threshold = meanThreshold
    else:
        threshold = newTopK[-1][0]

    return newTopK, threshold, cycles

# Computes the running mean of the last kth distances
def runningMeanDistance(lastkthdist):
    total = 0

    for dist in lastkthdist:
        total += dist
    
    return total / len(lastkthdist)


def simulateBitNN(q_list, r_list):

    total_cycles = 0
    prevTopK = []
    lastkthdist = [999999999]*10

    # >>> Stats arrays <<< 
    query_indices = []
    early_list = []
    full_list = []
    avg_cycles_list = []
    max_cycles_list = []
    threshold_list = []

    global_bdu_calls = 0
    global_early = 0
    global_full = 0
    global_max_cycle = 0

    query_id = 0

    for q in q_list:
        query_id += 1
        meanThreshold = runningMeanDistance(lastkthdist) * 2
        TopK, threshold, added_cycles = recomputeTopK(q, prevTopK, meanThreshold)
        total_cycles += added_cycles

        query_early = 0
        query_full = 0
        query_cycles = []

        for r in range(0, len(r_list), NUM_BDU):
            done = [False] * NUM_BDU
            cycles = [0] * NUM_BDU
            dist2 = [0] * NUM_BDU

            for i in range(NUM_BDU):
                global_bdu_calls += 1
                done[i], cycles[i], dist2[i] = BDU(q, r_list[r+i], threshold)

                if done[i] is False:
                    query_early += 1
                    global_early += 1
                else:
                    query_full += 1
                    global_full += 1

                global_max_cycle = max(global_max_cycle, cycles[i])

            # Update TopK
            for i in range(NUM_BDU):
                TopK, threshold = TopKupdate(
                    TopK, r_list[r+i], dist2[i], done[i], meanThreshold
                )

            query_cycles.extend(cycles)
            total_cycles += max(cycles)
            total_cycles += NUM_BDU

        avg_cyc = sum(query_cycles) / len(query_cycles)
        max_cyc = max(query_cycles)

        print(f"\n=== Query {query_id} Statistics ===")
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

        prevTopK = TopK
        lastkthdist = lastkthdist[1:] + [threshold]

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
               "new_bitnn_early_terminations.png")

    save_graph(query_indices, full_list,
               "Full BDU Evaluations per Query",
               "Full Evaluations",
               "new_bitnn_full_terminations.png")

    save_graph(query_indices, avg_cycles_list,
               "Average BDU Cycles per Query",
               "Average Cycles",
               "new_bitnn_avg_cycles.png")

    save_graph(query_indices, max_cycles_list,
               "Max BDU Cycles per Query",
               "Max Cycles",
               "new_bitnn_max_cycles.png")

    save_graph(query_indices, threshold_list,
               "TopK Threshold per Query",
               "Threshold Value",
               "new_bitnn_thresholds.png")

    print("\nSaved graphs:")
    print(" new_bitnn_early_terminations.png")
    print(" new_bitnn_full_terminations.png")
    print(" new_bitnn_avg_cycles.png")
    print(" new_bitnn_max_cycles.png")
    print(" new_bitnn_thresholds.png")

    return total_cycles



if __name__ == "__main__":

    r_list = [] 
    with open("../verification/datasets/synthetic_knn_data.csv", 'r') as f:
        reader = csv.reader(f)
        for row in reader:  
            r_list.append([int(v) for v in row])
    
    print(f"Loaded {len(r_list)} reference points")
    r_list = r_list[:4544]

    # Load query points from synthetic_knn_query.csv
    q_list = []
    with open("../verification/datasets/synthetic_knn_query.csv", 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            q_list.append([int(v) for v in row])
    print(f"Loaded {len(q_list)} query points")
    q_list = q_list[:4544]
    
    # print(f"Loaded {len(r_list)} reference points")
    # print(f"Loaded {len(q_list)} query points")
    
    total_cycles = simulateBitNN(q_list, r_list)
    print(total_cycles)
    
