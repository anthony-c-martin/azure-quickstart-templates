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

@description('Whether or not to enable token auth for this Webservice. ')
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

@description('Name of compute target.')
param computeTarget string

@description('Kubernetes namespace in which to deploy the service: up to 63 lowercase alphanumeric (\'a\'-\'z\', \'0\'-\'9\') and hyphen (\'-\') characters. The first and last characters cannot be hyphens.')
param namespace string

@description('The number of containers to allocate for this Webservice. No default, if this parameter is not set then the autoscaler is enabled by default.')
param numReplicas int

@description('Whether or not to enable autoscaling for this Webservice. Defaults to True if num_replicas is None.')
param autoScaleEnabled bool

@description('The minimum number of containers to use when autoscaling this Webservice.')
param autoScaleMinReplicas int

@description('The maximum number of containers to use when autoscaling this Webservice.')
param autoScaleMaxReplicas int

@description('The target utilization (in percent out of 100) the autoscaler should attempt to maintain for this Webservice.')
param autoscaleTargetUtilization int

@description('How often the autoscaler should attempt to scale this Webservice.')
param autoscaleRefreshSeconds int

@description('How often (in seconds) to perform the liveness probe.')
param periodSeconds int

@description('Number of seconds after the container has started before liveness probes are initiated.')
param initialDelaySeconds int

@description('Number of seconds after which the liveness probe times out.')
param timeoutSeconds int

@description('When a pod starts and the liveness probe fails, Kubernetes will try --failure-threshold times before giving up.')
param failureThreshold int

@description('Minimum consecutive successes for the liveness probe to be considered successful after having failed.')
param successThreshold int

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
    computeType: 'AKS'
    computeName: computeTarget
    numReplicas: numReplicas
    autoScaler: (autoScaleEnabled ? createObject('autoscaleEnabled', autoScaleEnabled, 'minReplicas', int(autoScaleMinReplicas), 'maxReplicas', int(autoScaleMaxReplicas), 'targetUtilization', int(autoscaleTargetUtilization), 'refreshPeriodInSeconds', int(autoscaleRefreshSeconds)) : json('null'))
    namespace: namespace
    livenessProbeRequirements: createObject('periodSeconds', periodSeconds, 'initialDelaySeconds', initialDelaySeconds, 'timeoutSeconds', timeoutSeconds, 'failureThreshold', failureThreshold, 'successThreshold', successThreshold)
  }
}