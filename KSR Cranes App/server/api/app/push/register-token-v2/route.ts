import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request: NextRequest) {
  try {
    console.log('[Push Token Registration V2] Starting token registration...');
    
    // Get authorization header
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json(
        { success: false, error: 'Authentication required' },
        { status: 401 }
      );
    }

    const body = await request.json();
    console.log('[Push Token Registration V2] Request body:', JSON.stringify(body));
    
    const { employee_id, token, device_type, app_version, os_version } = body;
    
    // Validate required fields
    if (!employee_id || !token || !device_type) {
      console.error('[Push Token Registration V2] Missing required fields');
      return NextResponse.json(
        { 
          success: false, 
          error: 'Missing required fields: employee_id, token, device_type' 
        },
        { status: 400 }
      );
    }

    // Convert employee_id to number
    const employeeIdNum = parseInt(String(employee_id));
    if (isNaN(employeeIdNum)) {
      return NextResponse.json(
        { success: false, error: 'Invalid employee_id' },
        { status: 400 }
      );
    }
    
    try {
      // First, check if this exact combination of employee_id + token already exists
      const existingEmployeeToken = await prisma.pushTokens.findFirst({
        where: {
          employee_id: employeeIdNum,
          token: token
        }
      });

      let result;
      
      if (existingEmployeeToken) {
        console.log(`[Push Token Registration V2] Updating existing token for employee ${employeeIdNum}:`, existingEmployeeToken.token_id);
        
        // Update existing employee-token combination
        result = await prisma.pushTokens.update({
          where: { 
            token_id: existingEmployeeToken.token_id 
          },
          data: {
            device_type: device_type as any,
            app_version: app_version || null,
            os_version: os_version || null,
            last_used_at: new Date(),
            is_active: true,
            updated_at: new Date()
          }
        });
      } else {
        // Check if this token exists for ANY employee (including current one)
        const existingTokenRecord = await prisma.pushTokens.findFirst({
          where: {
            token: token
          }
        });
        
        if (existingTokenRecord) {
          console.log(`[Push Token Registration V2] Token exists for employee ${existingTokenRecord.employee_id}, updating for employee ${employeeIdNum}`);
          
          // Update the existing token record to new employee
          result = await prisma.pushTokens.update({
            where: { 
              token_id: existingTokenRecord.token_id 
            },
            data: {
              employee_id: employeeIdNum,
              device_type: device_type as any,
              app_version: app_version || null,
              os_version: os_version || null,
              last_used_at: new Date(),
              is_active: true,
              updated_at: new Date()
            }
          });
        } else {
          console.log(`[Push Token Registration V2] Creating new token entry for employee ${employeeIdNum}`);
          
          // Deactivate other tokens for this employee on same device type
          await prisma.pushTokens.updateMany({
            where: {
              employee_id: employeeIdNum,
              device_type: device_type as any,
              is_active: true
            },
            data: {
              is_active: false,
              updated_at: new Date()
            }
          });
          
          // Create new token entry for this employee
          result = await prisma.pushTokens.create({
            data: {
              employee_id: employeeIdNum,
              token: token,
              device_type: device_type as any,
              app_version: app_version || null,
              os_version: os_version || null,
              created_at: new Date(),
              updated_at: new Date(),
              last_used_at: new Date(),
              is_active: true
            }
          });
        }
      }
      
      console.log('[Push Token Registration V2] Success:', result.token_id);
      
      return NextResponse.json({
        success: true,
        message: 'Push token registered successfully',
        token_id: result.token_id.toString()
      });
      
    } catch (dbError: any) {
      console.error('[Push Token Registration V2] Database error:', dbError);
      return NextResponse.json(
        { 
          success: false, 
          error: 'Database error',
          details: dbError.message 
        },
        { status: 500 }
      );
    }
    
  } catch (error: any) {
    console.error('[Push Token Registration V2] Unexpected error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Internal server error',
        details: error.message 
      },
      { status: 500 }
    );
  }
}