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
var jenkinsVmName_var = '${resourceNamePrefix}-jenkins'
var vmExtensionName = '${jenkinsVmName_var}-init'
var jenkinsNic_var = '${jenkinsVmName_var}-nic'
var jenkinsIp_var = '${jenkinsVmName_var}-ip'
var blueVmss_var = '${resourceNamePrefix}-blue'
var greenVmss_var = '${resourceNamePrefix}-green'
var blueComputerNamePrefix = blueVmss_var
var greenComputerNamePrefix = greenVmss_var
var ipName_var = '${resourceNamePrefix}-ip'
var lbName_var = '${resourceNamePrefix}-lb'
var vnetName_var = '${resourceNamePrefix}-vnet'
var nsgName_var = '${resourceNamePrefix}-nsg'
var subnetName = '${resourceNamePrefix}-subnet'
var lbFrontendName = 'loadBalancerFrontEnd'
var lbFrontendId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, lbFrontendName)
var lbBlueBeName = 'blue-bepool'
var lbBlueNatPoolName = 'blue-natpool'
var lbGreenBeName = 'green-bepool'
var lbGreenNatPoolName = 'green-natpool'
var artifactsLocation_var = artifactsLocation
var extensionScript = '301-jenkins-vmss-zero-downtime-deployment.sh'
var artifactsLocationSasToken_var = artifactsLocationSasToken

resource jenkinsVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jenkinsVmName_var
  location: location
  properties: {
    osProfile: {
      computerName: jenkinsVmName_var
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
        name: '${jenkinsVmName_var}-os-disk'
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
          id: jenkinsNic.id
        }
      ]
    }
  }
}

resource jenkinsVmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${jenkinsVmName_var}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation_var}/quickstart_templates/zero_downtime_deployment/${extensionScript}${artifactsLocationSasToken_var}'
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} --app_id "${servicePrincipalAppId}" --app_key "${servicePrincipalAppKey}" --subscription_id "${subscription().subscriptionId}" --tenant_id "${subscription().tenantId}" --resource_group "${resourceGroup().name}" --location "${location}" --name_prefix "${resourceNamePrefix}" --image_name "${baseImageName}" --jenkins_fqdn "${reference(jenkinsIp_var).dnsSettings.fqdn}" --artifacts_location "${artifactsLocation_var}" --sas_token "${artifactsLocationSasToken_var}"'
    }
  }
  dependsOn: [
    jenkinsVmName
  ]
}

resource jenkinsNic 'Microsoft.Network/networkInterfaces@2016-09-01' = {
  name: jenkinsNic_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jenkinsIp.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    vnetName
  ]
}

resource jenkinsIp 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: jenkinsIp_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkinsDNSPrefix
    }
  }
}

resource blueVmss 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  sku: {
    name: virtualMachineSize
    capacity: 2
  }
  name: blueVmss_var
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
                id: nsgName.id
              }
              dnsSettings: {
                dnsServers: []
              }
              ipConfigurations: [
                {
                  name: '${blueComputerNamePrefix}IPConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbBlueBeName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName_var, lbBlueNatPoolName)
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
    vnetName
    lbName
    jenkinsVmName_vmExtensionName
  ]
}

resource greenVmss 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  sku: {
    name: virtualMachineSize
    capacity: 2
  }
  name: greenVmss_var
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
                id: nsgName.id
              }
              dnsSettings: {
                dnsServers: []
              }
              ipConfigurations: [
                {
                  name: '${greenComputerNamePrefix}IPConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbGreenBeName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName_var, lbGreenNatPoolName)
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
    vnetName
    lbName
    jenkinsVmName_vmExtensionName
  ]
}

resource lbName 'Microsoft.Network/loadBalancers@2017-08-01' = {
  name: lbName_var
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
            id: ipName.id
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbBlueBeName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, service)
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbGreenBeName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, service)
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
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2017-06-01' = {
  name: nsgName_var
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

resource ipName 'Microsoft.Network/publicIPAddresses@2017-08-01' = {
  name: ipName_var
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

resource vnetName 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: vnetName_var
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
output jenkins_url string = 'http://${reference(jenkinsIp_var).dnsSettings.fqdn}'
output ssh string = 'ssh -L 8080:localhost:8080 ${adminUsername}@${reference(jenkinsIp_var).dnsSettings.fqdn}'
output tomcat_url string = 'http://${reference(ipName_var).dnsSettings.fqdn}'
output base_image_id string = imageId