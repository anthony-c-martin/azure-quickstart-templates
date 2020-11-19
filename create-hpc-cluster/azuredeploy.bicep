param clusterName string {
  minLength: 3
  maxLength: 15
  metadata: {
    description: 'The HPC Pack cluster name. It must be unique in the location because it is also used as the public DNS name prefix for the cluster. For example, the public DNS name is \'&lt;clustername&gt;.westus.cloudapp.azure.com\' if the resource group location is \'West US\'. It must contain between 3 and 15 characters with lowercase letters and numbers, and must start with a letter.'
  }
}
param privateDomainName string {
  metadata: {
    description: 'The fully qualified domain name (FQDN) for the private domain forest which will be created by this template, for example \'hpc.local\'.'
  }
  default: 'hpc.local'
}
param headNodeVMSize string {
  allowed: [
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_A10'
    'Standard_A11'
    'Standard_A4_v2'
    'Standard_A8_v2'
    'Standard_A4m_v2'
    'Standard_A8m_v2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
    'Standard_D14_v2'
    'Standard_D15_v2'
    'Standard_F4'
    'Standard_F8'
    'Standard_F16'
    'Standard_G2'
    'Standard_G3'
    'Standard_G4'
    'Standard_G5'
    'Standard_H8'
    'Standard_H16'
    'Standard_H8m'
    'Standard_H16m'
    'Standard_H16r'
    'Standard_H16mr'
    'Standard_NV6'
    'Standard_NV12'
    'Standard_NV24'
    'Standard_NC6'
    'Standard_NC12'
    'Standard_NC24'
    'Standard_NC24r'
  ]
  metadata: {
    description: 'The VM size of the head node. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/en-us/pricing/details/virtual-machines before deployment.'
  }
  default: 'Standard_D4_v2'
}
param computeNodeImage string {
  allowed: [
    'ComputeNode'
    'ComputeNodeWithExcel'
  ]
  metadata: {
    description: 'The VM image of the compute nodes'
  }
  default: 'ComputeNode'
}
param computeNodeNamePrefix string {
  minLength: 1
  maxLength: 12
  metadata: {
    description: 'The name prefix of the compute nodes. It must be no more than 12 characters, begin with a letter, and contain only letters, numbers and hyphens. For example, if \'IaaSCN-\' is specified, the compute node names will be \'IaaSCN-000\', \'IaaSCN-001\', ...'
  }
  default: 'IaaSCN-'
}
param computeNodeNumber int {
  minValue: 1
  maxValue: 500
  metadata: {
    description: 'The number of the compute nodes'
  }
  default: 2
}
param computeNodeVMSize string {
  allowed: [
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_A10'
    'Standard_A11'
    'Standard_A1_v2'
    'Standard_A2_v2'
    'Standard_A4_v2'
    'Standard_A8_v2'
    'Standard_A2m_v2'
    'Standard_A4m_v2'
    'Standard_A8m_v2'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D11_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
    'Standard_D14_v2'
    'Standard_D15_v2'
    'Standard_G1'
    'Standard_G2'
    'Standard_G3'
    'Standard_G4'
    'Standard_G5'
    'Standard_F1'
    'Standard_F2'
    'Standard_F4'
    'Standard_F8'
    'Standard_F16'
    'Standard_H8'
    'Standard_H16'
    'Standard_H8m'
    'Standard_H16m'
    'Standard_H16r'
    'Standard_H16mr'
    'Standard_NV6'
    'Standard_NV12'
    'Standard_NV24'
    'Standard_NC6'
    'Standard_NC12'
    'Standard_NC24'
    'Standard_NC24r'
  ]
  metadata: {
    description: 'The VM size of the compute nodes. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/en-us/pricing/details/virtual-machines before deployment.'
  }
  default: 'Standard_D3_v2'
}
param adminUsername string {
  metadata: {
    description: 'Administrator user name for the virtual machines and the Active Directory domain.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Administrator password for the virtual machines and the Active Directory domain'
  }
  secure: true
}
param headNodePostConfigScript string {
  metadata: {
    description: 'Optional URL of a public available PowerShell script you want to run on the head node after it is configured. The script will be run as the Local System account. You can also specify arguments for the script, for example \'http://www.contoso.com/myhnpostscript.ps1 -Arg1 arg1 -Arg2 arg2\'.'
  }
  default: ''
}
param computeNodePostConfigScript string {
  metadata: {
    description: 'Optional URL of a public available PowerShell script you want to run on the compute nodes after they are configured. The script will be run as the Local System account. You can also specify arguments for the script, for example \'http://www.contoso.com/mycnpostscript.ps1 -Arg1 arg1 -Arg2 arg2\'.'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var virtualNetworkName = '${clusterName}VNet'
var publicIPAddressName = '${clusterName}-PublicIP-HN'
var computeNodeImageOsPlatform = 'Windows'
var computeNodeImages = {
  ComputeNode: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2012R2CN'
    version: 'latest'
  }
  ComputeNodeWithExcel: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2012R2CNExcel'
    version: 'latest'
  }
}
var currentComputeNodeImage = computeNodeImages[computeNodeImage]
var artifactsBaseUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/create-hpc-cluster'

module mainTemplate '<failed to parse [concat(variables(\'artifactsBaseUrl\'), \'/mainTemplate.json\')]>' = {
  name: 'mainTemplate'
  params: {
    clusterName: clusterName
    virtualNetworkName: virtualNetworkName
    privateDomainName: privateDomainName
    headNodeVMSize: headNodeVMSize
    headNodeDiskType: 'HDD'
    computeNodeImageOsPlatform: computeNodeImageOsPlatform
    computeNodeImagePublisher: currentComputeNodeImage.publisher
    computeNodeImageOffer: currentComputeNodeImage.offer
    computeNodeImageSku: currentComputeNodeImage.sku
    computeNodeNamePrefix: computeNodeNamePrefix
    computeNodeNumber: computeNodeNumber
    computeNodeDiskType: 'HDD'
    computeNodeVMSize: computeNodeVMSize
    publicIPName: publicIPAddressName
    publicIPRGName: resourceGroup().name
    publicIPNewOrExisting: 'new'
    publicIPDNSNameLabel: clusterName
    adminUsername: adminUsername
    adminPassword: adminPassword
    headNodePostConfigScript: trim(headNodePostConfigScript)
    computeNodePostConfigScript: trim(computeNodePostConfigScript)
    artifactsBaseUrl: artifactsBaseUrl
  }
}

output clusterDnsName string = reference('mainTemplate').outputs.clusterDNSName.value