@description('Specifies the name of the KeyVault, this vault must already exist.')
param vaultName string

@description('Specifies the name of the key to be created.')
param keyName string

@description('The attributes of a key managed by the key vault service.')
param attributes object = {}

@allowed([
  ''
  'P-256'
  'P-256K'
  'P-384'
  'P-521'
])
@description('Elliptic curve name.')
param crv string = ''

@description('JSON web key operations. Operations include: \'encrypt\', \'decrypt\', \'sign\', \'verify\', \'wrapKey\', \'unwrapKey\'')
param key_ops array = []

@description('The key size in bits. For example: 2048, 3072, or 4096 for RSA.')
param key_size int = 4096

@allowed([
  'EC'
  'EC-HSM'
  'RSA'
  'RSA-HSM'
])
@description('The type of key to create')
param kty string = 'RSA'

@description('Tags to be assigned to the Key.')
param tags object = {}

resource vaultName_keyName 'Microsoft.KeyVault/vaults/keys@2019-09-01' = {
  name: '${vaultName}/${keyName}'
  tags: tags
  properties: {
    attributes: attributes
    crv: crv
    kty: kty
    key_ops: key_ops
    key_size: key_size
  }
}

output key object = reference(vaultName_keyName.id, '2019-09-01', 'Full')