@description('The name of the Azure Machine Learning Web Service. This resource will be created in the same resource group as the workspace.')
param webserviceName string

@description('The name of the Azure Machine Learning Workspace.')
param workspaceName string = 'mlworkspace'

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

@description('Name of Azure Machine Learning Environment for deployment. See https://docs.microsoft.com/en-us/azure/machine-learning/how-to-use-environments and https://docs.microsoft.com/en-us/azure/machine-learning/resource-curated-environments .')
param environmentName string

@description('Version of Azure Machine Learning Environment for deployment.')
param environmentVersion string

@description('The default number of CPU cores to allocate for this Webservice. Can be a decimal.')
param cpu string

@description('The max number of CPU cores this Webservice is allowed to use. Can be a decimal.')
param cpuLimit string

@description('The number of gpu cores to allocate for this Webservice')
param gpu int

@description('The amount of memory (in GB) to allocate for this Webservice. Can be a decimal.')
param memoryInGB string

@description('Relative path of a file from storage account that contains the code to run for service.')
param driverProgram string

@description('Details of the models to be deployed. Each model must have the following properties: \'name\'(name of the model), \'path\'(relative path of a file from storage account linked to Workspace), \'mimeType\'(MIME type of Model content. For more details about MIME type, please open https://www.iana.org/assignments/media-types/media-types.xhtml), \'framework\'(framework of the model, use Custom if unsure) and \'frameworkVersion\'(framework version of the model).')
param models array

@description('Whether or not to enable key auth for this Webservice.')
param authEnabled bool

@description('Whether or not to enable token auth for this Webservice.  Only applicable when deploying to AKS.')
param tokenAuthEnabled bool

@description('A primary auth key to use for this Webservice.')
@secure()
param primaryKey string

@description('A secondary auth key to use for this Webservice.')
@secure()
param secondaryKey string

@description('A timeout to enforce for scoring calls to this Webservice.')
param scoringTimeoutMilliSeconds int

@description('Whether or not to enable AppInsights for this Webservice.')
param appInsightsEnabled bool

var driverProgram_var = trim(driverProgram)
var driverProgramFileName = last(split(trim(driverProgram), '/'))
var assets = [
  {
    mimeType: 'application/x-python'
    url: (startsWith(driverProgram_var, '/') ? 'aml://storage${driverProgram_var}' : 'aml://storage/${driverProgram_var}')
  }
]
var models_var = [for item in models: {
  name: item.name
  url: (startsWith(item.path, '/') ? 'aml://storage${item.path}' : 'aml://storage/${item.path}')
  mimeType: item.mimeType
  framework: item.framework
  frameworkVersion: item.frameworkVersion
}]

resource workspaceName_webserviceName 'Microsoft.MachineLearningServices/workspaces/services@2020-05-01-preview' = {
  name: '${workspaceName}/${webserviceName}'
  location: location
  properties: {
    environmentImageRequest: {
      models: models_var
      driverProgram: (empty(driverProgramFileName) ? json('null') : driverProgramFileName)
      assets: (empty(driverProgramFileName) ? json('null') : assets)
      environmentReference: ((!(empty(environmentName) || empty(environmentVersion))) ? createObject('name', environmentName, 'version', environmentVersion) : json('null'))
    }
    scoringTimeoutMs: scoringTimeoutMilliSeconds
    appInsightsEnabled: appInsightsEnabled
    authEnabled: authEnabled
    aadAuthEnabled: tokenAuthEnabled
    keys: ((!(empty(primaryKey) || empty(secondaryKey))) ? createObject('primaryKey', primaryKey, 'secondaryKey', secondaryKey) : json('null'))
    ContainerResourceRequirements: {
      cpu: cpu
      cpuLimit: cpuLimit
      gpu: gpu
      memoryInGB: memoryInGB
    }
    computeType: 'ACI'
  }
}