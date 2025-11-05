#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for Support Tickets API and MCP tools

.DESCRIPTION
    Tests the new support ticket endpoints:
    - GET /api/SupportTickets (list)
    - GET /api/SupportTickets/{id} (details)
    - POST /api/SupportTickets (create)
    - PATCH /api/SupportTickets/{id}/status (update)
    - POST /api/SupportTickets/{id}/notes (add note)
#>

param(
    [string]$ApiBaseUrl = "https://localhost:7297"
)

Write-Host "🎫 Testing Support Tickets API" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get all support tickets
Write-Host "📋 Test 1: GET /api/SupportTickets (list active tickets)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets" -SkipCertificateCheck
    Write-Host "✅ SUCCESS: Found $($response.Count) tickets" -ForegroundColor Green
    if ($response.Count -gt 0) {
        $firstTicket = $response[0]
        Write-Host "   Sample: Ticket #$($firstTicket.id) - $($firstTicket.ticketNumber) - $($firstTicket.subject)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Get ticket details
Write-Host "🔍 Test 2: GET /api/SupportTickets/1 (ticket details)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets/1" -SkipCertificateCheck
    Write-Host "✅ SUCCESS: Got details for ticket #$($response.id)" -ForegroundColor Green
    Write-Host "   Ticket: $($response.ticketNumber)" -ForegroundColor Gray
    Write-Host "   Subject: $($response.subject)" -ForegroundColor Gray
    Write-Host "   Status: $($response.status)" -ForegroundColor Gray
    Write-Host "   Priority: $($response.priority)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Create a new support ticket
Write-Host "➕ Test 3: POST /api/SupportTickets (create new ticket)" -ForegroundColor Yellow
try {
    $newTicket = @{
        customerId = 1
        orderId = 1
        subject = "Test Ticket - Installation Question"
        description = "Customer wants to know about foundation requirements for The Pioneer model"
        priority = "Medium"
        category = "Installation"
    }
    
    $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($newTicket | ConvertTo-Json) `
        -SkipCertificateCheck
    
    Write-Host "✅ SUCCESS: Created ticket $($response.ticketNumber)" -ForegroundColor Green
    Write-Host "   ID: $($response.id)" -ForegroundColor Gray
    Write-Host "   Subject: $($response.subject)" -ForegroundColor Gray
    Write-Host "   Status: $($response.status)" -ForegroundColor Gray
    Write-Host "   Priority: $($response.priority)" -ForegroundColor Gray
    
    # Save ticket ID for next tests
    $script:newTicketId = $response.id
}
catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 4: Update ticket status
if ($script:newTicketId) {
    Write-Host "🔄 Test 4: PATCH /api/SupportTickets/$($script:newTicketId)/status (update ticket)" -ForegroundColor Yellow
    try {
        $update = @{
            status = "InProgress"
            priority = "High"
            assignedTo = "Sarah Johnson"
        }
        
        $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets/$($script:newTicketId)/status" `
            -Method Patch `
            -ContentType "application/json" `
            -Body ($update | ConvertTo-Json) `
            -SkipCertificateCheck
        
        Write-Host "✅ SUCCESS: Updated ticket #$($script:newTicketId)" -ForegroundColor Green
        Write-Host "   Status: $($response.status)" -ForegroundColor Gray
        Write-Host "   Priority: $($response.priority)" -ForegroundColor Gray
        Write-Host "   Assigned To: $($response.assignedTo)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Test 5: Add a note to the ticket
if ($script:newTicketId) {
    Write-Host "📝 Test 5: POST /api/SupportTickets/$($script:newTicketId)/notes (add note)" -ForegroundColor Yellow
    try {
        $note = @{
            note = "Contacted customer to discuss foundation options. Recommended concrete slab."
            createdBy = "Sarah Johnson"
            isInternal = $false
        }
        
        $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets/$($script:newTicketId)/notes" `
            -Method Post `
            -ContentType "application/json" `
            -Body ($note | ConvertTo-Json) `
            -SkipCertificateCheck
        
        Write-Host "✅ SUCCESS: Added note to ticket #$($script:newTicketId)" -ForegroundColor Green
        Write-Host "   Note ID: $($response.id)" -ForegroundColor Gray
        Write-Host "   Created By: $($response.createdBy)" -ForegroundColor Gray
        Write-Host "   Internal: $($response.isInternal)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Test 6: Get analytics
Write-Host "📊 Test 6: GET /api/SupportTickets/analytics" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/supporttickets/analytics" -SkipCertificateCheck
    Write-Host "✅ SUCCESS: Got analytics data" -ForegroundColor Green
    Write-Host "   Total Tickets: $($response.summary.totalTickets)" -ForegroundColor Gray
    Write-Host "   Open: $($response.summary.openTickets)" -ForegroundColor Gray
    Write-Host "   In Progress: $($response.summary.inProgressTickets)" -ForegroundColor Gray
    Write-Host "   Resolved: $($response.summary.resolvedTickets)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Support Tickets API Testing Complete!" -ForegroundColor Green
