@description('Specifies the name of the Azure Machine Learning Workspace which will contain this compute.')
param workspaceName string

@description('Specifies the name of the Azure Machine Learning Compute cluster.')
param clusterName string

@description('The minimum number of nodes to use on the cluster. If not specified, defaults to 0')
param minNodeCount int = 0

@description(' The maximum number of nodes to use on the cluster. If not specified, defaults to 4.')
param maxNodeCount int = 1

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

@description('The name of the administrator user account which can be used to SSH into nodes. It must only contain lower case alphabetic characters [a-z].')
@secure()
param adminUserName string

@description('The password of the administrator user account.')
@secure()
param adminUserPassword string

@description(' The size of agent VMs. More details can be found here: https://aka.ms/azureml-vm-details.')
param vmSize string = 'Standard_DS3_v2'

@description('Name of the resource group which holds the VNET to which you want to inject your compute in.')
param vnetResourceGroupName string = ''

@description('Name of the vnet which you want to inject your compute in.')
param vnetName string = ''

@description('Name of the subnet inside the VNET which you want to inject your compute in.')
param subnetName string = ''

var subnet = {
  id: resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
}

resource workspaceName_clusterName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/${clusterName}'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: vmSize
      scaleSettings: {
        minNodeCount: minNodeCount
        maxNodeCount: maxNodeCount
      }
      userAccountCredentials: {
        adminUserName: adminUserName
        adminUserPassword: adminUserPassword
      }
      subnet: (((!empty(vnetResourceGroupName)) && (!empty(vnetName)) && (!empty(subnetName))) ? subnet : json('null'))
    }
  }
}