context("argument normalization")
test_that("argument normalization:",{
  skip_on_bioc()
  library(RNAmodR.Data)
  library(rtracklayer)
  gff <- GFF3File(RNAmodR.Data.example.man.gff3())
  fasta <- unname(path(RNAmodR.Data.example.man.fasta()))
  bam <- unname(path(RNAmodR.Data.example.wt.1()))
  # .norm_gff
  expect_error(RNAmodR:::.norm_gff(),'argument "x" is missing')
  expect_error(RNAmodR:::.norm_gff(""),"The gff3 file does not exist")
  # .norm_annotation
  expect_error(RNAmodR:::.norm_annotation(),'argument "annotation" is missing')
  expect_error(RNAmodR:::.norm_annotation(""),"The gff3 file does not exist")
  actual <- RNAmodR:::.norm_annotation(gff)
  expect_s4_class(actual,"TxDb")
  grl <- GenomicFeatures::exonsBy(actual)
  expect_s4_class(grl,"GRangesList")
  expect_equal(length(grl),2L)
  expect_named(grl,c("1","2"))
  expect_equal(actual,RNAmodR:::.norm_annotation(actual))
  expect_equal(grl,RNAmodR:::.norm_annotation(grl))
  # .norm_annotation_GRangesList
  expect_error(RNAmodR:::.norm_annotation_GRangesList(),
               'argument "annotation" is missing')
  expect_error(RNAmodR:::.norm_annotation_GRangesList(""),
               "Elements of 'annotation' GRangesList")
  expect_error(RNAmodR:::.norm_annotation_GRangesList(grl[c(1,1)]),
               "Names of elements in 'annotation' GRangesList must be unique")
  expect_error(RNAmodR:::.norm_annotation_GRangesList(pc(grl,grl)),
               "'annotation' GRangesList must contain only non-overlapping")
  grl2 <- grl
  GenomicRanges::strand(grl2@unlistData) <- c("*","+")
  expect_error(RNAmodR:::.norm_annotation_GRangesList(grl2),
               "Invalid strand information. Strand must either be")
  expect_equal(grl,RNAmodR:::.norm_annotation_GRangesList(grl))
  # .norm_sequences
  expect_error(RNAmodR:::.norm_sequences(),'argument "seq" is missing')
  expect_error(RNAmodR:::.norm_sequences(""),
               "sequence files don't exist or cannot be accessed")
  actual <- RNAmodR:::.norm_sequences(fasta)
  expect_s4_class(actual,"FaFile")
  fafile <- actual
  # .norm_bamfiles
  expect_error(RNAmodR:::.norm_bamfiles(),'argument "x" is missing')
  expect_error(RNAmodR:::.norm_bamfiles(""),"Bam files do not exists at")
  expect_error(RNAmodR:::.norm_bamfiles(bam),
               "Names of BamFileList must either be 'treated' or 'control'")
  actual <- RNAmodR:::.norm_bamfiles(c(treated = unname(bam)))
  expect_s4_class(actual,"BamFileList")
  expect_named(actual,c("treated"))
  bf <- Rsamtools::BamFile(c(treated = bam))
  expect_error(RNAmodR:::.norm_bamfiles(bf),
               "Names of BamFileList must either be 'treated' or 'control'")
  actual <- RNAmodR:::.norm_bamfiles(c(treated = bf))
  expect_s4_class(actual,"BamFileList")
  expect_equal(actual, RNAmodR:::.norm_bamfiles(c(Treated = bf)))
  actual <- RNAmodR:::.norm_bamfiles(list(c(Treated = bf),c(Treated = bf)))
  expect_type(actual,"list")
  expect_s4_class(actual[[1]],"BamFileList")
  # .bam_header_to_seqinfo
  expect_error(RNAmodR:::.bam_header_to_seqinfo(),'argument "bfl" is missing')
  expect_error(RNAmodR:::.bam_header_to_seqinfo(""),"BamFileList required")
  actual <- RNAmodR:::.bam_header_to_seqinfo(bf)
  expect_s4_class(actual,"Seqinfo")
  seqinfo <- actual
  # .norm_seqinfo
  expect_error(RNAmodR:::.norm_seqinfo(),'argument "seqinfo" is missing')
  expect_error(RNAmodR:::.norm_seqinfo(""),
               "Input is not a Seqinfo object and could not be coerced to one")
  actual <- RNAmodR:::.norm_seqinfo(seqinfo)
  expect_equal(actual,seqinfo)
  # 
  expect_error(RNAmodR:::.norm_seqnames(),'argument "bamfiles" is missing')
  expect_error(RNAmodR:::.norm_seqnames(""),"BamFileList required")
  expect_error(RNAmodR:::.norm_seqnames(bf,""))
  expect_error(RNAmodR:::.norm_seqnames(bf,grl),'argument "sequences" is missing')
  expect_error(RNAmodR:::.norm_seqnames(bf,grl,fasta))
  actual <- RNAmodR:::.norm_seqnames(bf,grl,fafile)
  expect_equal(actual,seqinfo)
  seqinfo2 <- seqinfo[c("chr1","chr2","chr3"),]
  expect_equal(seqinfo2,RNAmodR:::.norm_seqnames(bf,grl,fafile,seqinfo2))
  # .norm_mod
  expect_error(RNAmodR:::.norm_mod(),'argument "x" is missing')
  # .norm_modifiertype
  expect_error(RNAmodR:::.norm_modifiertype(),'argument "x" is missing')
  expect_error(RNAmodR:::.norm_modifiertype(""),"Empty string")
  setClass("Mo2dInosine2",contains = "ModInosine")
  expect_error(RNAmodR:::.norm_modifiertype("Mo2dInosine2"),
               "Invalid class name of Modifier class: the string 'Mod' must be present once at the front")
  setClass("InosineMod2",contains = "ModInosine")
  expect_error(RNAmodR:::.norm_modifiertype("InosineMod2"),
               "Invalid class name of Modifier class: the string 'Mod' can only be present once at the front of")
})
