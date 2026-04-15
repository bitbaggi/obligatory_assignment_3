//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//
#pragma once
#include "edge.h"

void read_graph(const char* filename, struct Edge** edges, int* n, int* e);
void verify(int** bf_dist, int** fw_dist, int nodeCount);