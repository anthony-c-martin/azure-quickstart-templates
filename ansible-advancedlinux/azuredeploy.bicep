@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('Storage account Type. Standard_LRS or Premium_LRS')
param storageAccountType string = 'Premium_LRS'

@allowed([
  'Standard_D1'
  'Standard_DS1'
  'Standard_D2'
  'Standard_DS2'
  'Standard_D3'
  'Standard_DS3'
  'Standard_D4'
  'Standard_DS4'
  'Standard_D11'
  'Standard_DS11'
  'Standard_D12'
  'Standard_DS12'
  'Standard_D13'
  'Standard_DS13'
  'Standard_D14'
  'Standard_DS14'
])
@description('VM Size, for Premium Storage specify DS VMs.')
param vmSize string = 'Standard_DS2'

@description('Data disks Size in GBs')
param vmSizeDataDisks int = 120

@allowed([
  'ext4'
  'xfs'
])
@description('Linux File system')
param linuxFileSystem string = 'ext4'

@description('Servers role, for instance webtier, database.A tag will be created with the provided value')
param serversRole string = 'Generic'

@description('Servers purpose, for instance development, test, pre-production, production. A tag will be created with the provided value')
param serversPurpose string = 'DEV'

@description('Number of VMs. The template will create N number of identical VMs')
param numberOfVms int = 3

@description('Admin user name')
param adminUsername string

@description('Private storage account name in which you are storing your ssh certificates')
param sshStorageAccountName string

@description('Private storage account key in which you are storing your ssh certificates')
@secure()
param sshStorageAccountKey string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@allowed([
  'Static'
  'Dynamic'
])
@description('Public facing IP Type.')
param publicIPType string = 'Dynamic'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ansible-advancedlinux/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var vmStorageAccountContainerName = 'vhds'
var createRAID = 'true'
var availabilitySetName_var = 'ANS01'
var faultDomainCount = '3'
var updateDomainCount = '10'
var virtualNetworkName_var = 'VNet01'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'FrontEnd'
var subnet2Name = 'Backend'
var subnet1Prefix = '10.0.1.0/24'
var subnet2Prefix = '10.0.2.0/24'
var publicIPName_var = 'VIP01'
var vmNamePattern_var = 'ANS'
var VMIPAddressStart = '10.0.2.2'
var vmNICNamePattern_var = 'ANS'
var loadBalancerName_var = 'PLB'
var sshNatRuleFrontEndPort = '6400'
var sshNatRuleBackEndPort = '22'
var publicIPRef = publicIPName.id
var NICipconfig = 'ipCnfgBE'
var NICRef = resourceId('Microsoft.Network/networkInterfaces', vmNICNamePattern_var)
var DNSNameLB = concat(dnsLabelPrefix)
var vnetRef = virtualNetworkName.id
var subnetBackEndRef = '${vnetRef}/subnets/${subnet2Name}'
var FrontEndRef = '${vnetRef}/subnets/${subnet1Name}'
var loadBalancerRef = loadBalancerName.id
var lbRuleName = 'lbRuleANSAdmin'
var lbRuleRef = '${loadBalancerRef}/loadBalancingRules/${lbRuleName}'
var lbFEConfig = 'LBAnsFrontConfg'
var lbFEConfigRef = '${loadBalancerRef}/frontendIPConfigurations/${lbFEConfig}'
var lbBEConfig = 'LBBEAnsFrontConfg'
var lbBEConfigRef = '${loadBalancerRef}/backendAddressPools/${lbBEConfig}'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var sshRootCerBlobLocation = 'id_rsa'
var nginxConfigLocation = 'nginx'
var sshRootPubBlobLocation = 'id_rsa.pub'
var ansiblePlaybookLocation = 'InitStorage_RAID.yml'
var customScriptAnsibleFile = 'configure_ansible.sh'
var customScriptAnsibleUrl = uri(artifactsLocation, concat(customScriptAnsibleFile, artifactsLocationSasToken))
var customScriptAnsibleCommand = 'bash ${customScriptAnsibleFile}'
var customScriptAnsibleParameters = ' -i ${VMIPAddressStart} -n ${numberOfVms} -r ${createRAID} -f ${linuxFileSystem}'
var customScriptSSHRootFile = 'configure_ssh_root.sh'
var customScriptSSHRootUrl = uri(artifactsLocation, concat(customScriptSSHRootFile, artifactsLocationSasToken))
var customScriptSSHRootCommand = 'bash ${customScriptSSHRootFile} -a ${sshStorageAccountName} -k ${sshStorageAccountKey}'
var ansiblePlaybookUrl = uri(artifactsLocation, concat(ansiblePlaybookLocation, artifactsLocationSasToken))
var pythonAzureScriptUrl = uri(artifactsLocation, 'GetSSHFromPrivateStorageAccount.py${artifactsLocationSasToken}')
var ansibleVmTypes = {
  Premium_LRS: {
    vmSize: 'Standard_DS1'
  }
  Standard_LRS: {
    vmSize: 'Standard_A1'
  }
}
var currentEnvironmentSettings = ansibleVmTypes[storageAccountType]
var ansibleVmType = currentEnvironmentSettings.vmSize
var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}stg'
var storageRef = 'Microsoft.Storage/storageAccounts/${newStorageAccountName_var}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource publicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPType
    dnsSettings: {
      domainNameLabel: DNSNameLB
    }
  }
  dependsOn: [
    vnetRef
  ]
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFEConfig
        properties: {
          publicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBEConfig
      }
    ]
    inboundNatRules: [
      {
        name: 'sshToAnsibleControllerNAT'
        properties: {
          frontendIPConfiguration: {
            id: lbFEConfigRef
          }
          protocol: 'Tcp'
          frontendPort: '${sshNatRuleFrontEndPort}0'
          backendPort: sshNatRuleBackEndPort
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    publicIPRef
  ]
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: faultDomainCount
    platformUpdateDomainCount: updateDomainCount
  }
}

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource vmNICNamePattern 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfVms): {
  name: concat(vmNICNamePattern_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: NICipconfig
        properties: {
          privateIPAllocationMethod: 'Static '
          privateIPAddress: concat(VMIPAddressStart, i)
          subnet: {
            id: subnetBackEndRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: lbBEConfigRef
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetRef
    loadBalancerRef
  ]
}]

resource vmNamePattern 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfVms): {
  name: concat(vmNamePattern_var, i)
  location: location
  tags: {
    ServerRole: serversRole
    ServerEnvironment: serversPurpose
  }
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePattern_var, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.5-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmNamePattern_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmNamePattern_var}${i}_DataDisk1'
          diskSizeGB: vmSizeDataDisks
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
        {
          name: '${vmNamePattern_var}${i}_DataDisk2'
          diskSizeGB: vmSizeDataDisks
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
        {
          name: '${vmNamePattern_var}${i}_DataDisk3'
          diskSizeGB: vmSizeDataDisks
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
        {
          name: '${vmNamePattern_var}${i}_DataDisk4'
          diskSizeGB: vmSizeDataDisks
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: concat(NICRef, i)
        }
      ]
    }
  }
  dependsOn: [
    storageRef
    concat(NICRef, i)
    availabilitySetName
  ]
}]

resource vmNamePattern_configuressh 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfVms): {
  name: '${vmNamePattern_var}${i}/configuressh'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptSSHRootUrl
        pythonAzureScriptUrl
      ]
      commandToExecute: customScriptSSHRootCommand
      protectedSettings: {}
    }
  }
  dependsOn: [
    vmNamePattern
  ]
}]

resource AnsibleController 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'AnsibleController'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: NICipconfig
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(VMIPAddressStart, numberOfVms)
          subnet: {
            id: subnetBackEndRef
          }
          loadBalancerInboundNatRules: [
            {
              id: '${loadBalancerRef}/inboundNatRules/sshToAnsibleControllerNAT'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetRef
    loadBalancerRef
  ]
}

resource Microsoft_Compute_virtualMachines_AnsibleController 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'AnsibleController'
  location: location
  tags: {
    ServerRole: 'AnsibleController'
    ServerEnvironment: serversPurpose
  }
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: ansibleVmType
    }
    osProfile: {
      computerName: 'AnsibleController'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.5-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'AnsibleController_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: AnsibleController.id
        }
      ]
    }
  }
  dependsOn: [
    storageRef

    vmNamePattern
  ]
}

resource AnsibleController_installAnsible 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: Microsoft_Compute_virtualMachines_AnsibleController
  name: 'installAnsible'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptAnsibleUrl
        ansiblePlaybookUrl
        pythonAzureScriptUrl
      ]
      commandToExecute: '${customScriptAnsibleCommand}${customScriptAnsibleParameters} -a ${sshStorageAccountName} -k ${sshStorageAccountKey}'
      protectedSettings: {}
    }
  }
  dependsOn: [
    vmNamePattern_configuressh
  ]
}

output sshResourceURL string = 'SSH Url to Ansible Controller:${adminUsername}@${reference(publicIPRef, '2015-06-15').dnsSettings.fqdn} -p ${sshNatRuleFrontEndPort}'