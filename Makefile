.PHONY: all clean cleanall

all:
	snakemake -c 4

clean:
	snakemake -c 4 --delete-all-output
	-rm -f *.png

cleanall: clean all
