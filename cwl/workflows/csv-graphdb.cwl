#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
label: Convert CSV/TSV files to target RDF using GraphDB

inputs:
  - id: dataset_to_process
    label: "Dataset to process"
    type: string
  - id: config_dir
    label: "CWL config directory"
    type: Directory
  - id: input_data_jdbc
    label: "JDBC URL for database connexion"
    type: string
  # tmp RDF4J server SPARQL endpoint to load generic RDF
  # - id: sparql_tmp_triplestore_url  # TODO: remove?
  #   label: "URL of tmp triplestore"
  #   type: string
  - id: tmp_triplestore_container_id
    label: "ID of the tmp triplestore Docker container"
    type: string
  - id: tmp_triplestore_load_dir
    label: "Path to the tmp triplestore load dir in its container"
    type: string
    default: "/usr/local/virtuoso-opensource/var/lib/virtuoso/db/"
  - id: sparql_tmp_service_url
    label: "Service URL of tmp triplestore"
    type: string
  - id: sparql_tmp_graph_uri
    label: "URI of tmp graph"
    type: string
  - id: sparql_tmp_triplestore_username
    label: "Username for tmp triplestore"
    type: string
  - id: sparql_tmp_triplestore_password
    label: "Password for tmp triplestore"
    type: string
  # Final RDF4J server SPARQL endpoint to load the BioLink RDF
  - id: sparql_final_triplestore_url
    label: "URL of final triplestore"
    type: string
  - id: final_graphdb_url
    label: "URL of final GraphDB triplestore"
    type: string
  - id: tmp_graphdb_repository
    label: "URL of final GraphDB repository"
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
  - id: sparql_transform_queries_path
    label: "Path to queries to transform generic RDF"
    type: string
    

outputs:
  - id: logs_autor2rml
    outputSource: step2-autor2rml/logs_autor2rml
    type: File
    label: "AutoR2RML log file"
  - id: r2rml_trig_file_output
    outputSource: step2-autor2rml/r2rml_trig_file_output
    type: File
    label: "R2RML mapping file generated by AutoR2RML"
  - id: sparql_mapping_templates
    outputSource: step2-autor2rml/sparql_mapping_templates
    type: Directory
    label: "AutoR2RML SPARQL mapping templates files"
  - id: r2rml_nquads_file_output
    outputSource: step3-r2rml/r2rml_nquads_file_output
    type: File
    label: "Nquads file produced by R2RML"
  - id: logs_r2rml
    outputSource: step3-r2rml/logs_r2rml
    type: File
    label: "R2RML log file"
  - id: logs_copy_file_to_container
    outputSource: step4-copy-file-to-tmp-triplestore/logs_copy_file_to_container
    type: File
    label: "Copy RDF output to container log file"
  - id: logs_rdf_upload
    outputSource: step4-rdf-upload/logs_rdf_upload
    type: File
    label: "RDF Upload log file"
  - id: sparql_transform_queries_logs
    outputSource: step6-execute-transform-queries/logs_execute_sparql_query_
    type: File
    label: "SPARQL transform queries log file"


steps:
  step2-autor2rml:
    run: ../steps/run-autor2rml.cwl
    in:
      dataset_to_process: dataset_to_process
      input_data_jdbc: input_data_jdbc
    out: [r2rml_trig_file_output, sparql_mapping_templates, logs_autor2rml]

  step3-r2rml:
    run: ../steps/run-r2rml.cwl
    in:
      r2rml_trig_file: step2-autor2rml/r2rml_trig_file_output
      input_data_jdbc: input_data_jdbc
    out: [r2rml_nquads_file_output, logs_r2rml]

  step4-copy-file-to-tmp-triplestore:
    run: ../steps/copy-file-to-container.cwl
    in:
      load_in_container_id: tmp_triplestore_container_id
      file_to_load: step3-r2rml/r2rml_nquads_file_output
      load_to_dir: tmp_triplestore_load_dir
    out: [logs_copy_file_to_container]

  step4-rdf-upload:
    run: ../steps/bulk-load-graphdb.cwl
    # run: ../steps/bulk-load-virtuoso.cwl
    # run: ../steps/bulk-load-blazegraph.cwl
    in:
      file_to_load: step3-r2rml/r2rml_nquads_file_output
      graphdb_url: final_graphdb_url
      graphdb_repository: tmp_graphdb_repository
      graphdb_username: sparql_final_triplestore_username
      graphdb_password: sparql_final_triplestore_password
      previous_step_output: step4-copy-file-to-tmp-triplestore/logs_copy_file_to_container
    out: [logs_rdf_upload]

  # # We need to create a script that sleeps and check until all imports are done
  # curl -X GET --header 'Accept: application/json' 'http://localhost:7200/rest/data/import/server/test'
  # # Still importing:
  # [
  #   {
  #     "name": "rdf_output.nq",
  #     "status": "IMPORTING",
  #     "message": ""
  #   }
  # ]

  step6-execute-transform-queries:
    run: ../steps/execute-sparql-queries.cwl
    in:
      config_dir: config_dir
      sparql_queries_path: sparql_transform_queries_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_input_graph_uri: sparql_tmp_graph_uri
      sparql_output_graph_uri: sparql_final_graph_uri
      sparql_service_url: sparql_tmp_service_url
      previous_step_output: step4-rdf-upload/logs_rdf_upload
    out: [logs_execute_sparql_query_]


$namespaces:
  s: "http://schema.org/"
  dct: "http://purl.org/dc/terms/"
  foaf: "http://xmlns.com/foaf/0.1/"
  edam: "http://edamontology.org/"
$schemas:
  - https://schema.org/version/latest/schemaorg-current-http.rdf
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
s:codeRepository: https://github.com/MaastrichtU-IDS/d2s-core

edam:has_function:
  - edam:operation_1812   # Parsing
  - edam:operation_2429   # Mapping

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