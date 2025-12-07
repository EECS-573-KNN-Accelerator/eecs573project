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
                print(dist2, currLower)
                return False, cycles, dist2
    
    print(dist2)
    
    return True, cycles, dist2



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
    
    for q in q_list:
        threshold = 9999999
        TopK = []
        for r in range(0, len(r_list), 4):
            done = [False, False, False, False]
            cycles = [0,0,0,0]
            dist2 = [0,0,0,0]

            for i in range(4):
                print("r: ", r)
                print(r+i)
                done[i], cycles[i], dist2[i] = BDU(q, r_list[r+i], threshold)

            for i in range(4):
                if done[i]:
                    TopK, threshold = TopKupdate(TopK, r_list[r+i], dist2[i])
        

            max_cycles = max(cycles)
            total_cycles += max_cycles

            total_cycles += 4 # latency for shifting things into TopK
        
        print("topk: ", TopK)
    
    return total_cycles


if __name__ == "__main__":
    q_list = [[0,0,1], [0,0,2], [0,0,3]]
    r_list = [[0,0,2], [0,0,3], [23,24,25], [3,4,5,6], [1500,1324,9288], [5162,1221,3230], [5463,5438,6363], [1234,1234,8272]]
    # r_list = [[2342,2323,2322], [1233,1230,1233], [2333,2433,2335], [2322,3334,1315], [15,13,92], [1,4,3], [0,0,3], [2,4,2]]

    total_cycles = simulateBitNN(q_list, r_list)

    print(total_cycles)





        
