@description('An array of template files to deploy.')
param templateSpecFiles array

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

module templateSpec_templateSpecFiles_json '?' /*TODO: replace with correct path to [concat(parameters('templateSpecFiles')[copyIndex()], parameters('_artifactsLocationSasToken'))]*/ = [for item in templateSpecFiles: {
  name: 'templateSpec-${replace(last(split(item, '/')), '.json', '')}'
  params: {
    location: location
  }
}]