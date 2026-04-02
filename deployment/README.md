# Fabrikam API Azure Deployment

This folder contains the Azure deployment templates and scripts for the Fabrikam API with support for three authentication modes:

- **Disabled**: GUID tracking only, no authentication barriers
- **BearerToken**: JWT token-based authentication  
- **EntraExternalId**: OAuth 2.0 with Microsoft Entra External ID

## Quick Start

### Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription** - With appropriate permissions to create resources
3. **PowerShell** - For deployment scripts

### Login to Azure

```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Simple Deployment (Disabled Mode)

For quick demos and testing without authentication:

```powershell
.\deployment\Deploy-FabrikamApi.ps1 -AuthenticationMode Disabled -EnvironmentName dev
```

### JWT Token Authentication Deployment

For API key-based authentication:

```powershell
.\deployment\Deploy-FabrikamApi.ps1 -AuthenticationMode BearerToken -EnvironmentName prod
```

### Entra External ID OAuth Deployment

For enterprise OAuth 2.0 authentication:

```powershell
.\deployment\Deploy-FabrikamApi.ps1 `
    -AuthenticationMode EntraExternalId `
    -EnvironmentName prod `
    -EntraExternalIdTenant "yourcompany.onmicrosoft.com" `
    -EntraExternalIdClientId "12345678-1234-1234-1234-123456789012"
```

The script will prompt for the client secret securely.

## Authentication Modes

### 1. Disabled Mode

- **Use Case**: Demos, testing, development
- **Security**: GUID-based user tracking only
- **Resources**: Basic App Service, Key Vault, monitoring
- **Configuration**: No additional setup required

### 2. BearerToken Mode  

- **Use Case**: Production APIs with custom authentication
- **Security**: JWT tokens with HMAC SHA-256 signing
- **Resources**: App Service + JWT signing key in Key Vault
- **Configuration**: JWT settings automatically configured

### 3. EntraExternalId Mode

- **Use Case**: Enterprise integration with Microsoft identity
- **Security**: OAuth 2.0 with Microsoft Entra External ID
- **Resources**: App Service + B2C configuration + OAuth endpoints
- **Configuration**: Requires Entra External ID tenant setup

## Entra External ID Setup

### Prerequisites

1. **Entra External ID Tenant**: Create a B2C or External ID tenant
2. **App Registration**: Register your application in the tenant
3. **Client Secret**: Generate a client secret for the app

### Step-by-Step Setup

1. **Create Entra External ID Tenant**
   - Go to [Azure Portal](https://portal.azure.com)
   - Create a new Entra External ID tenant
   - Note the tenant domain (e.g., `contoso.onmicrosoft.com`)

2. **Register Application**
   - In your Entra tenant, go to App Registrations
   - Create a new registration
   - Note the Application (client) ID
   - Generate a client secret

3. **Configure Redirect URIs**
   - After deployment, add these redirect URIs to your app registration:
   - `https://your-app-name.azurewebsites.net/signin-oidc`
   - `https://your-app-name.azurewebsites.net/auth/callback`

4. **Deploy with Parameters**
   ```powershell
   .\deployment\Deploy-FabrikamApi.ps1 `
       -AuthenticationMode EntraExternalId `
       -EnvironmentName prod `
       -EntraExternalIdTenant "contoso.onmicrosoft.com" `
       -EntraExternalIdClientId "your-client-id"
   ```

## Architecture

### Resource Structure

```
Subscription
└── Resource Group (rg-fabrikam-{environment})
    ├── App Service Plan (plan-{unique-id})
    ├── App Service (app-{unique-id}) 
    ├── Key Vault (kv-{unique-id})
    ├── Application Insights (appi-{unique-id})
    ├── Log Analytics Workspace (log-{unique-id})
    └── Managed Identity (id-{unique-id})
```

### Key Vault Secrets by Mode

#### Disabled Mode
- `guid-tracking-salt`: Salt for GUID generation

#### BearerToken Mode  
- `guid-tracking-salt`: Salt for GUID generation
- `jwt-secret-key`: HMAC signing key for JWT tokens

#### EntraExternalId Mode
- `guid-tracking-salt`: Salt for GUID generation
- `entra-client-id`: OAuth application client ID
- `entra-client-secret`: OAuth client secret
- `entra-tenant-id`: Entra tenant domain
- `entra-authority-url`: OAuth authority endpoint
- `entra-well-known-endpoint`: OIDC configuration endpoint
- `entra-jwks-uri`: Token validation keys endpoint

## Deployment Scripts

### Deploy-FabrikamApi.ps1

Main deployment script with the following parameters:

- **Required Parameters**:
  - `-AuthenticationMode`: Disabled, BearerToken, or EntraExternalId
  - `-EnvironmentName`: Environment identifier (dev, prod, staging)

- **Optional Parameters**:
  - `-Location`: Azure region (default: East US)
  - `-SubscriptionId`: Azure subscription ID
  - `-ResourceGroupName`: Custom resource group name
  - `-AppServiceSku`: App Service pricing tier (default: B1)

- **EntraExternalId Parameters**:
  - `-EntraExternalIdTenant`: Tenant domain
  - `-EntraExternalIdClientId`: Application client ID
  - `-EntraExternalIdClientSecret`: Client secret (SecureString)

- **Options**:
  - `-WhatIf`: Show what would be deployed without actually deploying
  - `-Verbose`: Enable verbose output

## Configuration Files

### azure.yaml

Azure Developer CLI configuration for streamlined deployment:

```yaml
name: fabrikam-api-demo
infra:
  provider: bicep
  path: deployment/bicep
services:
  fabrikamapi:
    project: ./FabrikamApi/src
    host: appservice
    language: dotnet
```

### Parameters Files

- `parameters.dev.json`: Development environment defaults
- `parameters.entra.json`: EntraExternalId production template

## Bicep Templates

### main.bicep

Main template that orchestrates resource deployment based on authentication mode.

### resources.bicep  

Core Azure resources with authentication-aware configuration:
- App Service with mode-specific app settings
- Key Vault with role-based access
- Monitoring and diagnostics
- Managed identity for secure resource access

### entra-resources.bicep

EntraExternalId-specific resources:
- OAuth 2.0 endpoint configuration
- B2C tenant settings
- OIDC well-known endpoints

## Monitoring and Diagnostics

All deployments include:

- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Diagnostic Settings**: App Service logs and metrics
- **Health Checks**: `/health` endpoint monitoring

## Security Features

### All Modes
- HTTPS only
- TLS 1.2 minimum
- Managed identity for Azure resource access
- Key Vault for secrets management
- RBAC for resource permissions

### BearerToken Mode
- JWT token validation
- HMAC SHA-256 signing
- Configurable token expiration
- Audience and issuer validation

### EntraExternalId Mode
- OAuth 2.0 token validation
- OIDC discovery
- Automatic token refresh
- Claims mapping to application roles

## Troubleshooting

### Common Issues

1. **Deployment Permission Errors**
   - Ensure you have Contributor role on the subscription
   - Verify Azure CLI is logged in: `az account show`

2. **Key Vault Access Issues**
   - The deployment script automatically assigns Key Vault permissions
   - If manual setup is needed, assign "Key Vault Secrets Officer" role

3. **EntraExternalId Authentication Failures**
   - Verify redirect URIs are configured in app registration
   - Check client secret hasn't expired
   - Ensure tenant domain is correct

4. **App Service Configuration Issues**
   - Check Application Insights connection string
   - Verify managed identity has Key Vault access
   - Review app settings in Azure Portal

### Logs and Monitoring

- **Application Logs**: Available in Application Insights
- **Deployment Logs**: Check Azure Portal deployment history
- **App Service Logs**: Available in Log Analytics workspace

## Cost Optimization

### Free Tier (F1 SKU) - Recommended Default
- Free for limited usage
- No dedicated worker quota required — works on all subscriptions
- Ideal for training, demos, and initial testing
- Limitations: no AlwaysOn, no custom SSL, 60 min CPU/day

### Development (B1 SKU)
- Estimated cost: ~$13-15/month
- Requires dedicated App Service Basic worker quota
- Suitable for extended demos and development

### Production (P1v3 SKU)  
- Estimated cost: ~$75-85/month
- Includes auto-scaling and high availability
- Requires dedicated App Service Premium worker quota

> **⚠️ Quota Note**: B1+ SKUs require dedicated App Service worker quotas. New subscriptions often start with zero quota. If deployment fails with `SubscriptionIsOverQuotaForSku`, use F1 or request a quota increase via Azure Portal > Quotas > Microsoft.Web.

## Next Steps

After successful deployment:

1. **Test the API**: Access the Swagger UI at `https://your-app.azurewebsites.net/swagger`
2. **Configure Monitoring**: Set up alerts in Application Insights
3. **Set Up CI/CD**: Configure GitHub Actions for automated deployment
4. **Security Review**: Review CORS settings and authentication configuration
5. **Performance Testing**: Use Azure Load Testing for performance validation

## Support

For issues and questions:
- Review the deployment logs in Azure Portal
- Check Application Insights for runtime errors
- Consult the main project README for API-specific documentation
