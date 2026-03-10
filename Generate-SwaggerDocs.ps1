#!/usr/bin/env pwsh
# Generate MCP Swagger documents for all teams

$teams = 0..24
$output = "# MCP Server Swagger Documents for All Teams`n`n"
$output += "Copy and paste each swagger document into Power Platform Custom Connectors.`n`n"

foreach ($team in $teams) {
    $teamStr = $team.ToString("D2")
    $rg = "rg-fabrikam-team-$teamStr"
    
    # Get MCP app hostname
    $apps = az webapp list -g $rg --query "[?contains(name, 'mcp')].{name:name, url:defaultHostName}" -o json 2>$null | ConvertFrom-Json
    
    if ($apps -and $apps.Count -gt 0) {
        $hostname = $apps[0].url
        $guid = [guid]::NewGuid().ToString()
        
        $output += "## Team-$teamStr`n`n"
        $output += "**Host:** $hostname`n"
        $output += "**GUID:** $guid`n`n"
        $output += '```yaml' + "`n"
        $output += "swagger: '2.0'`n"
        $output += "info:`n"
        $output += "  title: MCP Server`n"
        $output += "  description: >`n"
        $output += "    This MCP Server will work with Streamable HTTP and is meant to work with`n"
        $output += "    Microsoft Copilot Studio`n"
        $output += "  version: 1.0.0`n"
        $output += "host: $hostname`n"
        $output += "basePath: /mcp`n"
        $output += "schemes:`n"
        $output += "  - https`n"
        $output += "consumes: []`n"
        $output += "produces: []`n"
        $output += "paths:`n"
        $output += "  /:`n"
        $output += "    post:`n"
        $output += "      summary: fabrikam-mcp-team-$teamStr`n"
        $output += "      x-ms-agentic-protocol: mcp-streamable-1.0`n"
        $output += "      operationId: InvokeMCP`n"
        $output += "      parameters:`n"
        $output += "        - name: X-User-GUID`n"
        $output += "          in: header`n"
        $output += "          required: true`n"
        $output += "          type: string`n"
        $output += "          default: $guid`n"
        $output += "          description: User tracking GUID for session management`n"
        $output += "      responses:`n"
        $output += "        '200':`n"
        $output += "          description: Success`n"
        $output += "definitions: {}`n"
        $output += "parameters: {}`n"
        $output += "responses: {}`n"
        $output += "securityDefinitions: {}`n"
        $output += "security: []`n"
        $output += "tags: []`n"
        $output += '```' + "`n`n"
        $output += "---`n`n"
        
        Write-Host "✓ Generated swagger for Team-$teamStr ($hostname)" -ForegroundColor Green
    }
}

# Save to file
$output | Out-File -FilePath "mcp-swagger-documents.md" -Encoding UTF8

Write-Host "`n✓ Created mcp-swagger-documents.md with all 25 team swagger documents" -ForegroundColor Cyan
Write-Host "✓ Each team has a unique GUID for the X-User-GUID header" -ForegroundColor Cyan
Write-Host "`nFile location: $(Join-Path $PWD 'mcp-swagger-documents.md')" -ForegroundColor Yellow
