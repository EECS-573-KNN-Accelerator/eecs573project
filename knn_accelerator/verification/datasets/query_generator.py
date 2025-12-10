import numpy as np
import csv

def load_reference_points(csv_file):
    """
    Load reference points from synthetic_knn_data.csv
    """
    points = []
    with open(csv_file, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            points.append([int(v) for v in row])
    return np.array(points, dtype=np.int64)


def generate_query_points(
    reference_points,
    n_queries=100,
    drift_scale=1500,
    jump_probability=0.1
):
    """
    Generates query points with temporal spatial locality.
    Adjacent queries are generally close to each other (smooth drift),
    with occasional random jumps to distant locations.
    
    Args:
        reference_points: (N, 3) array of reference points
        n_queries: Number of query points to generate
        drift_scale: Standard deviation of drift between adjacent queries
                     Smaller values = smoother trajectory
        jump_probability: Probability of jumping to a random reference point
                         (creates occasional large spatial jumps)
    
    Returns:
        query_points: (n_queries, 3) array of query points
    """
    
    query_points = np.zeros((n_queries, 3), dtype=np.int64)
    
    # Start at a random reference point
    current_point = reference_points[np.random.randint(0, len(reference_points))].astype(float)
    query_points[0] = current_point.astype(np.int64)
    
    for i in range(1, n_queries):
        # With small probability, jump to a random reference point
        if np.random.random() < jump_probability:
            current_point = reference_points[np.random.randint(0, len(reference_points))].astype(float)
        else:
            # Otherwise, drift smoothly from previous point
            drift = np.random.normal(loc=0, scale=drift_scale, size=3)
            current_point = current_point + drift
        
        query_points[i] = current_point.astype(np.int64)
    
    return query_points


def save_query_points(filename, query_points):
    """
    Save query points in CSV format (same as synthetic_knn_data.csv)
    """
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        for point in query_points:
            writer.writerow(point)


if __name__ == "__main__":
    # Load reference points
    ref_points = load_reference_points("synthetic_knn_data.csv")
    print(f"Loaded {len(ref_points)} reference points")
    print(f"Reference point range:")
    print(f"  X: [{ref_points[:, 0].min()}, {ref_points[:, 0].max()}]")
    print(f"  Y: [{ref_points[:, 1].min()}, {ref_points[:, 1].max()}]")
    print(f"  Z: [{ref_points[:, 2].min()}, {ref_points[:, 2].max()}]")
    
    # Generate query points with temporal spatial locality
    query_points = generate_query_points(
        ref_points,
        n_queries=500,
        drift_scale=1500,      # Controls smoothness: smaller = smoother trajectory
        jump_probability=0.1   # 10% chance of jumping to distant location
    )
    
    # Save query points
    save_query_points("synthetic_knn_query.csv", query_points)
    
    print(f"\nGenerated {len(query_points)} query points")
    print(f"Query point range:")
    print(f"  X: [{query_points[:, 0].min()}, {query_points[:, 0].max()}]")
    print(f"  Y: [{query_points[:, 1].min()}, {query_points[:, 1].max()}]")
    print(f"  Z: [{query_points[:, 2].min()}, {query_points[:, 2].max()}]")
    print("Saved to synthetic_knn_query.csv")
    
    print("\nFirst 5 query points:")
    print(query_points[:5])
