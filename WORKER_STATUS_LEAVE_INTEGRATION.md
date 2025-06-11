# Worker Status and Leave Management Integration

## Overview

This document describes how the worker status system integrates with the leave management system in the KSR Cranes app. The system automatically updates worker statuses based on approved leave requests, ensuring accurate workforce availability tracking.

## Current Implementation Status

### Database Architecture
- **Limitation**: Database only has `is_activated` boolean field, not a proper status enum column
- **Workaround**: System uses `is_activated` combined with active leave checks to determine actual status
- **Future**: Database should add a `status` column with enum values: 'aktiv', 'ferie', 'sygemeldt', 'inaktiv', 'opsagt'

### Status Mapping

| Leave Type | Worker Status | Display Name | is_activated |
|------------|---------------|--------------|--------------|
| VACATION | ferie | Vacation | false |
| SICK/EMERGENCY | sygemeldt | Sick Leave | false |
| No active leave | aktiv | Active | true |
| Deactivated (no leave) | inaktiv | Inactive | false |

## Implementation Components

### 1. Real-time Status Check
**Location**: `/server/api/app/chef/workers/route.ts`

The `getWorkerStatus()` function dynamically checks for active leave:
```typescript
async function getWorkerStatus(worker: any): Promise<string> {
  if (!worker.is_activated) {
    // Check for active approved leave
    const activeLeave = await prisma.leaveRequests.findFirst({
      where: {
        employee_id: worker.employee_id,
        status: 'APPROVED',
        start_date: { lte: today },
        end_date: { gte: today }
      }
    });
    
    if (activeLeave) {
      if (activeLeave.type === 'VACATION') return 'ferie';
      if (activeLeave.type === 'SICK' || activeLeave.type === 'EMERGENCY') return 'sygemeldt';
    }
    return 'inaktiv';
  }
  return 'aktiv';
}
```

### 2. Leave Approval Integration
**Location**: `/server/api/app/chef/leave/requests/route.ts`

When a leave request is approved AND starts today or earlier:
1. Updates `is_activated = false` in the employees table
2. Status will show as 'ferie' or 'sygemeldt' based on leave type
3. Creates notification for the employee

### 3. Daily Cron Job Updates
**Location**: `/server/api/app/chef/workers/update-leave-statuses/route.ts`

**Endpoints**:
- `GET /api/app/chef/workers/update-leave-statuses` - Preview status changes
- `POST /api/app/chef/workers/update-leave-statuses` - Execute status updates

**Functionality**:
1. Finds all approved leave starting today → Sets `is_activated = false`
2. Finds all approved leave ending today → Sets `is_activated = true` (unless ongoing leave)
3. Logs all changes for audit purposes

### 4. iOS Client Integration
**Location**: `Features/Chef/Workers/ChefWorkersViewModel.swift`

**Temporary Status Cache**:
```swift
private var statusCache: [Int: WorkerStatus] = [:]
```
- Caches status changes made through the UI
- Applied when loading worker list to maintain consistency
- Will be removed once database has proper status column

## User Experience Flow

### Worker Perspective
1. Worker submits leave request (e.g., vacation from June 15-20)
2. Manager approves the request on June 10
3. Worker status remains "Active" until June 15
4. On June 15, status automatically changes to "Vacation"
5. On June 21, status automatically returns to "Active"

### Manager Perspective
1. Views worker list showing real-time statuses
2. Sees "Vacation" or "Sick Leave" for workers currently on leave
3. Can override status manually if needed
4. Calendar view shows upcoming leave periods

### System Automation
1. **Immediate Update**: If approving leave that already started
2. **Scheduled Update**: Daily cron job at midnight for future leave
3. **End Date Processing**: Automatic return to active status

## Configuration Requirements

### Cron Job Setup
```bash
# Add to crontab or scheduling service
0 0 * * * curl -X POST https://ksrcranes.dk/api/app/chef/workers/update-leave-statuses \
  -H "Authorization: Bearer YOUR_CRON_TOKEN"
```

### Authentication for Cron
Options:
1. Special cron authentication token
2. Service account with limited permissions
3. IP whitelist for cron server

## Testing the Integration

### Manual Testing
1. Create a leave request with start date = today
2. Approve the request
3. Check worker status immediately (should show vacation/sick)
4. Check worker appears in calendar view

### Cron Job Testing
```bash
# Check which workers need updates
GET /api/app/chef/workers/update-leave-statuses

# Manually trigger update (requires auth)
POST /api/app/chef/workers/update-leave-statuses
```

## Known Issues and Limitations

1. **Database Schema**: Only boolean `is_activated` field, not proper status enum
2. **Status Display**: Server dynamically determines status on each request
3. **Performance**: Additional database query for each worker to check leave
4. **Cache Requirement**: iOS app needs temporary cache for UI consistency

## Future Improvements

1. **Database Migration**: Add proper `status` enum column
2. **Remove iOS Cache**: Once database has status column
3. **Push Notifications**: Real-time status updates to managers
4. **Webhook Support**: Notify external systems of status changes
5. **Audit Trail**: Complete history of status changes

## Related Documentation

- [Leave Management System](LEAVE_MANAGEMENT_IMPLEMENTATION.md)
- [Push Notifications](PUSH_NOTIFICATIONS_DOCUMENTATION.md)
- [Worker Management](WORKER_MANAGEMENT_IMPLEMENTATION.md)