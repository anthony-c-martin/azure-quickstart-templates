@description('Specifies the name of the Azure Machine Learning Compute.')
param computeName string

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

@description('The clusterName of the Azure HDInsight cluster.')
param clusterName string

@description('The username needed to access the virtual machine.')
@secure()
param username string

@description('The exposed port for the resource. Defaults to 22.')
param sshPort int = 22

@description('The password needed to access the virtual machine.')
@secure()
param password string

@description('Specifies the name of the Azure Machine Learning Workspace which will contain this compute.')
param workspaceName string

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