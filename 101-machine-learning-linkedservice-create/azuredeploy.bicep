@description('Name of the existing AML workspace to create the linked service.')
param amlWorkspaceName string

@description('Name of the LinkedService')
param linkName string = 'link1'

@description('ResourceId of the existing Synapse workspace which you want to link to the aml workspace by linked service.')
param synapseWorkspaceResourceId string

@description('Spark pools you want to attach to the aml workspace, in such format: [ {"computeName":"compute1", "poolName":"sparkPool1"}, ... ]. Pool name is the name of spark pool shown in Synapse workspace, while compute name is the alias for this pool after it is attached to aml workspace.')
param sparkPools array

@allowed([
  'australiaeast'
  'brazilsouth'
  'canadacentral'
  'centralus'
  'eastasia'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'koreacentral'
  'northcentralus'
  'northeurope'
  'southeastasia'
  'southcentralus'
  'uksouth'
  'westcentralus'
  'westus'
  'westus2'
  'westeurope'
])
@description('Location(aka region) of the LinkedService')
param location string

var synapseWorkspaceName = substring(synapseWorkspaceResourceId, (lastIndexOf(synapseWorkspaceResourceId, '/') + 1))

resource amlWorkspaceName_linkName 'Microsoft.MachineLearningServices/workspaces/linkedServices@2020-04-01-preview' = {
  name: '${amlWorkspaceName}/${linkName}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    linkedServiceResourceId: synapseWorkspaceResourceId
  }
}

resource amlWorkspaceName_sparkPools_computeName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = [for item in sparkPools: {
  name: '${amlWorkspaceName}/${item.computeName}'
  location: location
  properties: {
    resourceId: resourceId(reference(synapseWorkspaceResourceId, '2019-06-01-preview', 'Full').subscriptionId, reference(synapseWorkspaceResourceId, '2019-06-01-preview', 'Full').resourceGroupName, 'Microsoft.Synapse/workspaces/bigDataPools', synapseWorkspaceName, item.poolName)
    computeType: 'SynapseSpark'
  }
}]

output SaiPrincipalId string = reference(linkName, '2020-04-01-preview', 'Full').identity.principalId