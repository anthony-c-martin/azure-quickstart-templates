@description('VNet name')
param vnetName string = 'aci-vnet'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet prefix')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('Subnet name')
param subnetName string = 'aci-subnet'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container group name')
param containerGroupName string = 'aci-containergroup'

@description('Container name')
param containerName string = 'aci-container'

@description('Container image to deploy. Should be of the form accountName/imagename:tag for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.')
param image string = 'microsoft/aci-helloworld'

@description('Port to open on the container.')
param port string = '80'

@description('The number of CPU cores to allocate to the container. Must be an integer.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb string = '1.5'

var networkProfileName_var = 'aci-networkProfile'
var interfaceConfigName = 'eth0'
var interfaceIpConfig = 'ipconfigprofile1'

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'DelegationService'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

resource networkProfileName 'Microsoft.Network/networkProfiles@2020-05-01' = {
  name: networkProfileName_var
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: interfaceConfigName
        properties: {
          ipConfigurations: [
            {
              name: interfaceIpConfig
              properties: {
                subnet: {
                  id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                }
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource containerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    networkProfile: {
      id: networkProfileName.id
    }
    restartPolicy: 'Always'
  }
}

output containerIPv4Address string = containerGroupName_resource.properties.ipAddress.ip