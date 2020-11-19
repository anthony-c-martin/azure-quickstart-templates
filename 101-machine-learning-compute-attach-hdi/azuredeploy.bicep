param computeName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Compute.'
  }
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}
param clusterName string {
  metadata: {
    description: 'The clusterName of the Azure HDInsight cluster.'
  }
}
param username string {
  metadata: {
    description: 'The username needed to access the virtual machine.'
  }
  secure: true
}
param sshPort int {
  metadata: {
    description: 'The exposed port for the resource. Defaults to 22.'
  }
  default: 22
}
param password string {
  metadata: {
    description: 'The password needed to access the virtual machine.'
  }
  secure: true
}
param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Workspace which will contain this compute.'
  }
}

resource workspaceName_computeName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/${computeName}'
  location: location
  properties: {
    computeType: 'HDInsight'
    resourceId: resourceId('Microsoft.HDInsight/clusters', clusterName)
    properties: {
      sshPort: sshPort
      administratorAccount: {
        username: username
        password: password
      }
    }
  }
}