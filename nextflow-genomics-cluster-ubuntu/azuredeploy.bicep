param location string {
  metadata: {
    description: 'Location for all resources'
  }
  default: resourceGroup().location
}
param dnsNameForJumpBox string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Docker Virtual Machine (master node).'
  }
  default: 'jumpbox-${uniqueString(resourceGroup().id)}'
}
param vmImageReference object {
  metadata: {
    description: 'The image to use for VMs created. This can be marketplace or custom image'
    link: 'https://docs.microsoft.com/en-us/nodejs/api/azure-arm-compute/imagereference?view=azure-node-2.2.0'
  }
  default: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
}
param vmNodeSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_F8s_v2'
}
param vmMasterSku string {
  metadata: {
    description: 'Size of the master node.'
  }
  default: 'Standard_F16s_v2'
}
param vmMasterDiskType string {
  allowed: [
    'Premium_LRS'
    'Standard_LRS'
  ]
  metadata: {
    description: 'Choose between a standard disk for and SSD disk for the master node\'s NFS fileshare'
  }
  default: 'Premium_LRS'
}
param vmMasterDiskSize int {
  allowed: [
    32
    64
    128
    256
    512
    1000
    2000
    4000
    10000
  ]
  metadata: {
    description: 'The SSD Size to be used for the NFS file share. For pricing details see https://azure.microsoft.com/en-us/pricing/details/managed-disks/'
  }
  default: 256
}
param vmAdditionalInstallScriptUrl string {
  metadata: {
    description: 'An additional installs script (bash run as root) to be run after nodes/master are configured. Can be used to mount additional storage or do additional setup'
  }
  default: ''
}
param vmAdditionalInstallScriptArgument string {
  metadata: {
    description: 'An argument to be passed to the additional install script'
  }
  default: ''
}
param nextflowInstallUrl string {
  metadata: {
    description: 'The install URL for nextflow, this can be used to pin nextflow versions'
  }
  default: 'https://get.nextflow.io'
}
param instanceCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of cluster VM instances (100 or less).'
  }
  default: 2
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'password'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param vnetName string {
  metadata: {
    description: 'Name of the virtual network to deploy the scale set into.'
  }
  default: 'nfvnet'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet to deploy the scale set into.'
  }
  default: 'nfsubnet'
}
param shareName string {
  metadata: {
    description: 'Azure file share name.'
  }
  default: 'sharedstorage'
}
param mountpointPath string {
  metadata: {
    description: 'Path on VM to mount file shares. \'/datadisks/disk1/\' is a Premium Managed disk with high iops, this will suit most uses.'
  }
  default: '/datadisks/disk1'
}
param nodeMaxCpus int {
  metadata: {
    description: 'Sets the cluster.maxCpus setting on all cluster nodes'
  }
  default: 2
}
param forceUpdateTag string {
  metadata: {
    description: 'Determines whether to run the custom script extension on a subsequent deployment. Use the defaultValue.'
  }
  default: newGuid()
}
param artifactsLocation string {
  metadata: {
    description: '*Advanced* This is best left as default unless you are an advanced user. The base URI where artifacts required by this template are located.'
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: '*Advanced* This should be left as default unless you are an advanced user. The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param diskInitScriptUri string {
  metadata: {
    description: '*Advanced* This should be left as default unless you are an advanced user. The folder in the artifacts location were shared scripts are stored.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'
}
param artifactsNextflowFolder string {
  metadata: {
    description: '*Advanced* This should be left as default unless you are an advanced user. The folder in the artifacts location were nextflow scripts are stored.'
  }
  default: 'scripts'
}

var nextflowInitScript = uri(artifactsLocation, '${artifactsNextflowFolder}/init.sh${artifactsLocationSasToken}')
var jumpboxNICName = 'jumpboxNIC'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var vmssName = 'cluster${uniqueString(dnsNameForJumpBox)}'
var storageAccountType = 'Standard_LRS'
var storageAccountName = 'nfstorage${uniqueString(resourceGroup().id)}'
var storageSuffix = environment().suffixes.storage
var publicIPAddressName = 'jumpboxPublicIP'
var publicIPAddressType = 'Dynamic'
var jumpboxVMName = 'jumpboxVM'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
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
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForJumpBox
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource jumpboxNICName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: jumpboxNICName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    vnetName_resource
  ]
}

resource jumpboxVMName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: jumpboxVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmMasterSku
    }
    osProfile: {
      computerName: jumpboxVMName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: vmImageReference
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          name: 'jumpboxdatadisk'
          diskSizeGB: vmMasterDiskSize
          caching: 'None'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: vmMasterDiskType
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNICName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    jumpboxNICName_resource
  ]
}

resource jumpboxVMName_nfinit 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${jumpboxVMName}/nfinit'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    forceUpdateTag: forceUpdateTag
    settings: {
      fileUris: [
        nextflowInitScript
        diskInitScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash init.sh ${storageAccountName} "${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}" ${shareName} ${storageSuffix} ${mountpointPath} false ${adminUsername} 0 ${nextflowInstallUrl} ${vmAdditionalInstallScriptUrl} ${vmAdditionalInstallScriptArgument}'
    }
  }
  dependsOn: [
    jumpboxVMName_resource
  ]
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-12-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmNodeSku
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: vmImageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
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
      extensionProfile: {
        extensions: [
          {
            name: 'filesextension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              forceUpdateTag: forceUpdateTag
              settings: {
                fileUris: [
                  nextflowInitScript
                  diskInitScriptUri
                ]
              }
              protectedSettings: {
                commandToExecute: 'bash init.sh ${storageAccountName} "${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}" ${shareName} ${storageSuffix} ${mountpointPath} true ${adminUsername} ${nodeMaxCpus} ${nextflowInstallUrl} ${vmAdditionalInstallScriptUrl} ${vmAdditionalInstallScriptArgument}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    vnetName_resource
    storageAccountName_resource
  ]
}

output JumpboxConnectionString string = 'ssh ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'
output ExampleNextflowCommand string = 'nextflow run hello -process.executor ignite -cluster.join path:${mountpointPath}/cifs/cluster -with-timeline runtimeline.html -with-trace -cluster.maxCpus 0'
output ExampleNextflowCommandWithDocker string = 'nextflow run nextflow-io/rnatoy -with-docker -process.executor ignite -cluster.join path:${mountpointPath}/cifs/cluster -with-timeline runtimeline.html -with-trace -cluster.maxCpus 0'