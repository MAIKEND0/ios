// src/app/api/app/chef/zenegy/test-connection/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "../../../../../../lib/prisma";

function getErrorMessage(err: any): string {
  return (err && typeof err === "object" && err.message) || "Internal Server Error";
}

/**
 * GET /api/app/chef/zenegy/test-connection
 * Testuje połączenie z Zenegy API (mock)
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    console.log("🧪 [ZENEGY TEST] Testing connection to Zenegy API");

    // Get current Zenegy configuration
    const zenegyConfig = await prisma.zenegyConfig.findFirst({
      where: { id: 1 },
      select: {
        api_key: true,
        api_secret: true,
        tenant_id: true,
        company_id: true,
        environment: true,
        api_base_url: true,
        api_version: true,
        is_active: true,
        last_connection_test: true,
        last_connection_status: true
      }
    });

    if (!zenegyConfig) {
      return NextResponse.json({
        success: false,
        error: "Zenegy configuration not found. Please configure the integration first.",
        status: "not_configured"
      }, { status: 404 });
    }

    if (!zenegyConfig.is_active) {
      return NextResponse.json({
        success: false,
        error: "Zenegy integration is disabled",
        status: "disabled",
        config: zenegyConfig
      }, { status: 400 });
    }

    // Validate configuration
    const missingFields = [];
    if (!zenegyConfig.api_key) missingFields.push('api_key');
    if (!zenegyConfig.api_secret) missingFields.push('api_secret');
    if (!zenegyConfig.tenant_id) missingFields.push('tenant_id');
    if (!zenegyConfig.company_id) missingFields.push('company_id');

    if (missingFields.length > 0) {
      return NextResponse.json({
        success: false,
        error: `Missing required configuration fields: ${missingFields.join(', ')}`,
        status: "incomplete_config",
        missing_fields: missingFields,
        config: zenegyConfig
      }, { status: 400 });
    }

    // Test connection to mock API
    const testStartTime = Date.now();
    let connectionTestResult;
    
    try {
      // Create a test payload to send to mock API
      const testPayload = {
        batch_id: 0,
        batch_number: `TEST-${Date.now()}`,
        period_start: new Date().toISOString().split('T')[0],
        period_end: new Date().toISOString().split('T')[0],
        total_employees: 0,
        total_hours: 0,
        total_amount: 0,
        employees: [],
        company_id: zenegyConfig.company_id,
        tenant_id: zenegyConfig.tenant_id,
        currency: "DKK",
        created_at: new Date().toISOString(),
        test_connection: true
      };

      console.log("🧪 [ZENEGY TEST] Sending test payload to mock API");

      const response = await fetch(`${process.env.NEXTAUTH_URL || 'http://localhost:3000'}/api/test/zenegy-mock`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${zenegyConfig.api_key}`,
          'X-Zenegy-Environment': zenegyConfig.environment || 'sandbox',
          'X-Test-Connection': 'true'
        },
        body: JSON.stringify(testPayload)
      });

      const responseTime = Date.now() - testStartTime;
      const responseData = await response.json();

      connectionTestResult = {
        success: response.ok,
        status_code: response.status,
        response_time_ms: responseTime,
        response_data: responseData,
        headers: Object.fromEntries(response.headers.entries())
      };

      console.log("🧪 [ZENEGY TEST] Connection test result:", connectionTestResult);

    } catch (connectionError: any) {
      console.error("🧪 [ZENEGY TEST] Connection failed:", connectionError);
      
      connectionTestResult = {
        success: false,
        error: connectionError.message,
        response_time_ms: Date.now() - testStartTime
      };
    }

    // Update configuration with test results
    const newStatus = connectionTestResult.success ? 'success' : 'failed';
    
    await prisma.zenegyConfig.update({
      where: { id: 1 },
      data: {
        last_connection_test: new Date(),
        last_connection_status: newStatus
      }
    });

    // Check employee mappings
    const mappingStats = await prisma.zenegyEmployeeMapping.aggregate({
      _count: {
        id: true
      },
      where: {
        sync_enabled: true
      }
    });

    const totalActiveEmployees = await prisma.employees.count({
      where: {
        is_activated: true,
        role: { in: ['arbejder', 'byggeleder'] }
      }
    });

    const readyWorkEntries = await prisma.workEntries.count({
      where: {
        confirmation_status: 'confirmed',
        sent_to_payroll: false,
        isActive: true,
        start_time: { not: null },
        end_time: { not: null }
      }
    });

    // Prepare response
    const result = {
      success: connectionTestResult.success,
      status: connectionTestResult.success ? "connected" : "connection_failed",
      message: connectionTestResult.success 
        ? "Successfully connected to Zenegy API (mock)" 
        : "Failed to connect to Zenegy API",
      connection_test: connectionTestResult,
      configuration: {
        environment: zenegyConfig.environment,
        api_base_url: zenegyConfig.api_base_url,
        api_version: zenegyConfig.api_version,
        company_id: zenegyConfig.company_id,
        tenant_id: zenegyConfig.tenant_id,
        is_active: zenegyConfig.is_active,
        has_api_credentials: !!(zenegyConfig.api_key && zenegyConfig.api_secret)
      },
      integration_status: {
        total_active_employees: totalActiveEmployees,
        employees_with_zenegy_mapping: mappingStats._count.id || 0,
        mapping_coverage_percentage: totalActiveEmployees > 0 
          ? Math.round((mappingStats._count.id || 0) / totalActiveEmployees * 100) 
          : 0,
        ready_work_entries: readyWorkEntries,
        is_ready_for_sync: (mappingStats._count.id || 0) > 0 && readyWorkEntries > 0
      },
      recommendations: generateRecommendations(
        connectionTestResult.success,
        mappingStats._count.id || 0,
        totalActiveEmployees,
        readyWorkEntries
      ),
      tested_at: new Date().toISOString()
    };

    return NextResponse.json(result, { 
      status: connectionTestResult.success ? 200 : 500 
    });

  } catch (err: any) {
    console.error("❌ Error in zenegy test-connection:", err);
    
    // Try to update the config with failed status
    try {
      await prisma.zenegyConfig.update({
        where: { id: 1 },
        data: {
          last_connection_test: new Date(),
          last_connection_status: 'failed'
        }
      });
    } catch (updateError) {
      console.error("Failed to update config after error:", updateError);
    }

    return NextResponse.json({
      success: false,
      status: "error",
      error: getErrorMessage(err),
      tested_at: new Date().toISOString()
    }, { status: 500 });
  }
}

/**
 * POST /api/app/chef/zenegy/test-connection
 * Aktualizuje konfigurację Zenegy i testuje połączenie
 */
export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const {
      api_key,
      api_secret,
      tenant_id,
      company_id,
      environment = 'sandbox',
      api_base_url = 'https://api.zenegy.com',
      api_version = 'v1',
      is_active = true
    } = body;

    console.log("🔧 [ZENEGY CONFIG] Updating configuration");

    // Validate required fields
    if (!api_key || !api_secret || !tenant_id || !company_id) {
      return NextResponse.json({
        success: false,
        error: "Missing required fields: api_key, api_secret, tenant_id, company_id"
      }, { status: 400 });
    }

    // Update configuration
    const updatedConfig = await prisma.zenegyConfig.upsert({
      where: { id: 1 },
      create: {
        id: 1,
        api_key,
        api_secret,
        tenant_id,
        company_id,
        environment,
        api_base_url,
        api_version,
        is_active,
        updated_by: 1 // TODO: Get from auth
      },
      update: {
        api_key,
        api_secret,
        tenant_id,
        company_id,
        environment,
        api_base_url,
        api_version,
        is_active,
        updated_by: 1, // TODO: Get from auth
        updated_at: new Date()
      }
    });

    console.log("✅ [ZENEGY CONFIG] Configuration updated successfully");

    // Test connection with new configuration
    const testResponse = await fetch(`${process.env.NEXTAUTH_URL || 'http://localhost:3000'}/api/app/chef/zenegy/test-connection`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const testResult = await testResponse.json();

    return NextResponse.json({
      success: true,
      message: "Configuration updated and connection tested",
      configuration_updated: true,
      connection_test: testResult,
      config_id: updatedConfig.id
    }, { status: 200 });

  } catch (err: any) {
    console.error("❌ Error updating Zenegy configuration:", err);
    return NextResponse.json({
      success: false,
      error: getErrorMessage(err)
    }, { status: 500 });
  }
}

function generateRecommendations(
  connectionSuccess: boolean,
  mappedEmployees: number,
  totalEmployees: number,
  readyEntries: number
): string[] {
  const recommendations = [];

  if (!connectionSuccess) {
    recommendations.push("🔧 Check your API credentials and network connectivity");
    recommendations.push("📋 Verify that the Zenegy API endpoint is accessible");
  }

  if (mappedEmployees === 0) {
    recommendations.push("👥 Set up employee mappings to Zenegy employee IDs");
    recommendations.push("📖 Use the employee management section to configure Zenegy mappings");
  } else if (mappedEmployees < totalEmployees) {
    const unmapped = totalEmployees - mappedEmployees;
    recommendations.push(`👥 ${unmapped} employees still need Zenegy ID mapping`);
  }

  if (readyEntries === 0) {
    recommendations.push("⏰ No confirmed work entries ready for payroll sync");
    recommendations.push("✅ Make sure supervisors confirm submitted hours");
  }

  if (connectionSuccess && mappedEmployees > 0 && readyEntries > 0) {
    recommendations.push("🚀 System is ready for payroll synchronization!");
    recommendations.push("📤 You can now send confirmed hours to Zenegy");
  }

  return recommendations;
}