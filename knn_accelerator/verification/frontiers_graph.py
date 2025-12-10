import matplotlib.pyplot as plt

# =============================================================================
# DATA POINTS - Easy to add new entries
# Format: (validity, speedup_percent, label)
# =============================================================================
data_points = [
    (0.14533, 10.15, "1x running mean"),
    (0.592,   9.72, "2x running mean"),
    (0.78266, 9.46, "3x running mean"),
    (0.87733, 9.33, "4x running mean"),
    (0.93133, 9.26, "5x running mean"),
    (0.95533, 9.22, "6x running mean"),

    # Add new points here:
    # (validity, speedup_percent, "label"),
]

# =============================================================================
# PLOTTING
# =============================================================================
# Extract data
validities = [p[0] for p in data_points]
speedups = [p[1] for p in data_points]
labels = [p[2] for p in data_points]

# Create figure
fig, ax = plt.subplots(figsize=(10, 6))

# Plot points and connecting line
ax.plot(validities, speedups, 'o-', markersize=10, linewidth=2, color='#2E86AB')

# Add labels to each point
for x, y, label in data_points:
    ax.annotate(label, (x, y), textcoords="offset points", 
                xytext=(0, 5), ha='center', fontsize=9)

# Labels and title
ax.set_xlabel('Validity', fontsize=12)
ax.set_ylabel('Speedup (% fewer cycles)', fontsize=12)
ax.set_title('Validity vs Speedup Frontier', fontsize=14, fontweight='bold')

# Grid and styling
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 1.0)
ax.set_ylim(9.0, 10.5)

plt.tight_layout()
plt.savefig('./frontier_graph.png', dpi=150)
plt.show()

print("Graph saved to frontier_graph.png")