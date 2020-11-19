param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Workspace which will contain this compute.'
  }
}
param computeName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Compute cluster.'
  }
}
param clusterName string {
  metadata: {
    description: 'The name of the aks cluster to attach the compute target to.'
  }
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}

resource workspaceName_computeName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/${computeName}'
  location: location
  properties: {
    computeType: 'Aks'
    resourceId: resourceId('Microsoft.ContainerService/managedClusters', clusterName)
  }
}