#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Download files to process
requirements:
  # Get the config dir as input
  InitialWorkDirRequirement:
    listing:
      - $(inputs.config_dir)
  # InlineJavascriptRequirement: {}

hints:
  DockerRequirement:
    dockerPull: maastrichtuids/d2s-bash-exec:latest
    dockerOutputDirectory: /data
    # Link the output dir to /data in the Docker container

# baseCommand: ["https://raw.githubusercontent.com/MaastrichtU-IDS/d2s-transform-biolink/master/datasets/stitch/download/download-stitch.sh", "input"]
baseCommand: []
arguments: ["$(runtime.outdir)/$(inputs.dataset)/download/download.sh", "input"]


# https://www.commonwl.org/user_guide/08-arguments/

inputs:
  dataset:
    type: string
  config_dir:
    type: Directory
  download_username:
    type: string?
    inputBinding:
      position: 1
      prefix: --username
  download_password:
    type: string?
    inputBinding:
      position: 2
      prefix: --password


stdout: download-dataset.txt

outputs:
  download_dataset_logs:
    type: stdout
  download_dir:
    type: Directory
    outputBinding:
      glob: input