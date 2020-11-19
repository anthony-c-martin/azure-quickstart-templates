param automationAccountName string
param sku string {
  allowed: [
    'Free'
    'Basic'
  ]
  default: 'Basic'
}
param runbookName string
param credential1Name string = 'Azure_RM_Account_Credentials'
param cred1Username string = 'ash@sysgaininc.onmicrosoft.com'
param cred1Password string = 'Sysgain#@'
param jobIdSignup string {
  metadata: {
    description: 'Generate a Job ID (GUID) from https://www.guidgenerator.com/ '
  }
}
param location string {
  allowed: [
    'Japan East'
    'North Europe'
    'South Central US'
    'West Europe'
    'Southeast Asia'
    'East US 2'
  ]
  metadata: {
    description: 'Automation Service Location'
  }
  default: 'East US 2'
}
param runbookUrl string = 'https://raw.githubusercontent.com/sysgain/informatica-p2p/master/runbooks/info-restapi-signup.ps1 '
param tag object {
  metadata: {
    description: 'Tag Values'
  }
  default: {
    key1: 'key'
    value1: 'value'
  }
}
param ip string
param sysgain_ms_email string
param sysgain_ms_password string
param user_email string
param informatica_user_name string {
  metadata: {
    description: 'The same email id used for user_email'
  }
}
param informatica_user_password string
param user_firstname string
param user_lastname string
param user_title string
param user_phone string
param org_name string
param org_address string
param org_city string
param org_state string
param org_zipcode string
param org_country string
param org_employees string {
  allowed: [
    '0_10'
    '11_25'
    '26_50'
    '51_100'
    '101_500'
    '501_1000'
    '1001_5000'
    '5001_'
  ]
  default: '5001_'
}
param client_id string
param informaticaTags object
param quickstartTags object

resource automationAccountName_res 'Microsoft.Automation/automationAccounts@2015-01-01-preview' = {
  name: automationAccountName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    sku: {
      name: sku
    }
  }
}

resource automationAccountName_runbookName 'Microsoft.Automation/automationAccounts/runbooks@2015-01-01-preview' = {
  name: '${automationAccountName}/${runbookName}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbookType: 'Script'
    logProgress: false
    logVerbose: false
    description: null
    publishContentLink: {
      uri: runbookUrl
      version: '1.0.0.0'
    }
  }
}

resource automationAccountName_credential1Name 'Microsoft.Automation/automationAccounts/credentials@2015-01-01-preview' = {
  name: '${automationAccountName}/${credential1Name}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    userName: cred1Username
    password: cred1Password
  }
}

resource automationAccountName_jobIdSignup 'Microsoft.Automation/automationAccounts/jobs@2015-10-31' = {
  name: '${automationAccountName}/${jobIdSignup}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbook: {
      name: runbookName
    }
    parameters: {
      ip: ip
      sysgain_ms_email: sysgain_ms_email
      sysgain_ms_password: sysgain_ms_password
      informatica_user_name: informatica_user_name
      user_email: user_email
      informatica_user_password: informatica_user_password
      user_firstname: user_firstname
      user_lastname: user_lastname
      user_title: user_title
      user_phone: user_phone
      org_name: org_name
      org_address: org_address
      org_city: org_city
      org_state: org_state
      org_zipcode: org_zipcode
      org_country: org_country
      org_employees: org_employees
      client_id: client_id
    }
  }
}