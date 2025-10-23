import numpy as np
import basic_knn_search


def run_basic_functionality_test():
    """
    Tests basic_knn_search and prints a pass/fail message.
    """
    query = np.array([0.0, 0.0])
    reference = np.array([
        [2.0, 0.0],  # Index 0, Dist^2=4
        [1.0, 0.0],  # Index 1, Dist^2=1 (Expected 1st NN)
        [0.0, 3.0],  # Index 2, Dist^2=9
        [1.5, 0.0],  # Index 3, Dist^2=2.25 (Expected 2nd NN)
        [1.4, 1.4]   # Index 4, Dist^2=3.92 (Expected 3rd NN)
    ])
    k = 3
    
    expected_indices = [1, 3, 4]
    
    print("\n" + "="*60)
    print("RUNNING BASIC FUNCTIONALITY CHECK...")
    print(f"Query: {query}, k={k}")
    
    # --- 2. Execute the Algorithm ---
    try:
        actual_results = basic_knn_search.basic_knn_search(query, reference, k)
    except Exception as e:
        print("\n FUNCTION FAILED: An exception occurred during execution.")
        print(f"Error: {e}")
        return
    
    # --- 3. Verification and Output ---
    
    # Extract the indices from the results: [(dist1, idx1), (dist2, idx2), ...]
    actual_indices = [idx for dist, idx in actual_results]
    
    # Check 1: Did we get the right number of results?
    if len(actual_results) != k:
        print(f"\n FAILED: Expected {k} results, got {len(actual_results)}.")
        return
    
    # Check 2: Did we get the correct indices?
    if actual_indices == expected_indices:
        print("\n **SUCCESS!**")
        print("The kNN algorithm works correctly and found the expected nearest neighbors.")
        print(f"Output Indices (Expected: {expected_indices}): {actual_indices}")
        print("="*60)
    else:
        print("\n **FAILED!**")
        print("The algorithm produced incorrect neighbors.")
        print(f"Expected Indices: {expected_indices}")
        print(f"Actual Indices:   {actual_indices}")
        print("="*60)

# Run the simplified test
if __name__ == '__main__':
    run_basic_functionality_test()