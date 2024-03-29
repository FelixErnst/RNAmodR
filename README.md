# RNAmodR <img src="https://raw.githubusercontent.com/Bioconductor/BiocStickers/devel/RNAmodR/RNAmodR.png" height="300" align="right">

<!-- badges: start -->
[![R-CMD-check](https://github.com/FelixErnst/RNAmodR/workflows/R-CMD-check-bioc-devel/badge.svg)](https://github.com/FelixErnst/RNAmodR/actions/)
[![BioC Build](https://bioconductor.org/shields/build/devel/bioc/RNAmodR.svg)](http://bioconductor.org/checkResults/devel/bioc-LATEST/RNAmodR/)
[![codecov](https://codecov.io/gh/FelixErnst/RNAmodR/branch/devel/graph/badge.svg)](https://codecov.io/gh/FelixErnst/RNAmodR)
[![BioC Years](https://bioconductor.org/shields/years-in-bioc/RNAmodR.svg)](https://doi.org/doi:10.18129/B9.bioc.RNAmodR)
<!-- badges: end -->

Post-transcriptional modifications can be found abundantly in rRNA and tRNA and
can be detected classically via several strategies. However, difficulties arise
if the identity and the position of the modified nucleotides is to be determined
at the same time. Classically, a primer extension, a form of reverse
transcription (RT), would allow certain modifications to be accessed by blocks
during the RT or changes in the cDNA sequences. Other modification would
need to be selectively treated by chemical reactions to influence the outcome of
the reverse transcription.

With the increased availability of high throughput sequencing, these classical
methods were adapted to high throughput methods allowing more RNA molecules to
be accessed at the same time. With these advances post-transcriptional
modifications were also detected on mRNA. Among these high throughput techniques
are for example Pseudo-Seq ([Carlile et al. 2014](#Literature)), RiboMethSeq
([Birkedal et al. 2015](#Literature)) and AlkAnilineSeq 
([Marchand et al. 2018](#Literature)) each able to detect a specific type of 
modification from footprints in RNA-Seq data prepared with the selected methods.

Since similar pattern can be observed from some of these techniques, overlaps of
the bioinformatical pipeline already are and will become more frequent with new
emerging sequencing techniques.

# Installation

The current version of the `RNAmodR` package is available from Bioconductor.

```
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("RNAmodR")
library(RNAmodR)
```

# Introduction

`RNAmodR` implements classes and a workflow to detect post-transcriptional RNA
modifications in high throughput sequencing data. It can be easily adapted for
new methods and can help during the phase of initial method development as well
as more complex screenings.

Briefly, from the `SequenceData` and `SequenceDataFrame` classes, specific 
subclasses are derived for accessing specific aspects of aligned reads, e.g. 
5’-end positions or pileup data. With these, a `Modifier` class can be used to 
detect specific patterns for individual types of modifications. The 
`SequenceData` classes can be shared by different `Modifier` classes enabling 
easy adaptation to new methods and benefiting from other efforts in method
development.

Whereas, the `SequenceData` classes are used to hold the data, `Modifier`
classes are used to detect certain features within high throughput sequencing
data to assign the presence of specific modifications for an established
pattern. The `Modifier` class is virtual and can be adapted for individual
methods, whereas the type of nucleotide under investigation is specified by
inheriting from the virtual `RNAModifier` and `DNAModifier` classes. To fix 
the data processing and detection strategy, for each type of sequencing method 
a `Modifier` class can be developed alongside to detect  modifications.

For further details have a look at the vignette or the additional packages for
implementation examples:
- [RNAmodR.RiboMethSeq](https://doi.org/doi:10.18129/B9.bioc.RNAmodR.RiboMethSeq)
- [RNAmodR.AlkAnilineSeq](https://doi.org/doi:10.18129/B9.bioc.RNAmodR.AlkAnilineSeq)
- [RNAmodR.ML](https://doi.org/doi:10.18129/B9.bioc.RNAmodR.ML) for classes 
fascilitating machine learning approaches

# Literature

- Carlile, Thomas M., Maria F. Rojas-Duran, Boris Zinshteyn, Hakyung Shin,
Kristen M. Bartoli, and Wendy V. Gilbert (2014): “Pseudouridine Profiling Reveals
Regulated mRNA Pseudouridylation in Yeast and Human Cells.” Nature 515 (7525):
143–46.

- Birkedal, Ulf, Mikkel Christensen-Dalsgaard, Nicolai Krogh, Radhakrishnan
Sabarinathan, Jan Gorodkin, and Henrik Nielsen (2015): “Profiling of Ribose
Methylations in Rna by High-Throughput Sequencing.” Angewandte Chemie
(International Ed. In English) 54 (2): 451–55.
https://doi.org/10.1002/anie.201408362.

- Marchand, Virginie, Lilia Ayadi, __Felix G. M. Ernst__, Jasmin Hertler,
Valérie Bourguignon-Igel, Adeline Galvanin, Annika Kotter, Mark Helm, 
__Denis L. J. Lafontaine__, and Yuri Motorin (2018): “AlkAniline-Seq: Profiling 
of m7G and m3C Rna Modifications at Single Nucleotide Resolution.” Angewandte 
Chemie International Edition 57 (51): 16785–90. 
https://doi.org/10.1002/anie.201810946.
