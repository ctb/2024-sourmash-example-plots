#! /usr/bin/env python
"""
Convert sourmash_plugin_branchwater 'cluster' command output to categories CSV
for betterplot.
"""
import sys
import argparse
import csv
from collections import defaultdict


from sourmash_plugin_betterplot import manysearch_rows_to_index


def main():
    p = argparse.ArgumentParser()
    p.add_argument('manysearch_csv')
    p.add_argument('cluster_csv')
    p.add_argument('-o', '--output-categories-csv', required=True)
    args = p.parse_args()

    # load samples
    with open(args.manysearch_csv, newline='') as fp:
        r = csv.DictReader(fp)
        rows = list(r)

    samples_d = manysearch_rows_to_index(rows, column_name='both')
    print(f"loaded {len(samples_d)} samples from '{args.manysearch_csv}'")

    ident_d = {}
    for name, sample_idx in samples_d.items():
        ident = name.split(' ')[0]
        ident_d[ident] = name

    with open(args.cluster_csv, newline='') as fp:
        r = csv.DictReader(fp)
        rows = list(r)

    cluster_to_idents = defaultdict(set)
    for row in rows:
        cluster = row['cluster']
        nodes = row['nodes'].split(';')
        if len(nodes) == 1:
            cluster = 'unclustered'
        cluster_to_idents[cluster].update(nodes)

    print(f"loaded {len(cluster_to_idents)} clusters")
    print(f"{len(cluster_to_idents['unclustered'])} singletons => 'unclustered'")

    with open(args.output_categories_csv, 'w', newline='') as fp:
        w = csv.writer(fp)
        w.writerow(['label', 'category'])
        for cluster_name, idents in cluster_to_idents.items():
            for ident in idents:
                name = ident_d[ident]
                w.writerow([name, cluster_name])
    

if __name__ == '__main__':
    sys.exit(main())
