@description('Name of the DNS Zone to create or update.')
param dnsZoneName string

@description('Time to live value, in seconds')
param ttl int = 3600

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/dns-records-office365'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('A delimited list that defines the resources to create, acceptable values are (mail,mdm, and sfb). A combination of all or just one of the values can be used.')
param recordTypes string = [
  'mail;mdm;sfb'
]

var delimiters = [
  ','
  ';'
]
var records = split(recordTypes, delimiters)

resource dnsZoneName_resource 'Microsoft.Network/dnszones@2016-04-01' = {
  name: dnsZoneName
  location: 'global'
}

module SettingUpDNSRecods_records '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'),'/',variables('records')[copyIndex()],'.json',parameters('_artifactsLocationSasToken'))]*/ = [for item in records: {
  name: 'SettingUpDNSRecods-${item}'
  params: {
    dnsZoneName: dnsZoneName
    ttl: ttl
  }
  dependsOn: [
    dnsZoneName_resource
  ]
}]