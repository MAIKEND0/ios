import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { employee_id } = body;
    
    if (!employee_id) {
      return NextResponse.json(
        { success: false, error: 'Missing employee_id' },
        { status: 400 }
      );
    }

    // Call the main send endpoint
    const sendResponse = await fetch(`${request.nextUrl.origin}/api/app/push/send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': request.headers.get('authorization') || ''
      },
      body: JSON.stringify({
        employee_id: parseInt(employee_id),
        title: '🔔 Test Notification',
        message: 'This is a test push notification from KSR Cranes App',
        notification_type: 'GENERAL_INFO',
        priority: 'NORMAL',
        category: 'SYSTEM',
        data: {
          test: true,
          timestamp: new Date().toISOString()
        }
      })
    });

    const result = await sendResponse.json();
    
    if (!sendResponse.ok) {
      return NextResponse.json(result, { status: sendResponse.status });
    }

    return NextResponse.json({
      success: true,
      message: 'Test notification sent successfully',
      ...result
    });

  } catch (error: any) {
    console.error('[Push Test Send] Error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to send test notification',
        details: error.message 
      },
      { status: 500 }
    );
  }
}

// GET endpoint for easy testing from browser
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const employee_id = searchParams.get('employee_id');
  
  if (!employee_id) {
    return NextResponse.json(
      { 
        success: false, 
        error: 'Missing employee_id parameter',
        usage: 'GET /api/app/push/send-test?employee_id=2' 
      },
      { status: 400 }
    );
  }

  // For GET request, we need to make internal POST call
  const response = await fetch(`${request.nextUrl.origin}/api/app/push/send-test`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ employee_id })
  });

  const result = await response.json();
  return NextResponse.json(result, { status: response.status });
}
