#!/usr/bin/env nextflow

// Input parameters block
params.greeting_1 = 'Hello_GCU'
params.user = 'Sageloom'
params.fastqFiles = '/workspaces/training/data/input/fastqs/*.fastq.gz'



// Process 1: Say hello
process say_hello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting
        val user

    output:
	    path "${greeting}.txt"

    script:
    """
    echo '$greeting from $user'  > '${greeting}.txt'
    """
}



// Process 2: Change case
process convertToUpper {

    publishDir 'results', mode: 'copy'

    input:
        path input_file

    output:
        path "UPPER-${input_file}"

    script:
    """
    cat '$input_file' | tr '[a-z]' '[A-Z]' > 'UPPER-${input_file}'
    """
}



// Process 3: fastq file inspection

process inspectFiles {

    publishDir 'results', mode: 'copy'

    input:
        path input_file
        path fastq_path

    output:
        path "fastq-report-${fastq_path}-${input_file}"

    script:
    """
    cat '$input_file' > fastq-report-${fastq_path}-${input_file}
    echo 'File Path' >> 'fastq-report-${fastq_path}-${input_file}'
    echo '$fastq_path' >> 'fastq-report-${fastq_path}-${input_file}'

    echo 'CKSUM' >> 'fastq-report-${fastq_path}-${input_file}'
    cksum $fastq_path >> 'fastq-report-${fastq_path}-${input_file}'

    echo 'Line count' >> 'fastq-report-${fastq_path}-${input_file}'
    wc -l $fastq_path >> 'fastq-report-${fastq_path}-${input_file}'

    """
}

process combineReports {

    publishDir 'results', mode: 'copy'

    input:
        path reports

    output:
        path "final-fastq-report.txt"

    script:
    """
    cat ${reports} > final-fastq-report.txt
    """
}


// Workflow block
workflow {

	// Creating channel
	fastq_channel = channel.fromPath(params.fastqFiles)

    say_hello(params.greeting_1, params.user) // calling process 1

    convertToUpper(say_hello.out) // calling process 2

    inspect_out = inspectFiles(convertToUpper.out, fastq_channel) // calling process 3

    combineReports(inspect_out.collect()) // process 4

}
