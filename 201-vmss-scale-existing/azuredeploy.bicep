param existingVMSSName string {
  metadata: {
    description: 'Name of existing VM Scale Set'
  }
}
param newCapacity int {
  metadata: {
    description: 'Number of desired VM instances'
  }
}
param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_D1_v2'
}

resource existingVMSSName_res 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: existingVMSSName
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: newCapacity
  }
}