%YAML 1.1
---
application: # Aquesta és la clau que el SDK t'està demanant
  name: spleen_segmentation_app
  version: 1.0.0
  description: App per a la segmentació de melsa basada en MONAI Deploy
  main: app.py

  # Paràmetres del model
  models:
    - name: spleen_model
      model: model.ts
      format: torchscript

  # Definició dels recursos
  resources:
    cpu: 1
    gpu: 1
    memory: 4Gi