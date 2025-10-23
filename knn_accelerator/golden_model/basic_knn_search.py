import numpy as np
import heapq

def basic_knn_search(query_point, reference_points, k):
  
    # Calculate the difference vector (Q_float - P_i_float)

    diff_float = reference_points - query_point 
    
    # Square the difference
    squared_diff_float = diff_float ** 2
    
    # Sum across the feature dimension (axis=1) to get the final squared distance.
    squared_distances_float = np.sum(squared_diff_float, axis=1) 
    

    max_heap = [] 
    
    for index, distance_float in enumerate(squared_distances_float):
        
        # We push the NEGATIVE of the float distance and the index
        if len(max_heap) < k:
            heapq.heappush(max_heap, (-distance_float, index))
        elif distance_float < -max_heap[0][0]: 
            # If current distance is smaller than the largest distance in the heap, 
            # pop the largest (-max_heap[0][0] is the current largest distance) and push the new one.
            heapq.heappop(max_heap)
            heapq.heappush(max_heap, (-distance_float, index))
    
    results = sorted([
        # Convert the negative distance back to a positive distance
        (-dist_float, index) 
        for dist_float, index in max_heap
    ], key=lambda x: x[0])
    
    return results

