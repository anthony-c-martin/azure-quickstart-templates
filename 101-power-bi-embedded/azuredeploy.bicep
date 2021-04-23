@description('The capacity name, which is displayed in the Azure portal and the Power BI admin portal')
param name string

@description('The location where Power BI is hosted for your tenant')
param location string = resourceGroup().location

@allowed([
  'A1'
  'A2'
  'A3'
  'A4'
  'A5'
  'A6'
])
@description('The pricing tier, which determines the v-core count and memory size for the capacity')
param sku string

@description('A user within your Power BI tenant, who will serve as an admin for this capacity')
param admin string

resource name_resource 'Microsoft.PowerBIDedicated/capacities@2017-10-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    administration: {
      members: [
        admin
      ]
    }
  }
}