import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import admin from 'firebase-admin';

const prisma = new PrismaClient();

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
  } catch (error) {
    console.error('Firebase admin initialization error:', error);
  }
}

export async function POST(request: NextRequest) {
  try {
    console.log('[Push Send] Starting push notification send...');
    
    const body = await request.json();
    const { 
      employee_id, 
      title, 
      message, 
      notification_type,
      priority = 'NORMAL',
      category,
      data = {}
    } = body;
    
    // Validate required fields
    if (!employee_id || !title || !message || !notification_type) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Missing required fields' 
        },
        { status: 400 }
      );
    }

    // Get active tokens for employee
    const tokens = await prisma.pushTokens.findMany({
      where: {
        employee_id: parseInt(employee_id),
        is_active: true
      }
    });

    if (tokens.length === 0) {
      return NextResponse.json({
        success: false,
        error: 'No active push tokens found for employee'
      }, { status: 404 });
    }

    // Create notification record in database
    const notification = await prisma.pushNotifications.create({
      data: {
        employee_id: parseInt(employee_id),
        title,
        message,
        notification_type: notification_type as any,
        priority: priority as any,
        category: category as any,
        sent_at: new Date(),
        status: 'PENDING'
      }
    });

    // Send to all active tokens
    const results = [];
    for (const token of tokens) {
      try {
        const pushMessage = {
          notification: {
            title,
            body: message,
            sound: 'default'
          },
          data: {
            ...data,
            notification_id: notification.notification_id.toString(),
            notification_type,
            category: category || '',
            priority
          },
          token: token.token,
          apns: {
            payload: {
              aps: {
                'mutable-content': 1,
                sound: 'default',
                badge: 1,
                'thread-id': category || 'general'
              }
            },
            headers: {
              'apns-priority': priority === 'URGENT' ? '10' : '5'
            }
          }
        };

        const response = await admin.messaging().send(pushMessage);
        console.log('[Push Send] Successfully sent to token:', token.token_id);
        
        results.push({
          token_id: token.token_id,
          success: true,
          response
        });

        // Update last_used_at for token
        await prisma.pushTokens.update({
          where: { token_id: token.token_id },
          data: { last_used_at: new Date() }
        });

      } catch (error: any) {
        console.error('[Push Send] Error sending to token:', token.token_id, error);
        
        results.push({
          token_id: token.token_id,
          success: false,
          error: error.message
        });

        // If token is invalid, deactivate it
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
          await prisma.pushTokens.update({
            where: { token_id: token.token_id },
            data: { is_active: false }
          });
        }
      }
    }

    // Update notification status
    const successCount = results.filter(r => r.success).length;
    await prisma.pushNotifications.update({
      where: { notification_id: notification.notification_id },
      data: {
        status: successCount > 0 ? 'SENT' : 'FAILED',
        error_message: successCount === 0 ? 'Failed to send to all tokens' : null
      }
    });

    return NextResponse.json({
      success: true,
      notification_id: notification.notification_id,
      sent_count: successCount,
      total_tokens: tokens.length,
      results
    });

  } catch (error: any) {
    console.error('[Push Send] Error:', error);
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