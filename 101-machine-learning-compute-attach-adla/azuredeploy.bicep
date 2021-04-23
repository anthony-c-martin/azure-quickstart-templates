@description('Specifies the name of the Azure Machine Learning Workspace which will contain this compute.')
param workspaceName string

@description('Specifies the name of the Azure Machine Learning Compute cluster.')
param computeName string

@description('The name of the datalake analytics account to attach the compute target to.')
param adlAnalyticsName string

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_computeName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/${computeName}'
  location: location
  properties: {
    computeType: 'DataLakeAnalytics'
    resourceId: resourceId('Microsoft.DataLakeAnalytics/accounts', adlAnalyticsName)
  }
}