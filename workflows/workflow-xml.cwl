#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
label: Convert XML files to a target RDF

inputs:   
  - id: config_dir
    label: "CWL config directory"
    type: Directory
  - id: download_username
    label: "Username to download files"
    type: string?
  - id: download_password
    label: "Password to download files"
    type: string?
  - id: sparql_tmp_triplestore_url
    label: "URL of tmp triplestore"
    type: string
  - id: sparql_tmp_service_url
    label: "Service URL of tmp triplestore"
    type: string
  - id: sparql_tmp_triplestore_username
    label: "Username for tmp triplestore"
    type: string?
  - id: sparql_tmp_triplestore_password
    label: "Password for tmp triplestore"
    type: string?
  - id: sparql_final_triplestore_url
    label: "URL of final triplestore"
    type: string
  - id: sparql_final_triplestore_username
    label: "Username for final triplestore"
    type: string?
  - id: sparql_final_triplestore_password
    label: "Password for final triplestore"
    type: string?
  - id: sparql_final_graph_uri
    label: "Graph URI of transformed RDF"
    type: string
  - id: sparql_insert_metadata_path
    label: "Path to queries to insert metadata"
    type: string
  - id: sparql_transform_queries_path
    label: "Path to queries to transform generic RDF"
    type: string
  - id: sparql_compute_hcls_path
    label: "Path to queries to compute HCLS stats"
    type: string
    default: https://github.com/MaastrichtU-IDS/d2s-transform-repository/tree/master/sparql/compute-hcls-stats


outputs:
  - id: download_dir
    outputSource: step1-d2s-download/download_dir
    type: Directory
    label: "Downloaded files"
  - id: download_dataset_logs
    outputSource: step1-d2s-download/download_dataset_logs
    type: File
    label: "Download script log file"
  # - id: sparql_mapping_templates
  #   outputSource: step2-autor2rml/sparql_mapping_templates
  #   type: Directory
  #   label: "SPARQL mapping templates files"
  - id: xml2rdf_nquads_file_output
    outputSource: step2-xml2rdf/xml2rdf_nquads_file_output
    type: File
    label: "Nquads file produced by xml2rdf"
  - id: xml2rdf_logs
    outputSource: step2-xml2rdf/xml2rdf_logs
    type: File
    label: "xml2rdf log file"
  - id: rdf_upload_logs
    outputSource: step4-rdf-upload/rdf_upload_logs
    type: File
    label: "RDF Upload log file"
  - id: sparql_insert_metadata_logs
    outputSource: step5-insert-metadata/execute_sparql_query_logs
    type: File
    label: "SPARQL insert metadata log file"
  - id: sparql_transform_queries_logs
    outputSource: step6-execute-transform-queries/execute_sparql_query_logs
    type: File
    label: "SPARQL transform queries log file"
  - id: sparql_hcls_statistics_logs
    outputSource: step7-compute-hcls-stats/execute_sparql_query_logs
    type: File
    label: "SPARQL HCLS statistics log file"


steps:
  step1-d2s-download:
    run: ../steps/d2s-bash-exec.cwl
    in:
      config_dir: config_dir
      download_username: download_username
      download_password: download_password
    out: [download_dir, download_dataset_logs]

  step2-xml2rdf:
    run: ../steps/run-xml2rdf.cwl
    in:
      download_dir: step1-d2s-download/download_dir
    out: [xml2rdf_nquads_file_output, xml2rdf_logs]
    # out: [xml2rdf_nquads_file_output, xml2rdf_logs, sparql_mapping_templates]

  step4-rdf-upload:
    run: ../steps/rdf-upload.cwl
    # run: ../steps/virtuoso-bulk-load.cwl
    in:
      file_to_load: step2-xml2rdf/xml2rdf_nquads_file_output
      sparql_triplestore_url: sparql_tmp_triplestore_url
      sparql_username: sparql_tmp_triplestore_username
      sparql_password: sparql_tmp_triplestore_password
    out: [rdf_upload_logs]

  step5-insert-metadata:
    run: ../steps/execute-sparql-queries.cwl
    in:
      sparql_queries_path: sparql_insert_metadata_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_output_graph_uri: sparql_final_graph_uri
      previous_step_output: step4-rdf-upload/rdf_upload_logs
    out: [execute_sparql_query_logs]

  step6-execute-transform-queries:
    run: ../steps/execute-sparql-queries.cwl
    in:
      sparql_queries_path: sparql_transform_queries_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      # sparql_input_graph_uri: sparql_tmp_graph_uri
      sparql_output_graph_uri: sparql_final_graph_uri
      sparql_service_url: sparql_tmp_service_url
      previous_step_output: step4-rdf-upload/rdf_upload_logs
    out: [execute_sparql_query_logs]

  step7-compute-hcls-stats:
    run: ../steps/execute-sparql-queries.cwl
    in: # No sparql_queries_path, HCLS stats is the default
      sparql_queries_path: sparql_compute_hcls_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_input_graph_uri: sparql_final_graph_uri
      previous_step_output: step6-execute-transform-queries/execute_sparql_query_logs
    out: [execute_sparql_query_logs]


$namespaces:
  s: "http://schema.org/"
  dct: "http://purl.org/dc/terms/"
  foaf: "http://xmlns.com/foaf/0.1/"
  edam: "http://edamontology.org/"
$schemas:
  - http://schema.org/version/latest/schema.rdf
  - https://lov.linkeddata.es/dataset/lov/vocabs/dcterms/versions/2012-06-14.n3
  - http://xmlns.com/foaf/spec/index.rdf
  - http://edamontology.org/EDAM_1.18.owl

dct:creator:
  class: foaf:Person
  "@id": "https://orcid.org/0000-0002-1501-1082"
  foaf:name: "Vincent Emonet"
  foaf:mbox: "mailto:vincent.emonet@gmail.com"

dct:contributor:
  class: foaf:Person
  "@id": "https://orcid.org/0000-0000-ammar-ammar"
  foaf:name: "Ammar Ammar"
  foaf:mbox: "mailto:a.ammar@student.maastrichtuniversity.nl"

dct:license: "https://opensource.org/licenses/MIT"
s:citation: "https://swat4hcls.figshare.com/articles/Data2Services_enabling_automated_conversion_of_data_to_services/7345868/files/13573628.pdf"
s:codeRepository: https://github.com/MaastrichtU-IDS/d2s-cwl-workflows

edam:has_function:
  - edam:operation_2429   # Mapping
  - edam:operation_1812   # Parsing

edam:has_input: 
  - edam:data_3786      # Query script
  - edam:format_3857    # CWL
  - edam:format_3790    # SPARQL

edam:has_output:
  - edam:format_2376    # RDF format
  - edam:data_3509      # Ontology mapping

edam:has_topic:
  - edam:topic_0769   # Workflows
  - edam:topic_0219   # Data submission, annotation and curation
  - edam:topic_0102   # Mapping
  - edam:topic_3345   # Data identity and mapping