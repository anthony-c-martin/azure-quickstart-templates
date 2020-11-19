param resourceNamePrefix string {
  metadata: {
    description: 'Prefix for the resource names.'
  }
  default: 'vmssbg'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine hosting the Jenkins and the Virtual Machines in VMSS.'
  }
}
param sshPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH public key string, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param virtualMachineSize string {
  metadata: {
    description: 'The virutal machine size to use. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes'
  }
  default: 'Standard_D2'
}
param jenkinsDNSPrefix string {
  metadata: {
    description: 'Unique DNS name prefix for the public IP used to access the Jenkins service.'
  }
}
param tomcatDNSPrefix string {
  metadata: {
    description: 'Unique DNS name prefix for the public IP used to access the Tomcat service.'
  }
}
param servicePrincipalAppId string {
  metadata: {
    description: 'Service Principal App ID (also called Client ID) that has contributor rights to the subscription used for this deployment. It is used to manage related Azure resources, e.g., bake OS image, check resource status, update VMSS image, etc.'
  }
}
param servicePrincipalAppKey string {
  metadata: {
    description: 'Service Principal App Key (also called Client Secret) that has contributor rights to the subscription used for this deployment. It is used to manage related Azure resources, e.g., bake OS image, check resource status, update VMSS image, etc.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/jenkins/master'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var service = 'tomcat'
var baseImageName = '${resourceNamePrefix}-base-${uniqueString(resourceGroup().id)}'
var imageId = resourceId('Microsoft.Compute/images', baseImageName)
var jenkinsVmName = '${resourceNamePrefix}-jenkins'
var vmExtensionName = '${jenkinsVmName}-init'
var jenkinsNic = '${jenkinsVmName}-nic'
var jenkinsIp = '${jenkinsVmName}-ip'
var blueVmss = '${resourceNamePrefix}-blue'
var greenVmss = '${resourceNamePrefix}-green'
var blueComputerNamePrefix = blueVmss
var greenComputerNamePrefix = greenVmss
var ipName = '${resourceNamePrefix}-ip'
var lbName = '${resourceNamePrefix}-lb'
var vnetName = '${resourceNamePrefix}-vnet'
var nsgName = '${resourceNamePrefix}-nsg'
var subnetName = '${resourceNamePrefix}-subnet'
var lbFrontendName = 'loadBalancerFrontEnd'
var lbFrontendId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, lbFrontendName)
var lbBlueBeName = 'blue-bepool'
var lbBlueNatPoolName = 'blue-natpool'
var lbGreenBeName = 'green-bepool'
var lbGreenNatPoolName = 'green-natpool'
var artifactsLocation_variable = artifactsLocation
var extensionScript = '301-jenkins-vmss-zero-downtime-deployment.sh'
var artifactsLocationSasToken_variable = artifactsLocationSasToken

resource jenkinsVmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jenkinsVmName
  location: location
  properties: {
    osProfile: {
      computerName: jenkinsVmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${jenkinsVmName}-os-disk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jenkinsNic_resource.id
        }
      ]
    }
  }
  dependsOn: [
    jenkinsNic_resource
  ]
}

resource jenkinsVmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${jenkinsVmName}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation_variable}/quickstart_templates/zero_downtime_deployment/${extensionScript}${artifactsLocationSasToken_variable}'
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} --app_id "${servicePrincipalAppId}" --app_key "${servicePrincipalAppKey}" --subscription_id "${subscription().subscriptionId}" --tenant_id "${subscription().tenantId}" --resource_group "${resourceGroup().name}" --location "${location}" --name_prefix "${resourceNamePrefix}" --image_name "${baseImageName}" --jenkins_fqdn "${reference(jenkinsIp).dnsSettings.fqdn}" --artifacts_location "${artifactsLocation_variable}" --sas_token "${artifactsLocationSasToken_variable}"'
    }
  }
  dependsOn: [
    jenkinsVmName_resource
  ]
}

resource jenkinsNic_resource 'Microsoft.Network/networkInterfaces@2016-09-01' = {
  name: jenkinsNic
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: jenkinsIp_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName_resource.id
    }
  }
  dependsOn: [
    vnetName_resource
    jenkinsIp_resource
    nsgName_resource
  ]
}

resource jenkinsIp_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: jenkinsIp
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkinsDNSPrefix
    }
  }
}

resource blueVmss_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  sku: {
    name: virtualMachineSize
    capacity: 2
  }
  name: blueVmss
  location: location
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: blueComputerNamePrefix
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        imageReference: {
          id: imageId
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${blueComputerNamePrefix}Nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              networkSecurityGroup: {
                id: nsgName_resource.id
              }
              dnsSettings: {
                dnsServers: []
              }
              ipConfigurations: [
                {
                  name: '${blueComputerNamePrefix}IPConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbBlueBeName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName, lbBlueNatPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
    overprovision: true
  }
  dependsOn: [
    nsgName_resource
    vnetName_resource
    lbName_resource
    jenkinsVmName_vmExtensionName
  ]
}

resource greenVmss_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  sku: {
    name: virtualMachineSize
    capacity: 2
  }
  name: greenVmss
  location: location
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: greenComputerNamePrefix
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        imageReference: {
          id: imageId
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${greenComputerNamePrefix}Nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              networkSecurityGroup: {
                id: nsgName_resource.id
              }
              dnsSettings: {
                dnsServers: []
              }
              ipConfigurations: [
                {
                  name: '${greenComputerNamePrefix}IPConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbGreenBeName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName, lbGreenNatPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
    overprovision: true
  }
  dependsOn: [
    nsgName_resource
    vnetName_resource
    lbName_resource
    jenkinsVmName_vmExtensionName
  ]
}

resource lbName_resource 'Microsoft.Network/loadBalancers@2017-08-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFrontendName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ipName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBlueBeName
      }
      {
        name: lbGreenBeName
      }
    ]
    inboundNatPools: [
      {
        name: lbBlueNatPoolName
        properties: {
          protocol: 'Tcp'
          backendPort: 22
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50119
          frontendIPConfiguration: {
            id: lbFrontendId
          }
        }
      }
      {
        name: lbGreenNatPoolName
        properties: {
          protocol: 'Tcp'
          backendPort: 22
          frontendPortRangeStart: 50120
          frontendPortRangeEnd: 50239
          frontendIPConfiguration: {
            id: lbFrontendId
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: service
        properties: {
          frontendIPConfiguration: {
            id: lbFrontendId
          }
          frontendPort: 80
          backendPort: 8080
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          loadDistribution: 'Default'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbBlueBeName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, service)
          }
        }
      }
      {
        name: '${service}-test'
        properties: {
          frontendIPConfiguration: {
            id: lbFrontendId
          }
          frontendPort: 8080
          backendPort: 8081
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          loadDistribution: 'Default'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbGreenBeName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, service)
          }
        }
      }
    ]
    probes: [
      {
        name: service
        properties: {
          protocol: 'Http'
          port: 8080
          requestPath: '/'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    ipName_resource
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2017-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh-access'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'allow-http-service-access'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource ipName_resource 'Microsoft.Network/publicIPAddresses@2017-08-01' = {
  name: ipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: tomcatDNSPrefix
    }
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.87.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.87.0.0/24'
        }
      }
    ]
  }
}

output admin_username string = adminUsername
output jenkins_url string = 'http://${reference(jenkinsIp).dnsSettings.fqdn}'
output ssh string = 'ssh -L 8080:localhost:8080 ${adminUsername}@${reference(jenkinsIp).dnsSettings.fqdn}'
output tomcat_url string = 'http://${reference(ipName).dnsSettings.fqdn}'
output base_image_id string = imageId