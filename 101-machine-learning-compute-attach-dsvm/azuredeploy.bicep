param computeName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Compute.'
  }
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}
param vmName string {
  metadata: {
    description: 'The name of the virtual machine.'
  }
}
param username string {
  metadata: {
    description: 'The username needed to access the virtual machine.'
  }
  secure: true
}
param sshPort int {
  metadata: {
    description: 'The exposed port for the resource. Defaults to 22.'
  }
  default: 22
}
param password string {
  metadata: {
    description: 'The password needed to access the virtual machine.'
  }
  secure: true
}
param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning Workspace which will contain this compute.'
  }
}

resource workspaceName_computeName 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/${computeName}'
  location: location
  properties: {
    computeType: 'VirtualMachine'
    resourceId: resourceId('Microsoft.Compute/virtualMachines', vmName)
    properties: {
      sshPort: sshPort
      administratorAccount: {
        username: username
        password: password
      }
    }
  }
}