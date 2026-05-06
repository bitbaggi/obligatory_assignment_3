from itertools import product
from subprocess import call
runs = "3"

def run_config(filename, n_nodes, e_edges):
    print(f"############## Run config - n = {n_nodes}; e = {e_edges} ##############")
    print(f"# # # # # # # sequential # # # # # # #")
    call(["./sequential",
          f"./graphs/{filename}_{n_nodes}_{e_edges}.mtx",
          f"./results/seq/{filename}_{n_nodes}_{e_edges}.txt",
          f"{runs}"]
         )
    print(f"# # # # # # node_parallel # # # # # #")
    call(["./node_parallel",
          f"./graphs/{filename}_{n_nodes}_{e_edges}.mtx",
          f"./results/node_par/{filename}_{n_nodes}_{e_edges}.txt",
          f"{runs}"]
         )
    print(f"# # # # # # all_parallel # # # # # # ")
    call(["./all_parallel",
          f"./graphs/{filename}_{n_nodes}_{e_edges}.mtx",
          f"./results/all_par/{filename}_{n_nodes}_{e_edges}.txt",
          f"{runs}"]
         )


for i, j in product(
        [10000, 20000, 30000, 40000, 50000],
        range(100000, 1000001, 100000)
):
    run_config("graph", i, j)
