param bcMemberName string {
  metadata: {
    description: 'Azure Blockchain Service member name. The blockchain member name must be unique and can only contain lowercase letters and numbers. The first character must be a letter. The value must be between 2 and 20 characters long.'
  }
}
param consortiumName string {
  metadata: {
    description: 'Consortium name. The new consortium name must be unique.'
  }
}
param memberPassword string {
  metadata: {
    description: 'The password for the member\'s default transaction node. Use the password for basic authentication when connecting to blockchain member\'s default transaction node public endpoint. The password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character that is not \'#\', \'`\', \'*\', \'"\', \'\'\', \'-\', \'%\',\' \' or \';\'.'
  }
  secure: true
}
param consortiumManagementAccountPassword string {
  metadata: {
    description: 'The consortium management account password is used to encrypt the private key for the Ethereum account that is created for your member. You use the member account and member account password for consortium management. The password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character that is not \'#\', \'`\', \'*\', \'"\', \'\'\', \'-\', \'%\',\' \' or \';\'.'
  }
  secure: true
}
param skuTier string {
  metadata: {
    description: 'Use Basic or Standard. Use the Basic tier for development, testing, and proof of concepts. Use the Standard tier for production grade deployments. You should also use the Standard tier if you are using Blockchain Data Manager or sending a high volume of private transactions. Changing the pricing tier between basic and standard after member creation is not supported.'
  }
  default: 'Basic'
}
param skuName string {
  metadata: {
    description: 'Use S0 for Standard and B0 for Basic.'
  }
  default: 'B0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource bcMemberName_res 'Microsoft.Blockchain/blockchainMembers@2018-06-01-preview' = {
  name: bcMemberName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  tags: {
    consortium: 'Consortium'
  }
  properties: {
    protocol: 'Quorum'
    consensus: 'Default'
    password: memberPassword
    validatorNodesSku: {
      capacity: 1
    }
    consortium: consortiumName
    consortiumManagementAccountPassword: consortiumManagementAccountPassword
    firewallRules: [
      {
        ruleName: 'AllowAll'
        startIpAddress: '0.0.0.0'
        endIpAddress: '255.255.255.255'
      }
    ]
  }
}