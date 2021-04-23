@minLength(3)
@maxLength(6)
@description('The prefix that should be used to create the resource names.')
param resourcePrefix string = 'dev'

@description('The number of SAP systems that will use this file server')
param sapSystemCount int = 1

@allowed([
  'Windows Server 2016 Datacenter'
  'SLES 12'
  'SLES 12 BYOS'
  'RHEL 7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2016 Datacenter'

@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-file-server-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var images = {
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSFamily: 'Windows'
    OSType: 'Windows'
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    version: 'latest'
    OSFamily: 'SLES'
    OSType: 'Linux'
  }
  'SLES 12 BYOS': {
    sku: '12-SP3'
    offer: 'SLES-SAP-BYOS'
    publisher: 'SUSE'
    OSType: 'Linux'
    OSFamily: 'SLES'
    version: 'latest'
  }
  'RHEL 7': {
    sku: '7.4'
    offer: 'RHEL'
    publisher: 'RedHat'
    OSType: 'Linux'
    OSFamily: 'RHEL'
    version: 'latest'
  }
}
var internalOSType = images[osType].OSType
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
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(artifactsLocation, 'scripts/noop.ps1${artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File scripts/noop.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(artifactsLocation, 'scripts/noop.sh${artifactsLocationSasToken}')
    scriptCall: 'sh noop.sh'
  }
}
var cseExtPublisher = csExtension[internalOSType].Publisher
var cseExtName = csExtension[internalOSType].Name
var cseExtVersion = csExtension[internalOSType].Version
var cseExtScript = csExtension[internalOSType].script
var cseExtCall = csExtension[internalOSType].scriptCall
var loadBalancingRulesLinux2049T = {
  loadBalancingRules: [for j in range(0, sapSystemCount): {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations/', fsloadBalancerName_var, 'lbFrontendFile-${j}')
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', fsloadBalancerName_var, 'lbBackendFile-${j}')
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes/', fsloadBalancerName_var, 'lbProbeFile-${j}')
      }
      protocol: 'Tcp'
      frontendPort: 2049
      backendPort: 2049
      enableFloatingIP: true
      idleTimeoutInMinutes: 30
    }
    name: 'lbProbeFile2049T-${j}'
  }]
}
var loadBalancingRulesLinux2049U = {
  loadBalancingRules: [for j in range(0, sapSystemCount): {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations/', fsloadBalancerName_var, 'lbFrontendFile-${j}')
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', fsloadBalancerName_var, 'lbBackendFile-${j}')
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes/', fsloadBalancerName_var, 'lbProbeFile-${j}')
      }
      protocol: 'Udp'
      frontendPort: 2049
      backendPort: 2049
      enableFloatingIP: true
      idleTimeoutInMinutes: 30
    }
    name: 'lbProbeFile2049U-${j}'
  }]
}
var osFamilies = {
  Windows: {
    serversize: 'Standard_DS2_v2'
    useFastNetwork: false
    diskPerSystem: 2
    servercount: 2
    serverdisksSize: 128
    needsLB: false
    loadBalancingRules: createArray()
  }
  SLES: {
    serversize: 'Standard_DS2_v2'
    useFastNetwork: false
    diskPerSystem: 1
    servercount: 2
    serverdisksSize: 128
    needsLB: true
    loadBalancingRules: concat(loadBalancingRulesLinux2049T.loadBalancingRules, loadBalancingRulesLinux2049U.loadBalancingRules)
  }
  RHEL: {
    serversize: 'Standard_DS2_v2'
    useFastNetwork: false
    diskPerSystem: 1
    servercount: 3
    serverdisksSize: 128
    needsLB: false
    loadBalancingRules: createArray()
  }
}
var fsvmCount = osFamilies[images[osType].OSFamily].servercount
var fsvmSize = osFamilies[images[osType].OSFamily].serversize
var fsdiskSize = osFamilies[images[osType].OSFamily].serverdisksSize
var fsvmDataDisks = (osFamilies[images[osType].OSFamily].diskPerSystem * sapSystemCount)
var needsLB = osFamilies[images[osType].OSFamily].needsLB
var loadBalancingRules = osFamilies[images[osType].OSFamily].loadBalancingRules
var useFastNetwork = osFamilies[images[osType].OSFamily].useFastNetwork
var frontendIPConfigurations = {
  frontendIPConfigurations: [for j in range(0, sapSystemCount): {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: 'lbFrontendFile-${j}'
  }]
}
var backendAddressPools = {
  backendAddressPools: [for j in range(0, sapSystemCount): {
    name: 'lbBackendFile-${j}'
  }]
}
var probes = {
  probes: [for j in range(0, sapSystemCount): {
    properties: {
      protocol: 'Tcp'
      port: (61000 + j)
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: 'lbProbeFile-${j}'
  }]
}
var nicBackAddressPools = {
  nicBackAddressPools: [for j in range(0, sapSystemCount): {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', fsloadBalancerName_var, 'lbBackendFile-${j}')
  }]
}
var sidlower = toLower(resourcePrefix)
var vmName_var = '${sidlower}-fs'
var vnetName_var = '${sidlower}-vnet'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var fspublicIpName_var = '${sidlower}-pip-fs'
var fsavSetName_var = '${sidlower}-avset-fs'
var nsgName_var = '${sidlower}-nsg'
var fsloadBalancerName_var = '${sidlower}-lb-fs'
var fsnicName_var = '${sidlower}-nic-fs'
var osSecurityRules = {
  Windows: [
    {
      name: 'RDP'
      properties: {
        description: 'Allow RDP Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 150
        direction: 'Inbound'
      }
    }
  ]
  Linux: [
    {
      name: 'SSH'
      properties: {
        description: 'Allow SSH Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 150
        direction: 'Inbound'
      }
    }
  ]
}
var selectedSecurityRules = osSecurityRules[internalOSType]

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-04-01' = if (empty(subnetId)) {
  name: nsgName_var
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2020-04-01' = if (empty(subnetId)) {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource fsavSetName 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: fsavSetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 20
  }
}

resource fspublicIpName 'Microsoft.Network/publicIPAddresses@2020-04-01' = [for i in range(0, fsvmCount): if (empty(subnetId)) {
  name: '${fspublicIpName_var}-${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: [
    vnetName
  ]
}]

resource fsloadBalancerName 'Microsoft.Network/loadBalancers@2020-04-01' = if (needsLB) {
  name: fsloadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: frontendIPConfigurations.frontendIPConfigurations
    backendAddressPools: backendAddressPools.backendAddressPools
    loadBalancingRules: loadBalancingRules
    probes: probes.probes
  }
  dependsOn: [
    vnetName
  ]
}

resource fsnicName 'Microsoft.Network/networkInterfaces@2020-04-01' = [for i in range(0, fsvmCount): {
  name: '${fsnicName_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${resourceId('Microsoft.Network/publicIPAddresses', '${fspublicIpName_var}-${i}')}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
          loadBalancerBackendAddressPools: (needsLB ? nicBackAddressPools.nicBackAddressPools : json('null'))
        }
      }
    ]
    enableAcceleratedNetworking: useFastNetwork
  }
  dependsOn: [
    fspublicIpName
    vnetName
    fsloadBalancerName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, fsvmCount): {
  name: '${vmName_var}-${i}'
  location: location
  properties: {
    availabilitySet: {
      id: fsavSetName.id
    }
    hardwareProfile: {
      vmSize: fsvmSize
    }
    osProfile: {
      computerName: '${vmName_var}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [for j in range(0, fsvmDataDisks): {
        lun: j
        createOption: 'Empty'
        diskSizeGB: fsdiskSize
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${fsnicName_var}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    fsnicName
    fsavSetName
  ]
}]

resource vmName_cseExtName 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, fsvmCount): {
  name: '${vmName_var}-${i}/${cseExtName}'
  location: location
  properties: {
    publisher: cseExtPublisher
    type: cseExtName
    typeHandlerVersion: cseExtVersion
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        cseExtScript
      ]
      commandToExecute: concat(cseExtCall)
    }
  }
  dependsOn: [
    vmName
  ]
}]