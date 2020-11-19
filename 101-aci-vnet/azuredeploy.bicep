param vnetName string {
  metadata: {
    description: 'VNet name'
  }
  default: 'aci-vnet'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Address prefix'
  }
  default: '10.0.0.0/16'
}
param subnetAddressPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/24'
}
param subnetName string {
  metadata: {
    description: 'Subnet name'
  }
  default: 'aci-subnet'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param containerGroupName string {
  metadata: {
    description: 'Container group name'
  }
  default: 'aci-containergroup'
}
param containerName string {
  metadata: {
    description: 'Container name'
  }
  default: 'aci-container'
}
param image string {
  metadata: {
    description: 'Container image to deploy. Should be of the form accountName/imagename:tag for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.'
  }
  default: 'microsoft/aci-helloworld'
}
param port string {
  metadata: {
    description: 'Port to open on the container.'
  }
  default: '80'
}
param cpuCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container. Must be an integer.'
  }
  default: '1.0'
}
param memoryInGb string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes.'
  }
  default: '1.5'
}

var networkProfileName_var = 'aci-networkProfile'
var interfaceConfigName = 'eth0'
var interfaceIpConfig = 'ipconfigprofile1'

resource vnetName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
}

resource containerGroupName_res 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
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
              protocol: 'Tcp'
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

output containerIPv4Address string = containerGroupName_res.properties.ipAddress.ip