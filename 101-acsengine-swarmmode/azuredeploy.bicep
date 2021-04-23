@minValue(1)
@maxValue(100)
@description('The number of agents for the cluster.  This value can be from 1 to 100')
param agentCount int = 2

@description('Sets the Domain name label for the agent pool IP Address.  The concatenation of the domain name label and the regional DNS zone make up the fully qualified domain name associated with the public IP address.')
param agentEndpointDNSNamePrefix string

@description('Sets the subnet of agent pool \'agent\'.')
param agentSubnet string = '10.0.0.0/16'

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2_v2'

@description('Sets the static IP of the first master')
param firstConsecutiveStaticIP string = '172.16.0.5'

@description('User name for the Linux Virtual Machines (SSH or Password).')
param linuxAdminUsername string

@description('Sets the location for all resources in the cluster')
param location string = resourceGroup().location

@description('Sets the Domain name label for the master IP Address.  The concatenation of the domain name label and the regional DNS zone make up the fully qualified domain name associated with the public IP address.')
param masterEndpointDNSNamePrefix string

@description('Sets the subnet of the master node(s).')
param masterSubnet string = '172.16.0.0/24'

@description('The size of the Virtual Machine.')
param masterVMSize string

@description('A string hash of the master DNS name to uniquely identify the cluster.')
param nameSuffix string = '13957614'

@description('SSH public key used for auth to all Linux machines.  Not Required.  If not set, you must provide a password key.')
param sshRSAPublicKey string

var adminUsername = linuxAdminUsername
var agentCount_var = agentCount
var agentCustomScript = '/usr/bin/nohup /bin/bash -c "/bin/bash /opt/azure/containers/${configureClusterScriptFile} ${clusterInstallParameters} >> /var/log/azure/cluster-bootstrap.log 2>&1 &" &'
var agentEndpointDNSNamePrefix_var = toLower(agentEndpointDNSNamePrefix)
var agentIPAddressName_var = '${orchestratorName}-agent-ip-${agentEndpointDNSNamePrefix_var}-${nameSuffix_var}'
var agentLbBackendPoolName = '${orchestratorName}-agent-${nameSuffix_var}'
var agentLbIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', agentLbName_var, agentLbIPConfigName)
var agentLbIPConfigName = '${orchestratorName}-agent-${nameSuffix_var}'
var agentLbName_var = '${orchestratorName}-agent-${nameSuffix_var}'
var agentRunCmd = 'runcmd:\n -  [ /bin/bash, /opt/azure/containers/install-cluster.sh ]\n\n'
var agentRunCmdFile = ' -  content: |\n        #!/bin/bash\n        sudo mkdir -p /var/log/azure\n        ${agentCustomScript}\n    path: /opt/azure/containers/install-cluster.sh\n    permissions: "0744"\n'
var agentSubnet_var = agentSubnet
var agentSubnetName = '${orchestratorName}-agentsubnet'
var agentVMNamePrefix = '${orchestratorName}-agent-${nameSuffix_var}'
var agentVMSize_var = agentVMSize
var agentVnetSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, agentSubnetName)
var clusterInstallParameters = '${masterCount} ${masterVMNamePrefix_var} ${masterFirstAddrOctet4} ${adminUsername} ${postInstallScriptURI} ${masterFirstAddrPrefix}'
var configureClusterScriptFile = 'configure-swarmmode-cluster.sh'
var location_var = locations[((2 + length(location)) % (1 + length(location)))]
var locations = [
  location
  location
]
var masterAvailabilitySet_var = '${orchestratorName}-master-availabilitySet-${nameSuffix_var}'
var masterCount = 1
var masterCustomScript = '/bin/bash -c "/bin/bash /opt/azure/containers/${configureClusterScriptFile} ${clusterInstallParameters} >> /var/log/azure/cluster-bootstrap.log 2>&1"'
var masterEndpointDNSNamePrefix_var = toLower(masterEndpointDNSNamePrefix)
var masterFirstAddrOctet4 = masterFirstAddrOctets[3]
var masterFirstAddrOctets = split(firstConsecutiveStaticIP, '.')
var masterFirstAddrPrefix = '${masterFirstAddrOctets[0]}.${masterFirstAddrOctets[1]}.${masterFirstAddrOctets[2]}.'
var masterLbBackendPoolName = '${orchestratorName}-master-pool-${nameSuffix_var}'
var masterLbIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', masterLbName_var, masterLbIPConfigName)
var masterLbIPConfigName = '${orchestratorName}-master-lbFrontEnd-${nameSuffix_var}'
var masterLbInboundNatRules = [
  [
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}0')
    }
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSHPort22-${masterVMNamePrefix_var}0')
    }
  ]
  [
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}1')
    }
  ]
  [
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}22')
    }
  ]
  [
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}3')
    }
  ]
  [
    {
      id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}4')
    }
  ]
]
var masterLbName_var = '${orchestratorName}-master-lb-${nameSuffix_var}'
var masterPublicIPAddressName_var = '${orchestratorName}-master-ip-${masterEndpointDNSNamePrefix_var}-${nameSuffix_var}'
var masterSshPort22InboundNatRuleNamePrefix = '${masterLbName_var}/SSHPort22-${masterVMNamePrefix_var}'
var masterSubnet_var = masterSubnet
var masterSubnetName = '${orchestratorName}-masterSubnet'
var masterVMNamePrefix_var = '${orchestratorName}-master-${nameSuffix_var}-'
var masterVMSize_var = masterVMSize
var masterVnetSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, masterSubnetName)
var nameSuffix_var = nameSuffix
var orchestratorName = 'swarmm'
var osImageOffer = 'UbuntuServer'
var osImagePublisher = 'Canonical'
var osImageSKU = '16.04-LTS'
var osImageVersion = 'latest'
var postInstallScriptURI = 'disabled'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var sshRSAPublicKey_var = sshRSAPublicKey
var virtualNetworkName_var = '${orchestratorName}-vnet-${nameSuffix_var}'
var agentVmSizeSuffix = toLower(split(agentVMSize, '_')[1])
var masterVmSizeSuffix = toLower(split(masterVMSize, '_')[1])
var agentDiskType = (contains(agentVmSizeSuffix, 's') ? 'Premium_LRS' : 'StandardSSD_LRS')
var masterDiskType = (contains(masterVmSizeSuffix, 's') ? 'Premium_LRS' : 'StandardSSD_LRS')

resource agentIPAddressName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  location: location_var
  name: agentIPAddressName_var
  properties: {
    dnsSettings: {
      domainNameLabel: agentEndpointDNSNamePrefix_var
    }
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource agentLbName 'Microsoft.Network/loadBalancers@2020-04-01' = {
  location: location_var
  name: agentLbName_var
  properties: {
    backendAddressPools: [
      {
        name: agentLbBackendPoolName
      }
    ]
    frontendIPConfigurations: [
      {
        name: agentLbIPConfigName
        properties: {
          publicIPAddress: {
            id: agentIPAddressName.id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule80'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', agentLbName_var, agentLbBackendPoolName)
          }
          backendPort: 80
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: agentLbIPConfigID
          }
          frontendPort: 80
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', agentLbName_var, 'tcp80Probe')
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'LBRule443'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', agentLbName_var, agentLbBackendPoolName)
          }
          backendPort: 443
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: agentLbIPConfigID
          }
          frontendPort: 443
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', agentLbName_var, 'tcp443Probe')
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'LBRule8080'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', agentLbName_var, agentLbBackendPoolName)
          }
          backendPort: 8080
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: agentLbIPConfigID
          }
          frontendPort: 8080
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', agentLbName_var, 'tcp8080Probe')
          }
          protocol: 'Tcp'
        }
      }
    ]
    probes: [
      {
        name: 'tcp80Probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: 80
          protocol: 'Tcp'
        }
      }
      {
        name: 'tcp443Probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: 443
          protocol: 'Tcp'
        }
      }
      {
        name: 'tcp8080Probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: 8080
          protocol: 'Tcp'
        }
      }
    ]
  }
}

resource agentVMNamePrefix_vmss 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  location: location_var
  name: '${agentVMNamePrefix}-vmss'
  sku: {
    capacity: agentCount_var
    name: agentVMSize_var
    tier: 'Standard'
  }
  tags: {
    creationSource: 'acsengine-${agentVMNamePrefix}-vmss'
  }
  properties: {
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              ipConfigurations: [
                {
                  name: 'nicipconfig'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', agentLbName_var, agentLbBackendPoolName)
                      }
                    ]
                    subnet: {
                      id: agentVnetSubnetID
                    }
                  }
                }
              ]
              primary: true
            }
          }
        ]
      }
      osProfile: {
        adminUsername: adminUsername
        computerNamePrefix: agentVMNamePrefix
        customData: base64('#cloud-config\n\nwrite_files:\n -  encoding: gzip\n    content: !!binary |\n        H4sIACkUqlkAA81ZbXPbNhL+zl+xpTW1nYaipDSXOWeUG8dWLp6rLY9kd24uaWOIhCzWFKEQoGSfq/9+u3ihSFmK3TaZOWUSkuAC++wunt0Fs/NdOEqycMTkxPN2/vzP24EjkY2T6yLnMFywfAqnIubQzzi8FbceCVxMEglJJhVLUwlqwmEs0lQskuwaIjGdiYxnSqJgAMciuuF55RZXRwHJ9VBl/SmTiudyfZhdm6X+gkGe5AqCW8/j0USAj6hzRUgrWqK0IO0I3ljOVCIy34uZ4t5MAsPJx/2jf/UGn476p+f9Ye/Tz73B8KR/1vXbzXan2fLrCNGKc5azKTcm1eGcHg4veoOj/uXZRbdx317agfNB793Jv3Gk40benQyGF4fHxwMcfLH0Dv9zOehdDnv0+OPSQxgXJ2co8NNPw6PByfnF5eAE37xcem8Ph73h5duzHq3/t6X38+nZ4WmvezURUmUI6opGLk/f4kpX2icNIwG/g+Qx7Mqw+ezDr63g77983PugLz983H/WCD+2w12aa5Fumftxr5y9/8xOd3NtCE51rHEnFJk6gEbFIX5d4jzn4+S2FDGK12TeJblUcBjHeSlXOs6Jzqdk94ED64adG8wLffscnH16sK5x5Vh8uXpwr8sA4dvy3t/IRs2y6VRk8K7IItptG/c4OiyTSMTD/+I/Z1wtRH6zt+/dewA7YF5p+mXmFdA/El/a5/ecpWpy123j0FjkkCBp4b7dxC27fA2xwGGAxTXRox/GfB5mRZrCRKnZQUjZ5LqJbNZCyRg+QOMfEPDP0IJf9BgqzvQNgXF7CyZMwojzDBUWWUyMQrIV3AquAWvZYeO/qiWYYCZGyLcyo5yzG30/TvRFppzPoE1rxJhxPIeyrgMCTFwGcgl4o7pMKKfyObCRMEnCZjnfesEkCPMwA2ZWu00UdDyLqxYX8goJRiyDnEuRzvmTotNahad0bJD8v0fiWwQCPUfP1nna6ch0LuWfj9FyA6m8932baq8qDseElUhTmMDSTlvm1/MRdLs4VCaLuok5V0WeAfmXp5JXx9oODy5a6nntpjrfaI9gjcIrs1XS93AaQtPFcQXs4Ro1VevqWzX1eq0va89MNTbajQdaJ+faa37jfpUPl437tTy83JwFTSJ0sZU8HRMFjs+G24Rtom24aJUJncpPEQtQHOPGIOQqCimQ8qFe1HhiNkzZnGxRY8VoizFDIN0c0LOZiVbZvWeebSjqZG6tp9pA5QmX8CPeYSTyuwAXzrDQFVRAg2DBEqXHu+2XEHzuBzohS8zIOLsZa0WUl8nkyVdNCcZq26ZZwxCSLKIICTfG2vD0ZLz0VIIKa+7BToxihHbmU4Gmsn+CMadSLp3vL2fYfK08DTHjVC3FTNdKdHxBAty8PdYv++adDQKYDTG9iZMcgpnZEvIO+TGN7TW0zkQ88yTizdgz7hpSh+gUU+TTBMVReQYHnRevXsJeJoAVavIcRoWiQM8xfe2TqF2BpVKgsylhKcBCGoMSuiAUWXILklZWwBSEc5aHeZGVSPCywk69PAQR7BqXfBganCbAvVseaaDdtcewkLk+Cpg10c/vQUVU0VtN/cfYgKMEBoe3gPDhzZOcFoo5z/Mk5k0iyK6L/Nb4bGBX/WTg10llR8u2R7sGi+G3JFqiJsWISGatDSMDIsx5ypnkEscXWSpYHDY2HwzsxMBODK4KU1PkVXk7vSIPU7RSEbG0EjM36xuwu67gW7Dcne+iCZH8h9tHTDQ5weytSKWW6Bgw8q59abaaSxZYL2iju964lnor3RfSy05YdTAaN41t7b1erDaR1u2WyMbiq0ajDqO1MQM/aLyqiPBYGrA/2hrXtG5vyFYAKr2YX++eXErfXKm3/bD4RuXXhSTD7JgXKXLUxhSoKs9yQTuR/9FTv7e5jyp7Ntc0YL9WdnC2f8Ge7XU1jCtXHKFrdR1i2KIu7DcDLARjfep07dhqlo2O1HLawCBgMWZIlWAWoN4VGnuVFnOfsvErFDI1ZquEiY7r4Fb4hhz9GbP8zmLBqoJEmmnIWHN+E7ivsXHD/leuPnqsAGucyFOuxA3Puv62N4fR5yLJeawJY37bjyxbFm/sWedg6am731Qk4zNCHOgJmJPRqAx7zny/tu4aBx9E7osGtB4IrthTmpbU7dBselmOWUpVwWxWVmGY+T0AuiWIkSjSONtVRJaMR4pCqSO37dRTrufOOQ8MqW1MvS0C6+Y18Bti88rlFn3s2H5Yec/mhExi22JbJsQ9Q7zQwR9gQlxwJDheOx3CbbN7DLjNwZfhr+dGthHaG+/cTQ7bvu1G5IT+xp/sMe8RSEOuDH3nLEnZKEkTdQdi7BxNZ5sD2LXHiF2NlxXUg5Qe08cf080Ql6vraFF3BlkhWTtKOSiHevjp/NzMzS/y8suc/Ap8pLNylY6PU/FJNKxTsLJrq9QrafdkytXAVINQ8kv7/1FmVVhlsf01NtmdgkZs+ogL32F9inEbjbAvo68JtQ3tGk8E+lwfTm6S6IZQi/EYuUbfm+zpVkZ5MlNkRfk/A3Sa8GvNcaf15O54M9jfkSCTYlbR8eaNOdek4jpk9I0ltJ/Xg5EQSqqczQICanE2UQ46b75vw/fmy4Kxs+wC6JzE0U4krbPIfJLXX+eNMDWTKVcI/PGP+naK6zhM50lcdH5j2R32I1OG1ZuSmRgrXJNOJRu4LSeFoohAQIli4dkKvQPkPmjDFFs+zBu4utNnEs+DoFQXcp74H9DolC7TGQAA\n    path: /opt/azure/containers/configure-swarmmode-cluster.sh\n    permissions: "0744"\n\n${agentRunCmdFile}${agentRunCmd}')
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                keyData: sshRSAPublicKey
                path: sshKeyPath
              }
            ]
          }
        }
      }
      storageProfile: {
        imageReference: {
          offer: osImageOffer
          publisher: osImagePublisher
          sku: osImageSKU
          version: 'latest'
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: agentDiskType
          }
        }
      }
    }
  }
  dependsOn: [
    masterPublicIPAddressName
    virtualNetworkName
    agentLbName
  ]
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  location: location_var
  name: virtualNetworkName_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        masterSubnet_var
        agentSubnet_var
      ]
    }
    subnets: [
      {
        name: masterSubnetName
        properties: {
          addressPrefix: masterSubnet_var
        }
      }
      {
        name: agentSubnetName
        properties: {
          addressPrefix: agentSubnet_var
        }
      }
    ]
  }
}

resource masterAvailabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = {
  location: location_var
  name: masterAvailabilitySet_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource masterPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  location: location_var
  name: masterPublicIPAddressName_var
  properties: {
    dnsSettings: {
      domainNameLabel: masterEndpointDNSNamePrefix_var
    }
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource masterLbName 'Microsoft.Network/loadBalancers@2020-04-01' = {
  location: location_var
  name: masterLbName_var
  properties: {
    backendAddressPools: [
      {
        name: masterLbBackendPoolName
      }
    ]
    frontendIPConfigurations: [
      {
        name: masterLbIPConfigName
        properties: {
          publicIPAddress: {
            id: masterPublicIPAddressName.id
          }
        }
      }
    ]
  }
}

resource masterLbName_SSH_masterVMNamePrefix 'Microsoft.Network/loadBalancers/inboundNatRules@2020-04-01' = [for i in range(0, masterCount): {
  location: location_var
  name: '${masterLbName_var}/SSH-${masterVMNamePrefix_var}${i}'
  properties: {
    backendPort: 22
    enableFloatingIP: false
    frontendIPConfiguration: {
      id: masterLbIPConfigID
    }
    frontendPort: (i + 2200)
    protocol: 'Tcp'
  }
  dependsOn: [
    masterLbName
  ]
}]

resource masterSshPort22InboundNatRuleNamePrefix_0 'Microsoft.Network/loadBalancers/inboundNatRules@2020-04-01' = {
  location: location_var
  name: '${masterSshPort22InboundNatRuleNamePrefix}0'
  properties: {
    backendPort: 2222
    enableFloatingIP: false
    frontendIPConfiguration: {
      id: masterLbIPConfigID
    }
    frontendPort: 22
    protocol: 'Tcp'
  }
  dependsOn: [
    masterLbName
  ]
}

resource masterVMNamePrefix_nic 'Microsoft.Network/networkInterfaces@2020-04-01' = [for i in range(0, masterCount): {
  name: '${masterVMNamePrefix_var}nic-${i}'
  location: location_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', masterLbName_var, masterLbBackendPoolName)
            }
          ]
          loadBalancerInboundNatRules: masterLbInboundNatRules[i]
          privateIPAddress: concat(masterFirstAddrPrefix, (i + int(masterFirstAddrOctet4)))
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: masterVnetSubnetID
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    masterLbName
    resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSHPort22-${masterVMNamePrefix_var}0')
    resourceId('Microsoft.Network/loadBalancers/inboundNatRules', masterLbName_var, 'SSH-${masterVMNamePrefix_var}${i}')
  ]
}]

resource masterVMNamePrefix 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, masterCount): {
  name: concat(masterVMNamePrefix_var, i)
  location: location_var
  tags: {
    creationSource: 'acsengine-${masterVMNamePrefix_var}${i}'
  }
  properties: {
    availabilitySet: {
      id: masterAvailabilitySet.id
    }
    hardwareProfile: {
      vmSize: masterVMSize_var
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${masterVMNamePrefix_var}nic-${i}')
        }
      ]
    }
    osProfile: {
      adminUsername: adminUsername
      computerName: concat(masterVMNamePrefix_var, i)
      customData: base64('#cloud-config\n\nwrite_files:\n -  encoding: gzip\n    content: !!binary |\n        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\n    path: /opt/azure/containers/configure-swarmmode-cluster.sh\n    permissions: "0744"\n\n')
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshRSAPublicKey_var
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        offer: osImageOffer
        publisher: osImagePublisher
        sku: osImageSKU
        version: osImageVersion
      }
      osDisk: {
        name: '${masterVMNamePrefix_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: masterDiskType
        }
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', '${masterVMNamePrefix_var}nic-${i}')
    masterAvailabilitySet
  ]
}]

resource masterVMNamePrefix_configuremaster 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, masterCount): {
  name: '${masterVMNamePrefix_var}${i}/configuremaster'
  location: location_var
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: masterCustomScript
    }
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(masterVMNamePrefix_var, i))
  ]
}]

output agentFQDN string = agentIPAddressName.properties.dnsSettings.fqdn
output masterFQDN string = masterPublicIPAddressName.properties.dnsSettings.fqdn