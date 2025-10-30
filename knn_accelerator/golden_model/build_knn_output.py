import numpy as np
import pandas as pd
import basic_knn_search
from tqdm import tqdm
import os


def build_knn_table(npy_path, k, output_basename="knn_indices"):
    """
    Loads a .npy dataset of feature vectors, treats all points as both
    reference and query, and runs basic_knn_search for each query point.
    
    Saves results as both .npy (binary array) and .csv (human-readable table).
    """
    # 1. Load dataset
    print(f"Loading dataset from {npy_path} ...")
    data = np.load(npy_path)
    N, D = data.shape
    print(f"Loaded {N} points with dimension {D}.")

    # 2. Prepare storage for neighbor indices
    all_indices = np.zeros((N, k), dtype=int)

    # 3. Compute neighbors for each query
    print(f"Computing {k}-nearest neighbors for each point ...")
    for i in tqdm(range(N)):
        query = data[i]
        try:
            results = basic_knn_search.basic_knn_search(query, data, k)
        except Exception as e:
            print(f"Error on query {i}: {e}")
            continue

        # Extract indices from [(dist, idx), ...]
        neighbor_indices = [idx for _, idx in results]
        all_indices[i, :] = neighbor_indices

    # 4. Save as .npy
    npy_path_out = f"../verification/test_output/{output_basename}.npy"
    np.save(npy_path_out, all_indices)
    print(f"\nSaved binary NumPy results to {npy_path_out}")

    # 5. Also save as .csv for easy viewing
    csv_path_out = f"../verification/test_output/{output_basename}.csv"
    df = pd.DataFrame(all_indices)
    df.to_csv(csv_path_out, index=False, header=[f"NN_{i+1}" for i in range(k)])
    print(f"Saved CSV table to {csv_path_out}")

    # 6. Preview first few rows
    print("\nExample (first 5 rows):")
    print(df.head())


if __name__ == "__main__":
    # Example usage
    npy_path = "../verification/datasets/oxford_2015-03-17-11-08-44_stereo_left.npy"    # Path to your descriptor .npy file
    k = 10                          # Number of neighbors
    build_knn_table(npy_path, k, "oxford_2015_knn_indices")