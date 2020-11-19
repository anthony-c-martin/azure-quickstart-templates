param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-linux-dynamic-data-disks/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique public dns prefix where the  node will be exposed'
  }
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine. Pick a valid username otherwise there will be a BadRequest error.'
  }
  default: 'azureuser'
}
param imagePublisher string {
  allowed: [
    'Canonical'
    'openlogic'
  ]
  metadata: {
    description: 'openlogic/Canonical are the respective CentOS/Ubuntu Distributor in Azure Market Place'
  }
  default: 'openlogic'
}
param imageOffer string {
  allowed: [
    'CentOS'
    'UbuntuServer'
  ]
  metadata: {
    description: 'New CentOS/UbuntuServer Image Offer'
  }
  default: 'CentOS'
}
param imageSku string {
  allowed: [
    '16.04.0-LTS'
    '6.5'
    '6.6'
    '7.1'
    '7.2'
  ]
  metadata: {
    description: 'P.S: OpenLogic CentOS version to use **docker usage Only for 7.1/7.2 kernels 3.10 and above **'
  }
  default: '7.2'
}
param sshPublicKey string {
  metadata: {
    description: 'This field must be a valid SSH public key. ssh with this RSA public key'
  }
  secure: true
}
param mountFolder string {
  metadata: {
    description: 'The Folder system to be auto-mounted.'
  }
  default: '/data'
}
param nodeSize string {
  allowed: [
    'Standard_DS1'
    'Basic_A0'
    'Basic_A1'
    'Basic_A2'
    'Basic_A3'
    'Basic_A4'
    'Standard_A0'
    'Standard_A1'
    'Standard_A10'
    'Standard_A11'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_D1'
    'Standard_D11'
    'Standard_D11_v2'
    'Standard_D12'
    'Standard_D12_v2'
    'Standard_D13'
    'Standard_D13_v2'
    'Standard_D14'
    'Standard_D14_v2'
    'Standard_D15_v2'
    'Standard_D1_v2'
    'Standard_D2'
    'Standard_D2_v2'
    'Standard_D3'
    'Standard_D3_v2'
    'Standard_D4'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_DS1'
    'Standard_DS11'
    'Standard_DS11_v2'
    'Standard_DS12'
    'Standard_DS12_V2'
    'Standard_DS12_v2'
    'Standard_DS13'
    'Standard_DS13_v2'
    'Standard_DS14'
    'Standard_DS14_v2'
    'Standard_DS15_v2'
    'Standard_DS1_v2'
    'Standard_DS2'
    'Standard_DS2_v2'
    'Standard_DS3'
    'Standard_DS3_v2'
    'Standard_DS4'
    'Standard_DS4_v2'
    'Standard_DS5_v2'
    'Standard_G1'
    'Standard_G2'
    'Standard_G3'
    'Standard_G4'
    'Standard_G5'
    'Standard_GS1'
    'Standard_GS2'
    'Standard_GS3'
    'Standard_GS4'
    'Standard_GS5'
  ]
  metadata: {
    description: 'Size of the  node.'
  }
  default: 'Standard_DS2_v2'
}
param storageType string {
  allowed: [
    'Standard_LRS'
    'Premium_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'Storage Account Type : Standard-LRS, Standard-GRS, Standard-RAGRS, Standard-ZRS'
  }
  default: 'Standard_LRS'
}
param dockerVer string {
  metadata: {
    description: 'The docker version **Only for 7.1/7.2 kernels 3.10 and above **'
  }
  default: '1.12'
}
param dockerComposeVer string {
  metadata: {
    description: 'The Docker Compose Version **Only for 7.1/7.2 kernels 3.10 and above **'
  }
  default: '1.9.0-rc2'
}
param dockerMachineVer string {
  metadata: {
    description: 'The docker-machine version **Only for 7.1/7.2 kernels 3.10 and above **'
  }
  default: '0.8.2'
}
param dataDiskSize int {
  metadata: {
    description: 'The size in GB of each data disk that is attached to the VM.  A MDADM RAID0  is created with all data disks auto-mounted,  that is dataDiskSize * dataDiskCount in size n the Storage .'
  }
  default: 10
}
param masterVMName string {
  allowed: [
    'centos'
    'ubuntuserver'
  ]
  metadata: {
    description: 'The Name of the VM.'
  }
  default: 'centos'
}
param numDataDisks int {
  minValue: 0
  maxValue: 64
  metadata: {
    description: 'This parameter allows the user to select the number of disks wanted'
  }
  default: '4'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var avSetName_var = 'avSet'
var diskCaching = 'ReadWrite'
var networkSettings = {
  virtualNetworkName: 'virtualnetwork'
  addressPrefix: '10.0.0.0/16'
  subnet: {
    dse: {
      name: 'dse'
      prefix: '10.0.0.0/24'
      vnet: 'virtualnetwork'
    }
  }
  statics: {
    master: '10.0.0.254'
  }
}
var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}dynamicdisk'
var nicName_var = 'nic'
var OSDiskName = 'osdisk'
var publicIPAddressName_var = 'publicips'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhd'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.virtualNetworkName, networkSettings.subnet.dse.name)
var installationCLI = 'bash azuredeploy.sh ${masterVMName} ${mountFolder} ${numDataDisks} ${dockerVer} ${dockerComposeVer} ${adminUsername} ${imageSku} ${dockerMachineVer}'
var storageAccountType = storageType
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var networkSecurityGroupName_var = 'default-NSG'

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource avSetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: avSetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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

resource networkSettings_virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-03-01' = {
  name: networkSettings.virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkSettings.addressPrefix
      ]
    }
    subnets: [
      {
        name: networkSettings.subnet.dse.name
        properties: {
          addressPrefix: networkSettings.subnet.dse.prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-03-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-03-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: networkSettings.statics.master
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource masterVMName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: masterVMName
  location: location
  properties: {
    availabilitySet: {
      id: avSetName.id
    }
    hardwareProfile: {
      vmSize: nodeSize
    }
    osProfile: {
      computerName: masterVMName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${masterVMName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      copy: [
        {
          name: 'dataDisks'
          count: numDataDisks
          input: {
            caching: diskCaching
            diskSizeGB: dataDiskSize
            lun: copyIndex('dataDisks')
            name: '${masterVMName}-datadisk${copyIndex('dataDisks')}'
            createOption: 'Empty'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
}

resource masterVMName_Installation 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  name: '${masterVMName}/Installation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        concat(uri(artifactsLocation, 'azuredeploy.sh'), artifactsLocationSasToken)
      ]
      commandToExecute: installationCLI
    }
  }
}