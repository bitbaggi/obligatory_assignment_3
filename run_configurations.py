from itertools import product
from subprocess import call
runs = "3"

def run_config(filename, n_nodes, e_edges):
    print(f"Run config - n = {n_nodes}; e = {e_edges}")
    print(f"# # # # # # # sequential # # # # # # #")
    call(["./sequential",
          f"./graphs/{filename}_{n_nodes}_{e_edges}.mtx",
          f"./results/seq/{filename}_{n_nodes}_{e_edges}.txt",
          f"{runs}"]
         )


for i, j in product([10000, 20000, 30000], range(1000, 510000, 100000)):
    run_config("graph", i, j)
