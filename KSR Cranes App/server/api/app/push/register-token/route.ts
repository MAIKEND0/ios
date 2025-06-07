import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request: NextRequest) {
  try {
    console.log('[Push Token Registration] Starting token registration...');
    
    const body = await request.json();
    console.log('[Push Token Registration] Request body:', body);
    
    const { employee_id, token, device_type, app_version, os_version } = body;
    
    // Validate required fields
    if (!employee_id || !token || !device_type) {
      console.error('[Push Token Registration] Missing required fields');
      return NextResponse.json(
        { 
          success: false, 
          error: 'Missing required fields: employee_id, token, device_type' 
        },
        { status: 400 }
      );
    }
    
    // Validate employee exists
    const employee = await prisma.employees.findUnique({
      where: { employee_id: parseInt(employee_id) }
    });
    
    if (!employee) {
      console.error('[Push Token Registration] Employee not found:', employee_id);
      return NextResponse.json(
        { 
          success: false, 
          error: 'Employee not found' 
        },
        { status: 404 }
      );
    }
    
    // Check if token already exists for this employee
    const existingToken = await prisma.pushTokens.findFirst({
      where: {
        employee_id: parseInt(employee_id),
        token: token
      }
    });
    
    let pushToken;
    
    if (existingToken) {
      // Update existing token
      pushToken = await prisma.pushTokens.update({
        where: { token_id: existingToken.token_id },
        data: {
          app_version,
          os_version,
          last_used_at: new Date(),
          is_active: true,
          updated_at: new Date()
        }
      });
      
      console.log('[Push Token Registration] Updated existing token:', pushToken.token_id);
    } else {
      // Deactivate old tokens for this employee and device type
      await prisma.pushTokens.updateMany({
        where: {
          employee_id: parseInt(employee_id),
          device_type: device_type as any,
          is_active: true
        },
        data: {
          is_active: false,
          updated_at: new Date()
        }
      });
      
      // Create new token
      pushToken = await prisma.pushTokens.create({
        data: {
          employee_id: parseInt(employee_id),
          token,
          device_type: device_type as any,
          app_version,
          os_version,
          created_at: new Date(),
          updated_at: new Date(),
          last_used_at: new Date(),
          is_active: true
        }
      });
      
      console.log('[Push Token Registration] Created new token:', pushToken.token_id);
    }
    
    return NextResponse.json({
      success: true,
      message: 'Push token registered successfully',
      token_id: pushToken.token_id
    });
    
  } catch (error) {
    console.error('[Push Token Registration] Error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Internal server error' 
      },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const employee_id = searchParams.get('employee_id');
    
    if (!employee_id) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'employee_id parameter required' 
        },
        { status: 400 }
      );
    }
    
    const tokens = await prisma.pushTokens.findMany({
      where: {
        employee_id: parseInt(employee_id),
        is_active: true
      },
      orderBy: {
        created_at: 'desc'
      }
    });
    
    return NextResponse.json({
      success: true,
      tokens: tokens
    });
    
  } catch (error) {
    console.error('[Push Token Registration] Get tokens error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Internal server error' 
      },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const employee_id = searchParams.get('employee_id');
    const token = searchParams.get('token');
    
    if (!employee_id) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'employee_id parameter required' 
        },
        { status: 400 }
      );
    }
    
    const whereClause: any = {
      employee_id: parseInt(employee_id)
    };
    
    if (token) {
      whereClause.token = token;
    }
    
    await prisma.pushTokens.updateMany({
      where: whereClause,
      data: {
        is_active: false,
        updated_at: new Date()
      }
    });
    
    return NextResponse.json({
      success: true,
      message: 'Push tokens deactivated successfully'
    });
    
  } catch (error) {
    console.error('[Push Token Registration] Delete tokens error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Internal server error' 
      },
      { status: 500 }
    );
  }
}