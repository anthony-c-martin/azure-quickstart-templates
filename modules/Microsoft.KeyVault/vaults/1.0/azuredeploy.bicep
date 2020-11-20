param vaultName string {
  metadata: {
    description: 'Specifies the name of the KeyVault, this value must be globally unique.'
  }
  default: 'keyvault-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
  default: resourceGroup().location
}
param enabledForDeployment bool {
  metadata: {
    description: 'Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.'
  }
  default: false
}
param enabledForDiskEncryption bool {
  metadata: {
    description: 'Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.'
  }
  default: false
}
param enabledForTemplateDeployment bool {
  metadata: {
    description: 'Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.'
  }
  default: false
}
param enablePurgeProtection bool {
  metadata: {
    description: 'Property specifying whether protection against purge is enabled for this vault.  This property does not accept false but enabled here to allow for this to be optional, if false, the property will not be set.'
  }
  default: false
}
param enableRbacAuthorization bool {
  metadata: {
    description: 'Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored.'
  }
  default: false
}
param enableSoftDelete bool {
  metadata: {
    description: 'Property to specify whether the \'soft delete\' functionality is enabled for this key vault. If it\'s not set to any value(true or false) when creating new key vault, it will be set to true by default. Once set to true, it cannot be reverted to false.'
  }
  default: true
}
param softDeleteRetentionInDays int {
  minValue: 7
  maxValue: 90
  metadata: {
    description: 'softDelete data retention days, only used if enableSoftDelete is true. It accepts >=7 and <=90.'
  }
  default: 7
}
param tenantId string {
  metadata: {
    description: 'Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.'
  }
  default: subscription().tenantId
}
param networkRuleBypassOptions string {
  allowed: [
    'None'
    'AzureServices'
  ]
  metadata: {
    description: 'Tells what traffic can bypass network rules. This can be \'AzureServices\' or \'None\'. If not specified the default is \'AzureServices\'.'
  }
  default: 'AzureServices'
}
param NetworkRuleAction string {
  allowed: [
    'Allow'
    'Deny'
  ]
  metadata: {
    description: 'The default action when no rule from ipRules and from virtualNetworkRules match. This is only used after the bypass property has been evaluated.'
  }
  default: 'Allow'
}
param ipRules array {
  metadata: {
    description: 'An array of IPv4 addresses or rangea in CIDR notation, e.g. \'124.56.78.91\' (simple IP address) or \'124.56.78.0/24\' (all addresses that start with 124.56.78).'
  }
  default: []
}
param accessPolicies array {
  metadata: {
    description: 'An complex object array that contains the complete definition of the access policy.'
  }
  default: []
}
param virtualNetworkRules array {
  metadata: {
    description: 'An array for resourceIds for the virtualNetworks allowed to access the vault.'
  }
  default: []
}
param skuName string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Specifies whether the key vault is a standard vault or a premium vault.'
  }
  default: 'Standard'
}
param tags object {
  metadata: {
    description: 'Tags to be assigned to the KeyVault.'
  }
  default: {}
}

resource vaultName_res 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    copy: [
      {
        name: 'accessPolicies'
        count: length(accessPolicies)
        input: {
          tenantId: accessPolicies[copyIndex('accessPolicies')].tenantId
          objectId: accessPolicies[copyIndex('accessPolicies')].objectId
          permissions: accessPolicies[copyIndex('accessPolicies')].permissions
        }
      }
    ]
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: (enableSoftDelete ? softDeleteRetentionInDays : json('null'))
    enableRbacAuthorization: enableRbacAuthorization
    enablePurgeProtection: (enablePurgeProtection ? enablePurgeProtection : json('null'))
    networkAcls: {
      bypass: networkRuleBypassOptions
      defaultAction: NetworkRuleAction
      copy: [
        {
          name: 'ipRules'
          count: length(ipRules)
          input: {
            value: ipRules[copyIndex('ipRules')]
          }
        }
        {
          name: 'virtualNetworkRules'
          count: length(virtualNetworkRules)
          input: {
            id: virtualNetworkRules[copyIndex('virtualNetworkRules')]
          }
        }
      ]
    }
  }
}

output vaultName_out string = vaultName
output vaultResourceGroup string = resourceGroup().name
output location_out string = location