#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process get_images {
  stageInMode 'symlink'
  stageOutMode 'move'

  script:
    """

    if [[ "${params.run_type}" == "r2d2" ]] || [[ "${params.run_type}" == "raven" ]] ; 

      then

        cd ${params.image_folder}

        if [[ ! -f multiqc-1.13.sif ]] ;
          then
            singularity pull multiqc-1.13.sif docker://index.docker.io/mpgagebioinformatics/multiqc:1.13
        fi

    fi


    if [[ "${params.run_type}" == "local" ]] ; 

      then

        docker pull mpgagebioinformatics/multiqc:1.13

    fi

    """

}

process multiqc {
  stageInMode 'symlink'
  stageOutMode 'move'

  input:
    val fastqc
    val mapping
    val featurecounts

  when:
    ( ! file("${params.project_folder}/multiqc_output/multiqc_report.html").exists() ) 
  
  script:
  """
    mkdir -p /workdir/multiqc_output
    multiqc /workdir/${fastqc} /workdir/${mapping} /workdir/${featurecounts} -f -o /workdir/multiqc_output
  """
}

workflow images {
  main:
    get_images()
}

workflow {
  if ( 'fastqc' in params.keySet() ) {
    fastqc=${params.fastqc}
  } else {
    fastqc="fastqc_output"
  }
  if ( 'mapping' in params.keySet() ) {
    mapping=${params.mapping}
  } else {
    mapping="kallisto_output"
  }
  if ( 'featurecounts' in params.keySet() ) {
    featurecounts=${params.featurecounts}
  } else {
    featurecounts="featureCounts_output"
  }
  multiqc(fastqc,mapping,featurecounts)
} 