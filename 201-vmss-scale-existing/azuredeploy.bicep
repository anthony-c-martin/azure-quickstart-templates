@description('Name of existing VM Scale Set')
param existingVMSSName string

@description('Number of desired VM instances')
param newCapacity int

@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_D1_v2'

resource existingVMSSName_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: existingVMSSName
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: newCapacity
  }
}