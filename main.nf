#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process get_images {
  stageInMode 'symlink'
  stageOutMode 'move'

  script:
    """

    if [[ "${params.containers}" == "singularity" ]] ; 

      then

        cd ${params.image_folder}

        if [[ ! -f multiqc-1.13.sif ]] ;
          then
            singularity pull multiqc-1.13.sif docker://index.docker.io/mpgagebioinformatics/multiqc:1.13
        fi

    fi


    if [[ "${params.containers}" == "docker" ]] ; 

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

    if [ ${fastqc} != "" ] ; then fastqc_folder=/workdir/${fastqc} ; else fastqc_folder="" ; fi
    if [ ${mapping} != "" ] ; then mapping_folder=/workdir/${mapping} ; else mapping_folder="" ; fi
    if [ ${featurecounts} != "" ] ; then featureCounts_folder=/workdir/${featurecounts} ; else featureCounts_folder="" ; fi

    multiqc \${fastqc_folder} \${mapping_folder} \${featureCounts_folder} -f -o /workdir/multiqc_output
  """
}

process upload_paths {
  stageInMode 'symlink'
  stageOutMode 'move'

  script:
  """
    cd ${params.project_folder}/multiqc_output
    rm -rf upload.txt
    echo "multiqc \$(readlink -f multiqc_report.html)" >>  upload.txt_
    uniq upload.txt_ upload.txt 
    rm upload.txt_
  """
}

workflow images {
  main:
    get_images()
}

workflow upload {
  main:
    upload_paths()
}

workflow {
  if ( 'fastqc_output' in params.keySet() ) {
    // fastqc=${params.fastqc_output}
    fastqc=params["fastqc_output"]
  } else {
    fastqc="fastqc_output"
  }
  if ( 'mapping_output' in params.keySet() ) {
    // mapping=${params.mapping_output}
    mapping=params["mapping_output"]
  } else {
    mapping="kallisto_output"
  }
  if ( 'featurecounts' in params.keySet() ) {
    // featurecounts=${params.featurecounts}
    featurecounts=params["featurecounts"]
  } else {
    featurecounts="featureCounts_output"
  }
  multiqc(fastqc,mapping,featurecounts)
} 