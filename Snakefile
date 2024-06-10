GTDB = 'gtdb-rs214-k21.zip'

rule all:
    input:
        "gtdb-rs214-k21.mf.csv",
        "ecoli.30.cmp.png",
        "ecoli.30.cmp.cut.png",
        "ecoli.30.ani.cmp.png",
        "ecoli-cluster.sig.zip",
        "ecoli-cluster.upset.png",
        "ecoli.1000.sig.zip",
        "ecoli.1000.pairwise.png",

rule extract_mf:
    input:
        GTDB
    output:
        protected("gtdb-rs214-k21.mf.csv")
    shell: """
        sourmash sig manifest {input} -o {output} --no-rebuild
    """

rule mf_30:
    input:
        "gtdb-rs214-k21.mf.csv"
    output:
        "ecoli.30.mf.csv"
    shell: """
        head -2 {input} > {output}
        egrep -v "MANIFEST|internal_location" {input} | grep -i Escheric | tail -30 >> {output}
    """

rule mf_1000:
    input:
        "gtdb-rs214-k21.mf.csv"
    output:
        "ecoli.1000.mf.csv"
    shell: """
        head -2 {input} > {output}
        egrep -v "MANIFEST|internal_location" {input} | grep -i Escheric | tail -1000 >> {output}
    """

rule sig_30:
    input:
        db=GTDB,
        mf="ecoli.30.mf.csv",
    output:
        protected("ecoli.30.sig.zip")
    shell: "sourmash sig cat --picklist {input.mf}::manifest {input.db} -o {output}"

rule sig_1000:
    input:
        db=GTDB,
        mf="ecoli.1000.mf.csv",
    output:
        protected("ecoli.1000.sig.zip")
    shell: "sourmash sig cat --picklist {input.mf}::manifest {input.db} -o {output}"

rule cmp_30:
    input: "ecoli.30.sig.zip"
    output:
        cmp="ecoli.30.cmp",
        labels="ecoli.30.labels_to.csv",
    shell: "sourmash compare {input} -o {output.cmp} --labels-to {output.labels}"

rule plot_30:
    input:
        cmp="ecoli.30.cmp",
        labels="ecoli.30.labels_to.csv",
    output:
        "ecoli.30.cmp.png",
    shell: """
        sourmash scripts plot2 {input.cmp} {input.labels} -o {output}
    """

rule plot_30_cut:
    input:
        cmp="ecoli.30.cmp",
        labels="ecoli.30.labels_to.csv",
    output:
        fig="ecoli.30.cmp.cut.png",
        csv="ecoli.30.cmp.2.csv",
    shell: """
        sourmash scripts plot2 {input.cmp} {input.labels} -o {output.fig} \
            --cut 0.9 --cluster-out
    """

rule cmp_30_ani:
    input: "ecoli.30.sig.zip"
    output:
        cmp="ecoli.30.ani.cmp",
        labels="ecoli.30.ani.labels_to.csv",
    shell: "sourmash compare {input} -o {output.cmp} --labels-to {output.labels} --ani"

rule plot_30_ani:
    input:
        cmp="ecoli.30.ani.cmp",
        labels="ecoli.30.ani.labels_to.csv",
    output:
        "ecoli.30.ani.cmp.png",
    shell: """
        sourmash scripts plot2 {input.cmp} {input.labels} -o {output}  \
           --vmin=0.93
    """

rule cluster_examine:
    input:
        csv="ecoli.30.cmp.2.csv",
        sigs="ecoli.30.sig.zip",
    output:
        "ecoli-cluster.sig.zip"
    shell: """
        sourmash sig cat {input.sigs} -o {output} --picklist {input.csv}:label:ident
    """
        
rule cluster_upset:
    input:
        sigs="ecoli-cluster.sig.zip",
    output:
        "ecoli-cluster.upset.png"
    shell: """
        sourmash scripts upset {input} -o {output} -k 21 --show-singleton
    """

rule pairwise_1k_ecoli:
    input:
        "ecoli.1000.sig.zip",
    output:
        "ecoli.1000.pairwise.csv",
    shell: """
        sourmash scripts pairwise {input} -o {output} -k 21
    """

rule pairwise_1k_ecoli_cluster:
    input:
        "ecoli.1000.pairwise.csv",
    output:
        clusters="ecoli.1000.pairwise.clusters.csv",
        sizes="ecoli.1000.pairwise.cluster_sizes.csv",
    shell: """
        sourmash scripts cluster {input} -o {output.clusters} \
            --cluster-sizes {output.sizes} --similarity jaccard -t 0.5
    """

rule pairwise_1k_ecoli_cluster_categories:
    input:
        samples="ecoli.1000.pairwise.csv",
        clusters="ecoli.1000.pairwise.clusters.csv",
    output:
        "ecoli.1000.pairwise.clusters.categories.csv",
    shell: """
        sourmash scripts cluster_to_categories {input.samples} \
            {input.clusters} -o {output}
    """

rule pairwise_1k_ecoli_plot:
    input:
        cmp="ecoli.1000.pairwise.csv",
        cats="ecoli.1000.pairwise.clusters.categories.csv",
    output:
        "ecoli.1000.pairwise.png",
    shell: """
        sourmash scripts mds2 {input.cmp} -o {output} -C {input.cats}
    """

# sourmash scripts pangenome_merge ecoli.1000.sig.zip -o ecoli.1000.merged.sig.zip -k 21
# sourmash scripts pangenome_ranktable ecoli.1000.merged.sig.zip -o ecoli.1000.merged.csv -k 21
# ../2024-pangenome-hash-corr/calc-hash-presence.py ecoli.1000.merged.csv ecoli.1000.sig.zip -o ecoli.1000.dump
# ../2024-pangenome-hash-corr/hash-by-sample.py ecoli.1000.dump -o ecoli.1000.presence.csv -C ecoli.1000.categories.csv
# sourmash scripts clustermap1 ecoli.1000.presence.csv -o ecoli.1000.presence.png -u "presence" --bool --no-labels -C ecoli.1000.categories.csv
