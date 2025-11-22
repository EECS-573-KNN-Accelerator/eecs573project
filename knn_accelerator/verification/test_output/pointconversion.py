import pandas as pd

import os

script_dir = os.getcwd()  # current working directory

csv_file = os.path.join(script_dir, "knn_accelerator", "verification", "test_output", "oxford_2015_knn_indices.csv")
output_file = os.path.join(script_dir, "output_hex.txt")


# header=0 considers first row as column names
df = pd.read_csv(csv_file, header=0)
hex_output = []


for block_start in range(0, len(df), 4):

    block = df.iloc[block_start:block_start+4].copy()

    while len(block) < 4:
        block.loc[len(block)] = [0] * len(df.columns)

    bin_x, bin_y, bin_z = [], [], []


    for i in range(4):
        row = block.iloc[i]
        #considering first value in each row is index, so considering calues from index 1
        x, y, z = row.iloc[1:4]  

        bx = format(int(x), '032b')
        by = format(int(y), '032b')
        bz = format(int(z), '032b')

        bin_x.append(bx)
        bin_y.append(by)
        bin_z.append(bz)


    for bit in range(32):
        four_x = bin_x[0][bit] + bin_x[1][bit] + bin_x[2][bit] + bin_x[3][bit]
        four_y = bin_y[0][bit] + bin_y[1][bit] + bin_y[2][bit] + bin_y[3][bit]
        four_z = bin_z[0][bit] + bin_z[1][bit] + bin_z[2][bit] + bin_z[3][bit]

        combined_16 = four_x + four_y + four_z + "0000"
        hex16 = format(int(combined_16, 2), '04x')

        hex_output.append(hex16)


rows = []
for i in range(0, len(hex_output), 4):
    row_hex = "".join(hex_output[i:i+4])
    rows.append(row_hex)

# Save to file 
with open(output_file, "w") as f:
    for row in rows:
        f.write(row + "\n")

print(f"Processed {len(df)} data rows.")
print(f"Output saved to {output_file}")
