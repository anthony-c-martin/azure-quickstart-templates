@description('Blob Shared Access Signature(SAS) URL to the SAS license.')
param DeploymentDataLocation string

@description('The full ssh public key that will be added to the servers.')
param SSHPublicKey string

@description('The location in Microsoft Azure where these resources should be created.')
param location string = resourceGroup().location

@description('Allow inbound HTTP traffic to the SAS Viya Environment from this CIDR block (IP address range). Must be a valid IP CIDR range of the form x.x.x.x/x.')
param WebIngressLocation string

@description('Allow inbound SSH traffic to the Ansible Controller from this CIDR block (IP address range). Must be a valid IP CIDR range of the form x.x.x.x/x.')
param AdminIngressLocation string

@minLength(6)
@maxLength(255)
@description('Password of the SAS Admin Users (sasboot, optionally sasadmin). Must have at least 6 and no more than 255 characters. Single quotes (\') are not allowed.')
@secure()
param SASAdminPass string

@description('Password of the default SAS User (sasuser). If left empty, no default users are created. (WARNING: If not set, deployment will require additional setup steps before it is usable). Single quotes (\') are not allowed.')
@secure()
param SASUserPass string = ''

@description('OPTIONAL: Specifies the https location of a SAS mirror. Mirror should be a path to a mirror directory tree in blob storage.')
param DeploymentMirror string = ''

@description('This is the SKU for the Ansible/Bastion VM.')
param Ansible_VM_SKU string = 'Standard_B2s'

@description('This is the SKU for the Services VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks.')
param Services_VM_SKU string = 'Standard_E8s_v3'

@description('This is the SKU for the Controller VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks.')
param Controller_VM_SKU string = 'Standard_E8s_v3'

@minValue(1)
@maxValue(10)
@description('The number of CAS nodes in the deployment. If this is set to 1, an SMP environment is built with one CAS controller. If this is set to a value of 2 or more, an MPP environment is built (n workers + 1 controller). In the MPP environment case, you should shrink the size of the CAS controller as it will only be performing orchestration.')
param CAS_Node_Count int = 1

@description('This is the SKU for the CAS worker VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks.')
param CAS_Worker_VM_SKU string = 'Standard_E8s_v3'

@description('For a standard deployment, leave empty. If you are running from a blob template, then provide the Shared Access Signature token (starting with a ?) that grants authorization to the private template. ')
@secure()
param artifactsLocationSasToken string = ''

@description('For a standard deployment, keep the default.  The https URL to the base of the deployment files in Microsoft Azure. If a SAS key is needed, please do not include the SAS key in the URL.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sas-viya/'

var resourceGroupUniqueString = uniqueString(resourceGroup().id)
var VirtualNetworkName = 'viyanetwork_${resourceGroupUniqueString}'
var VirtualNetworkPrivateSubnet = '${VirtualNetworkName}_private'
var VirtualNetworkPrivateSubnetCIDR = '10.0.127.0/24'
var VirtualNetworkPublicSubnet = '${VirtualNetworkName}_public'
var VirtualNetworkPublicSubnetCIDR = '10.0.128.0/24'
var VirtualNetworkApplicationGatewaySubnet = '${VirtualNetworkName}_applicationGateway'
var VirtualNetworkApplicationGatewaySubnetCIDR = '10.0.129.0/24'
var DiagnosticStorageGroupName_var = toLower('rg4diag${resourceGroupUniqueString}')
var AzureFilesViyaShare = 'viyashare'
var PrimaryUserName = 'vmuser'
var ExtensionAnsibleURI = '${artifactsLocation}nestedtemplates/run_ansible_script.json${artifactsLocationSasToken}'
var NetworkCreateTemplateURI = '${artifactsLocation}nestedtemplates/createNetworkSubtemplate.json${artifactsLocationSasToken}'
var AlternateDomain = 'viya-${subscription().subscriptionId}-${resourceGroupUniqueString}'
var DomainActual = substring(AlternateDomain, 0, ((length(AlternateDomain) <= 60) ? length(AlternateDomain) : 60))
var Base64AdminPass = base64(SASAdminPass)
var Base64UserPass = base64(SASUserPass)

resource PrimaryViyaLoadbalancer_PublicIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: 'PrimaryViyaLoadbalancer_PublicIP'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: DomainActual
    }
  }
}

resource PrimaryViyaLoadbalancer_NetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: 'PrimaryViyaLoadbalancer_NetworkSecurityGroup'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-https'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: WebIngressLocation
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-backend-health'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65503-65534'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
    ]
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from the Microsoft Azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

module CreateNetwork '?' /*TODO: replace with correct path to [variables('NetworkCreateTemplateURI')]*/ = {
  name: 'CreateNetwork'
  params: {
    location: location
    virtualNetworkName: VirtualNetworkName
    addressPrefix: '10.0.0.0/16'
    VirtualNetworkPrivateSubnet: VirtualNetworkPrivateSubnet
    VirtualNetworkPublicSubnet: VirtualNetworkPublicSubnet
    VirtualNetworkApplicationGatewaySubnet: VirtualNetworkApplicationGatewaySubnet
    VirtualNetworkPrivateSubnetCIDR: VirtualNetworkPrivateSubnetCIDR
    VirtualNetworkPublicSubnetCIDR: VirtualNetworkPublicSubnetCIDR
    VirtualNetworkApplicationGatewaySubnetCIDR: VirtualNetworkApplicationGatewaySubnetCIDR
    LoadBalancerNetworkSecurityGroup: 'PrimaryViyaLoadbalancer_NetworkSecurityGroup'
  }
  dependsOn: [
    PrimaryViyaLoadbalancer_NetworkSecurityGroup
  ]
}

resource PrimaryViyaLoadbalancer 'Microsoft.Network/applicationGateways@2019-09-01' = {
  name: 'PrimaryViyaLoadbalancer'
  location: location
  properties: {
    sku: {
      name: 'Standard_Small'
      tier: 'Standard'
      capacity: 1
    }
    sslPolicy: {
      policyType: 'Custom'
      cipherSuites: [
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
      ]
      minProtocolVersion: 'TLSv1_2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, VirtualNetworkApplicationGatewaySubnet)
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'appGatewayFrontendCertificate'
        properties: {
          data: json(concat(split(reference('AnsiblePhase2GetLBCertPart1').outputs.instanceView.value.statuses[0].message, '#DATA#')[1], split(reference('AnsiblePhase3GetLBCertPart2').outputs.instanceView.value.statuses[0].message, '#DATA#')[1])).data
          password: json(concat(split(reference('AnsiblePhase2GetLBCertPart1').outputs.instanceView.value.statuses[0].message, '#DATA#')[1], split(reference('AnsiblePhase3GetLBCertPart2').outputs.instanceView.value.statuses[0].message, '#DATA#')[1])).password
        }
      }
    ]
    authenticationCertificates: [
      {
        name: 'viya-ca.cer'
        properties: {
          data: split(reference('AnsiblePhase5GetCACert').outputs.instanceView.value.statuses[0].message, '#DATA#')[1]
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: PrimaryViyaLoadbalancer_PublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: Services_NetworkInterface.properties.ipConfigurations[0].properties.privateIPAddress
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 30000
          authenticationCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/authenticationCertificates', 'PrimaryViyaLoadbalancer', 'viya-ca.cer')
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'PrimaryViyaLoadbalancer', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'PrimaryViyaLoadbalancer', 'appGatewayFrontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'PrimaryViyaLoadbalancer', 'appGatewayFrontendCertificate')
          }
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'PrimaryViyaLoadbalancer', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'PrimaryViyaLoadbalancer', 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'PrimaryViyaLoadbalancer', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    enableHttp2: true
  }
  dependsOn: [
    services
    CreateNetwork
  ]
}

resource AnsibleController_NetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: 'AnsibleController_NetworkSecurityGroup'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: AdminIngressLocation
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from the Microsoft Azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource AnsibleController_PublicIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: 'AnsibleController_PublicIP'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource AnsibleController_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: 'AnsibleController_NetworkInterface'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: AnsibleController_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, VirtualNetworkPublicSubnet)
          }
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: github_accessor.id
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: AnsibleController_NetworkSecurityGroup.id
    }
  }
  dependsOn: [
    CreateNetwork
  ]
}

resource Ansible 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'Ansible'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: Ansible_VM_SKU
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'Ansible_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
    }
    osProfile: {
      computerName: 'Ansible'
      adminUsername: PrimaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${PrimaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: AnsibleController_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(DiagnosticStorageGroupName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    DiagnosticStorageGroupName
  ]
}

module AnsiblePhase1SetupHostForAnsible '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase1SetupHostForAnsible'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./ansiblecontroller_startup.sh "1" "${artifactsLocation}" "${artifactsLocationSasToken}" "${DeploymentDataLocation}" "${PrimaryUserName}" "${Base64AdminPass}" "${Base64UserPass}" "${VirtualNetworkPrivateSubnetCIDR}" "${PrimaryViyaLoadbalancer_PublicIP.properties.dnsSettings.fqdn}" "${DeploymentMirror}" "${DiagnosticStorageGroupName_var}" "${AzureFilesViyaShare}" "${listKeys(DiagnosticStorageGroupName_var, '2019-06-01').keys[0].value}" "${CAS_Node_Count}" "" 2>&1 | tee /var/log/sas/install/runAnsiblePhase1_SetupPrerequisites.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Ansible
  ]
}

module AnsiblePhase2GetLBCertPart1 '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase2GetLBCertPart1'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "3"  2>&1 | tee /var/log/sas/install/runAnsiblePhase2_CertificateExport_1.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase1SetupHostForAnsible
  ]
}

module AnsiblePhase3GetLBCertPart2 '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase3GetLBCertPart2'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "4"  2>&1 | tee /var/log/sas/install/runAnsiblePhase3_CertificateExport_2.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase2GetLBCertPart1
  ]
}

module AnsiblePhase4PreViyaInstall '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase4PreViyaInstall'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "5"  2>&1 | tee /var/log/sas/install/runAnsiblePhase4_PRE_INSTALL.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase3GetLBCertPart2
  ]
}

module AnsiblePhase5GetCACert '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase5GetCACert'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "6"  2>&1 | tee /var/log/sas/install/runAnsiblePhase5_SAS_CA_CRT.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase4PreViyaInstall
  ]
}

module AnsiblePhase6Part1RunViyaInstall '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase6Part1RunViyaInstall'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "7"  2>&1 | tee /var/log/sas/install/runAnsiblePhase6Part1_SAS_INSTALL.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase5GetCACert
  ]
}

module AnsiblePhase6Part2RunViyaInstall '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase6Part2RunViyaInstall'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "7"  2>&1 | tee /var/log/sas/install/runAnsiblePhase6Part2_SAS_INSTALL.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase6Part1RunViyaInstall
  ]
}

module AnsiblePhase6Part3RunViyaInstall '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase6Part3RunViyaInstall'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "7"  2>&1 | tee /var/log/sas/install/runAnsiblePhase6Part3_SAS_INSTALL.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase6Part2RunViyaInstall
  ]
}

module AnsiblePhase7PostViyaInstall '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase7PostViyaInstall'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "8"  2>&1 | tee /var/log/sas/install/runAnsiblePhase7_POST_INSTALL.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase6Part3RunViyaInstall
  ]
}

module AnsiblePhase8GetCASURIsFromLicense '?' /*TODO: replace with correct path to [variables('ExtensionAnsibleURI')]*/ = {
  name: 'AnsiblePhase8GetCASURIsFromLicense'
  params: {
    location: location
    vmName: 'Ansible'
    commandToExecute: 'set -o pipefail; ./ansiblecontroller_startup.sh "9"  2>&1 | tee /var/log/sas/install/runAnsiblePhase8_ReturnCasSize.log'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    AnsiblePhase7PostViyaInstall
  ]
}

resource CASController_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: 'CASController_NetworkInterface'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, VirtualNetworkPrivateSubnet)
          }
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: github_accessor.id
            }
            {
              id: sas_services_accessor.id
            }
            {
              id: sas_viya_provider.id
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: Viya_NetworkSecurityGroup.id
    }
  }
  dependsOn: [
    CreateNetwork
  ]
}

resource DiagnosticStorageGroupName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  name: DiagnosticStorageGroupName_var
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource controller 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'controller'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: Controller_VM_SKU
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'controller_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
      dataDisks: [
        {
          lun: 0
          name: 'controllerOptDisk'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 256
        }
      ]
    }
    osProfile: {
      computerName: 'controller'
      adminUsername: PrimaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${PrimaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
      customData: base64('#include\n${uri(artifactsLocation, 'cloudinit/controller.txt${artifactsLocationSasToken}')}')
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: CASController_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(DiagnosticStorageGroupName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    DiagnosticStorageGroupName
  ]
}

resource controller_CASStartup 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: controller
  name: 'CASStartup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
    }
    protectedSettings: {
      commandToExecute: 'set -o pipefail; ./nonansiblecontroller_prereqs.sh "${PrimaryUserName}" "${DiagnosticStorageGroupName_var}" "${AzureFilesViyaShare}" "${listKeys(DiagnosticStorageGroupName_var, '2019-06-01').keys[0].value}" "CasControllerServers" 2>&1 | tee /tmp/prerequisites.log'
      fileUris: [
        '${artifactsLocation}scripts/nonansiblecontroller_prereqs.sh${artifactsLocationSasToken}'
      ]
    }
  }
  dependsOn: [
    Ansible
    AnsiblePhase1SetupHostForAnsible
  ]
}

resource worker_1_2_0_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-09-01' = [for i in range(0, ((CAS_Node_Count == 1) ? 0 : CAS_Node_Count)): {
  name: 'worker${padLeft((i + 1), 2, '0')}_NetworkInterface'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, VirtualNetworkPrivateSubnet)
          }
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: github_accessor.id
            }
            {
              id: sas_services_accessor.id
            }
            {
              id: sas_viya_provider.id
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: Viya_NetworkSecurityGroup.id
    }
  }
  dependsOn: [
    Viya_NetworkSecurityGroup
    github_accessor
    sas_services_accessor
    sas_viya_provider
    CreateNetwork
  ]
}]

resource worker_1_2_0 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, ((CAS_Node_Count == 1) ? 0 : CAS_Node_Count)): {
  name: 'worker${padLeft((i + 1), 2, '0')}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: CAS_Worker_VM_SKU
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'worker${padLeft((i + 1), 2, '0')}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
      dataDisks: [
        {
          lun: 0
          name: 'worker${padLeft((i + 1), 2, '0')}OptDisk'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 256
        }
      ]
    }
    osProfile: {
      computerName: 'worker${padLeft((i + 1), 2, '0')}'
      adminUsername: PrimaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${PrimaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
      customData: base64('#include\n${uri(artifactsLocation, 'cloudinit/controller.txt${artifactsLocationSasToken}')}')
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'worker${padLeft((i + 1), 2, '0')}_NetworkInterface')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: DiagnosticStorageGroupName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', 'worker${padLeft((i + 1), 2, '0')}_NetworkInterface')
    DiagnosticStorageGroupName
  ]
}]

resource worker_1_2_0_CASStartup 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, ((CAS_Node_Count == 1) ? 0 : CAS_Node_Count)): {
  name: 'worker${padLeft((i + 1), 2, '0')}/CASStartup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
    }
    protectedSettings: {
      commandToExecute: 'set -o pipefail; ./nonansiblecontroller_prereqs.sh "${PrimaryUserName}" "${DiagnosticStorageGroupName_var}" "${AzureFilesViyaShare}" "${listKeys(DiagnosticStorageGroupName_var, '2019-06-01').keys[0].value}" "CasControllerServers" 2>&1 | tee /tmp/prerequisites.log'
      fileUris: [
        '${artifactsLocation}scripts/nonansiblecontroller_prereqs.sh${artifactsLocationSasToken}'
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', 'worker${padLeft((i + 1), 2, '0')}')
    Ansible
    AnsiblePhase1SetupHostForAnsible
  ]
}]

resource Viya_NetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: 'Viya_NetworkSecurityGroup'
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from the Microsoft Azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource Services_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: 'Services_NetworkInterface'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, VirtualNetworkPrivateSubnet)
          }
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: github_accessor.id
            }
            {
              id: sas_services_provider.id
            }
            {
              id: sas_viya_accessor.id
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: Viya_NetworkSecurityGroup.id
    }
  }
  dependsOn: [
    CreateNetwork
  ]
}

resource services 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'services'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: Services_VM_SKU
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'services_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
      dataDisks: [
        {
          lun: 0
          name: 'servicesOptDisk'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 256
        }
      ]
    }
    osProfile: {
      computerName: 'services'
      adminUsername: PrimaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${PrimaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Services_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(DiagnosticStorageGroupName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    DiagnosticStorageGroupName
  ]
}

resource services_ServicesStartup 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: services
  name: 'ServicesStartup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
    }
    protectedSettings: {
      commandToExecute: 'set -o pipefail; ./nonansiblecontroller_prereqs.sh "${PrimaryUserName}" "${DiagnosticStorageGroupName_var}" "${AzureFilesViyaShare}" "${listKeys(DiagnosticStorageGroupName_var, '2019-06-01').keys[0].value}" "VisualServicesServers,ProgrammingServicesServers,StatefulServicesServers" 2>&1 | tee /tmp/prerequisites.log'
      fileUris: [
        '${artifactsLocation}scripts/nonansiblecontroller_prereqs.sh${artifactsLocationSasToken}'
      ]
    }
  }
  dependsOn: [
    Ansible
    AnsiblePhase1SetupHostForAnsible
  ]
}

resource github_accessor 'Microsoft.Network/applicationSecurityGroups@2019-09-01' = {
  name: 'github-accessor'
  location: location
  properties: {}
}

resource sas_services_accessor 'Microsoft.Network/applicationSecurityGroups@2019-09-01' = {
  name: 'sas-services-accessor'
  location: location
  properties: {}
}

resource sas_services_provider 'Microsoft.Network/applicationSecurityGroups@2019-09-01' = {
  name: 'sas-services-provider'
  location: location
  properties: {}
}

resource sas_viya_accessor 'Microsoft.Network/applicationSecurityGroups@2019-09-01' = {
  name: 'sas-viya-accessor'
  location: location
  properties: {}
}

resource sas_viya_provider 'Microsoft.Network/applicationSecurityGroups@2019-09-01' = {
  name: 'sas-viya-provider'
  location: location
  properties: {}
}

module pid_479ba1d7_9b83_427f_b94f_ce441afe2b5c './nested_pid_479ba1d7_9b83_427f_b94f_ce441afe2b5c.bicep' = {
  name: 'pid-479ba1d7-9b83-427f-b94f-ce441afe2b5c'
  params: {}
}

output AnsibleControllerIP string = reference('AnsibleController_PublicIP').ipAddress
output SASDrive string = (empty(DeploymentDataLocation) ? 'A testing license string was provided instead of a valid license URI. Therefore, SAS was not actually installed. Please replace DeploymentDataLocation with a valid license URI. For further details, see the Troubleshooting section in the Readme.' : 'https://${reference('PrimaryViyaLoadbalancer_PublicIP').dnsSettings.fqdn}${json(split(reference('AnsiblePhase8GetCASURIsFromLicense').outputs.instanceView.value.statuses[0].message, '#DATA#')[1]).SAS_DRIVE}')
output SASStudio string = (empty(DeploymentDataLocation) ? 'A testing license string was provided instead of a valid license URI. Therefore, SAS was not actually installed. Please replace DeploymentDataLocation with a valid license URI. For further details, see the Troubleshooting section in the Readme.' : 'https://${reference('PrimaryViyaLoadbalancer_PublicIP').dnsSettings.fqdn}${json(split(reference('AnsiblePhase8GetCASURIsFromLicense').outputs.instanceView.value.statuses[0].message, '#DATA#')[1]).SAS_STUDIO}')