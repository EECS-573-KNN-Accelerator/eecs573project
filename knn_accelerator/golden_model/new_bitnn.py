import math

K = 3
NUM_BITS = 32

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
                return False, cycles, dist2
    
    return True, cycles, dist2



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
    
    newTopK.sort()

    if len(newTopK) == 0 or newTopK[-1][2] is False:
        threshold = meanThreshold
    else:
        threshold = newTopK[-1][0]

    return newTopK, threshold, cycles


def runningMeanDistance(lastkthdist):

    total = 0

    for dist in lastkthdist:
        total += dist
    
    return total / len(lastkthdist)



def simulateBitNN(q_list, r_list):

    total_cycles = 0

    prevTopK = []

    lastkthdist = [99999]*10 # choose 10 arbitrarily
    
    for q in q_list:
        meanThreshold = runningMeanDistance(lastkthdist)
        TopK, threshold, added_cycles = recomputeTopK(q, prevTopK, meanThreshold)
        total_cycles += added_cycles
        for r in range(0, len(r_list), 4):
            done = [False, False, False, False]
            cycles = [0,0,0,0]
            dist2 = [0,0,0,0]

            for i in range(4):
                done[i], cycles[i], dist2[i] = BDU(q, r_list[r+i], threshold)

            for i in range(4):
                if done[i]:
                    TopK, threshold = TopKupdate(TopK, r_list[r+i], dist2[i], True, meanThreshold)
                else:
                    TopK, threshold = TopKupdate(TopK, r_list[r+i], dist2[i], False, meanThreshold)
        

            max_cycles = max(cycles)
            total_cycles += max_cycles

            total_cycles += 4 # latency for shifting things into TopK
        
        print("topk: ", TopK)
        prevTopK = TopK
        lastkthdist = lastkthdist[1:] + [threshold]
    
    return total_cycles


if __name__ == "__main__":
    q_list = [[0,0,1], [0,0,2], [0,0,3]]
    # r_list = [[0,0,2], [0,0,3], [23,24,25], [3,4,5,6], [1500,1324,9288], [5162,1221,3230], [5463,5438,6363], [1234,1234,8272]]
    r_list = [[2342,2323,2322], [1233,1230,1233], [2333,2433,2335], [2322,3334,1315], [15,13,92], [1,4,3], [0,0,3], [2,4,2]]

    total_cycles = simulateBitNN(q_list, r_list)

    print(total_cycles)
