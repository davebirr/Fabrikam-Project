# Quick script to mark migrations as applied and add Issue #4 columns
# This works around the EF migration conflicts

Write-Host "🔧 Quick Issue #4 Migration Fix" -ForegroundColor Green

try {
    # Use Invoke-Sqlcmd if available (from SqlServer module)
    $connectionString = "Server=fabrikam-dev-sql.database.windows.net;Database=fabrikam-dev-db;Authentication=ActiveDirectoryDefault;"
    
    # First, mark existing migrations as applied
    $markMigrationsSql = @"
-- Mark existing migrations as applied
INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
SELECT * FROM (VALUES 
    ('20250727042608_InitialCreateIdentitySchema', '9.0.7'),
    ('20250727042732_FixRoleSeedData', '9.0.7')
) AS V([MigrationId], [ProductVersion])
WHERE NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory] 
    WHERE [MigrationId] = V.[MigrationId]
);
"@

    # Add Issue #4 columns
    $addColumnsSql = @"
-- Add Issue #4 columns
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUsers') AND name = 'EntraObjectId')
    ALTER TABLE [FabUsers] ADD [EntraObjectId] nvarchar(max) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUsers') AND name = 'CompanyName')
    ALTER TABLE [FabUsers] ADD [CompanyName] nvarchar(max) NOT NULL DEFAULT N'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUsers') AND name = 'UpdatedDate')
    ALTER TABLE [FabUsers] ADD [UpdatedDate] datetime2 NOT NULL DEFAULT '1900-01-01T00:00:00.0000000';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUsers') AND name = 'DeletedDate')
    ALTER TABLE [FabUsers] ADD [DeletedDate] datetime2 NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'AssignedAt')
    ALTER TABLE [FabUserRoles] ADD [AssignedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'AssignedBy')
    ALTER TABLE [FabUserRoles] ADD [AssignedBy] nvarchar(256) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'AssignmentNotes')
    ALTER TABLE [FabUserRoles] ADD [AssignmentNotes] nvarchar(500) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'ExpiresAt')
    ALTER TABLE [FabUserRoles] ADD [ExpiresAt] datetime2 NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'IsActive')
    ALTER TABLE [FabUserRoles] ADD [IsActive] bit NOT NULL DEFAULT CAST(1 AS bit);

-- Create indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'IX_FabUserRoles_AssignedAt')
    CREATE INDEX [IX_FabUserRoles_AssignedAt] ON [FabUserRoles] ([AssignedAt]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'IX_FabUserRoles_ExpiresAt')
    CREATE INDEX [IX_FabUserRoles_ExpiresAt] ON [FabUserRoles] ([ExpiresAt]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('FabUserRoles') AND name = 'IX_FabUserRoles_IsActive')
    CREATE INDEX [IX_FabUserRoles_IsActive] ON [FabUserRoles] ([IsActive]);

-- Mark Issue #4 migration as applied
INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
SELECT '20250727051059_CompleteIssue4WithEntraID', '9.0.7'
WHERE NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory] 
    WHERE [MigrationId] = '20250727051059_CompleteIssue4WithEntraID'
);
"@

    Write-Host "📝 Executing migration fix..." -ForegroundColor Blue
    
    if (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue) {
        Write-Host "✅ Using Invoke-Sqlcmd" -ForegroundColor Green
        Invoke-Sqlcmd -ConnectionString $connectionString -Query $markMigrationsSql -TrustServerCertificate
        Invoke-Sqlcmd -ConnectionString $connectionString -Query $addColumnsSql -TrustServerCertificate
        Write-Host "✅ Migration completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Invoke-Sqlcmd not available. Please install SqlServer module:" -ForegroundColor Yellow
        Write-Host "Install-Module -Name SqlServer -Force" -ForegroundColor White
        Write-Host "Or run the SQL manually in Azure Data Studio" -ForegroundColor White
        
        # Save the SQL to a file for manual execution
        $combinedSql = $markMigrationsSql + "`n" + $addColumnsSql
        $combinedSql | Out-File -FilePath "quick-migration-fix.sql" -Encoding UTF8
        Write-Host "💾 SQL saved to quick-migration-fix.sql for manual execution" -ForegroundColor Cyan
    }
    
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Please run the SQL manually in Azure Data Studio" -ForegroundColor Yellow
}
