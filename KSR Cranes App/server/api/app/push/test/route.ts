import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  console.log('[Push Test] Test endpoint called');
  
  return NextResponse.json({
    success: true,
    message: 'Push notification test endpoint is working',
    timestamp: new Date().toISOString()
  });
}

export async function POST(request: NextRequest) {
  try {
    console.log('[Push Test] POST test endpoint called');
    
    const body = await request.json();
    console.log('[Push Test] Request body:', body);
    
    return NextResponse.json({
      success: true,
      message: 'Push notification POST test endpoint is working',
      received_data: body,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[Push Test] Error:', error);
    return NextResponse.json({
      success: false,
      error: 'Test endpoint error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}