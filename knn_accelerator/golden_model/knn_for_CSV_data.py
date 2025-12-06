import numpy as np
import pandas as pd
import basic_knn_search
from tqdm import tqdm
import os

def build_knn_table_from_csv(input_csv, k, output_basename="knn_indices"):
    """
    Loads a CSV of points (each row is a vector), runs KNN among all points,
    and saves the resulting neighbor indices.
    """
    # 1. Load dataset
    print(f"Loading dataset from {input_csv} ...")
    data = pd.read_csv(input_csv, header=None).values.astype(float)
    N, D = data.shape
    print(f"Loaded {N} points with dimension {D}.")

    # 2. Prepare storage
    all_indices = np.zeros((N, k), dtype=int)

    # 3. Compute KNN for each point
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


    # 5. Save as .csv
    csv_out = f"{output_basename}.csv"
    df = pd.DataFrame(all_indices)
    df.to_csv(csv_out, index=False, header=[f"NN_{i+1}" for i in range(k)])
    print(f"Saved CSV table to {csv_out}")

    # Preview
    # Print first 5 points with their 10 KNN
    print("First 5 points with their KNN:")
    for i in range(min(5, N)):
        print(f"Point {i}: {data[i]}")
        print(f"  KNN indices: {all_indices[i]}")
        print(f"  KNN points: {data[all_indices[i]]}")
    print("\nExample (first 5 rows):")
    print(df.head())

if __name__ == "__main__":
    # Write your input into a file named "input_points.csv" in the same directory
    input_csv = "/home/aphatke/EECS573/eecs573project/knn_accelerator/verification/datasets/synthetic_knn_data.csv"
    k = 10
    build_knn_table_from_csv(input_csv, k, "example_knn_output")
