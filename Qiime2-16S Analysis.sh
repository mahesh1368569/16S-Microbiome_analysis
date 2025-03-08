1.	Import data. (# the folder should only have the fastq files . no other files should be there)

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ponto-manifest.tsv \
  --output-path paired-end-demux.qza \
  --input-format PairedEndFastqManifestPhred33V2
1.	Summary

qiime demux summarize \
  --i-data  paired-end-demux.qza \
  --o-visualization  demux-paired-end.qzv

2.	Quality control -DADA2 based on the quality scores (It took 34 hrs on 10 nodes- Shadow cluter)
(Doing this by inspection of the quality plots is subjective, and so I use Zymo Research’s program FIGARO to find the parameters for me. See my tutorial on FIGARO for how to install and run Figaro)
time qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-paired-end.qza \
  --p-trim-left-f 1 \
  --p-trim-left-r 1 \
  --p-trunc-len-f 200 \
  --p-trunc-len-r 200 \
   --o-table table.qza \
  --o-representative-sequences repseqs.qza \
--o-denoising-stats denoising_stats.qza

qiime metadata tabulate \
  --m-input-file denoising_stats.qza \
  --o-visualization denoising_stats.qzv

4. Summary-  summarize your filtered/denoised data

qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file ponto-metadata.tsv
qiime feature-table tabulate-seqs \
  --i-data repseqs.qza \
  --o-visualization repseqs.qzv

5. Sequence Alignment and building phylogenetic tree
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences repseqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

6. Alpha and beta diversity analysis


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 51000 \
  --m-metadata-file ponto-metadata.tsv \
  --output-dir core-metrics-results
  
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file ponto-metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv
  
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file ponto-metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv
7. Taxonomic Analysis
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads repseqs.qza \
  --o-classification taxonomy.qza
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file ponto-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

8. Alpha rarefaction plotting

qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 66000 \
  --m-metadata-file ponto-metadata.tsv \
  --o-visualization alpha-rarefaction.qzv

Microbiome Analyst

Creating a BIOM table with taxonomy annotations
qiime tools export \
--input-path table.qza \
--output-path exported
qiime tools export \
--input-path taxonomy.qza \
--output-path exported
Change the first line of taxonomy.tsv (i.e. the header) to this:
#OTU ID	taxonomy	confidence

** make sure the tab spacing is  not lost when making the above change

biom add-metadata \
-i feature-table.biom \
-o table-with-taxonomy.biom \
--observation-metadata-fp taxonomy.tsv \
--sc-separated taxonomy 

Exporting a phylogenetic tree

qiime tools export \
  --input-path unrooted-tree.qza \
  --output-path exported-unrooted-tree

qiime tools export \
  --input-path rooted-tree.qza \
  --output-path exported-tree


Covert Biom-table to tsv
biom convert \
-i feature-table.biom  \
-o feature-table.txt \
--to-tsv

Relative Abundance for PAST – RDA

1.	create a feature table that has taxonomy instead of feature ID
qiime taxa collapse \
   --i-table table.qza \
    --i-taxonomy taxonomy_16s.qza \
    --p-level 2 \
    --o-collapsed-table phyla-table.qza
2.	convert this new frequency table to relative-frequency

qiime feature-table relative-frequency \
--i-table phyla-table.qza \
--o-realtive-frequency-table rel-phyla-table.qza

3.	Export

qiime tools export \
  --input-path rel-phyla-table.qza \
  --output-path exported-tree

4.	Convert biom to txt
biom convert \
 -i feature-table.biom \
-o rel-phyla-table.tsv \
--to-tsv

## Please cite QIIME2 original package refer online page for additional details
