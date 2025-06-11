# KSR Cranes App - Server API Documentation

## 🎯 **Overview**

The KSR Cranes server is a robust Next.js-based API that powers the iOS application. It manages crane operator staffing operations with comprehensive features for workers, managers, and business executives.

**Business Context**: KSR Cranes provides certified crane operators to work with clients' equipment - this is a staffing/personnel service, NOT equipment rental.

---

## 🏗️ **Technology Stack**

### **Backend Framework**
- **Next.js 14** with App Router for modern React-based API development
- **TypeScript** for type safety and better development experience
- **Node.js** runtime environment

### **Database**
- **MySQL** as primary database system
- **Prisma ORM** for type-safe database access and migrations
- **50+ tables** covering all business operations
- **Comprehensive relationships** with foreign key constraints

### **Authentication & Security**
- **JWT (JSON Web Tokens)** for stateless authentication
- **Role-based access control** (RBAC) with hierarchy
- **Bcrypt** for password hashing
- **CORS** configuration for API security

### **File Storage**
- **DigitalOcean Spaces** (S3-compatible) for file storage
- **CDN support** for optimized file delivery
- **Organized directory structure** for different file types
- **Presigned URLs** for secure file access

### **Additional Services**
- **Push Notifications** integration
- **Email notifications** for business workflows
- **Logging and monitoring** for production debugging

---

## 🗄️ **Database Architecture**

### **Core Tables Structure**

```sql
-- Core Business Entities
Employees               # Workers, managers, and executives
Projects               # Client projects
Tasks                  # Specific assignments within projects
WorkEntries           # Time tracking and hours submission
Customers             # Client companies and contacts

-- Leave Management System
LeaveRequests         # Vacation, sick leave, personal days
LeaveBalance          # Annual leave tracking per employee
PublicHolidays        # Danish holidays calendar

-- Payroll System
PayrollBatches        # Bi-weekly payroll processing
EmployeeOvertimeSettings  # Rate management

-- Certifications & Skills
Certificates          # Required crane operator certifications
EmployeeCertificates  # Employee certification tracking

-- Notification System
Notifications         # In-app notifications
PushNotificationTokens  # Device tokens for push notifications

-- File Management
S3Files              # File storage tracking
```

### **Key Relationships**

```
Employees (1) ←→ (M) WorkEntries ←→ (1) Projects ←→ (1) Customers
    ↓                    ↓
    LeaveRequests        Tasks
    ↓                    ↓
    LeaveBalance         TaskAssignments
```

### **Role Hierarchy**

```
system (highest)
    ↓
chef (business owner)
    ↓  
byggeleder (project manager)
    ↓
arbejder (crane operator)
```

---

## 🔗 **API Endpoint Organization**

### **Directory Structure**

```
server/api/app/
├── 👷 worker/              # Worker (arbejder) endpoints
│   ├── profile/           # Personal profile management
│   ├── timesheets/        # Timesheet submission and history
│   ├── leave/             # Leave request management
│   └── tasks/             # Task viewing and updates
├── 👔 supervisor/          # Manager (byggeleder) endpoints  
│   ├── projects/          # Project management
│   ├── workers/           # Team member oversight
│   └── profile/           # Manager profile
├── 🏢 chef/               # Chef/Boss (chef) endpoints
│   ├── workers/           # Employee CRUD operations
│   ├── customers/         # Customer management
│   ├── projects/          # Full project control
│   ├── payroll/           # Payroll processing
│   ├── leave/             # Leave oversight
│   ├── tasks/             # Task management
│   ├── certificates/      # Certification management
│   └── management-calendar/  # Resource planning
└── 🔄 shared/             # Common endpoints
    ├── notifications/     # Notification system
    ├── work-entries/      # Work hour submissions
    ├── push/              # Push notification management
    └── upload/            # File upload utilities
```

### **RESTful URL Patterns**

```
# Resource Collections
GET /api/app/{role}/{resource}              # List resources
POST /api/app/{role}/{resource}             # Create resource

# Individual Resources  
GET /api/app/{role}/{resource}/[id]         # Get specific resource
PUT /api/app/{role}/{resource}/[id]         # Update resource
DELETE /api/app/{role}/{resource}/[id]      # Delete resource

# Sub-resources
GET /api/app/{role}/{resource}/[id]/{sub}   # Get sub-resources
POST /api/app/{role}/{resource}/[id]/{sub}  # Create sub-resource

# Actions
POST /api/app/{role}/{resource}/[id]/{action}  # Perform action
```

---

## 🔐 **Authentication & Authorization**

### **JWT Token Structure**

```json
{
  "employee_id": 123,
  "email": "user@example.com", 
  "role": "arbejder",
  "name": "John Doe",
  "iat": 1640995200,
  "exp": 1641081600
}
```

### **Authentication Middleware Pattern**

```typescript
// Authentication verification
export async function verifyAuth(request: Request) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing or invalid authorization header');
  }
  
  const token = authHeader.slice(7);
  const decoded = jwt.verify(token, JWT_SECRET) as JWTPayload;
  return decoded;
}

// Role-based authorization
export function requireRole(allowedRoles: string[]) {
  return (user: JWTPayload) => {
    if (!allowedRoles.includes(user.role)) {
      throw new Error('Insufficient permissions');
    }
  };
}
```

### **Role Access Matrix**

| Endpoint Type | arbejder | byggeleder | chef | system |
|---------------|----------|------------|------|--------|
| Worker endpoints | ✅ (own) | ✅ (team) | ✅ (all) | ✅ |
| Supervisor endpoints | ❌ | ✅ (own) | ✅ (all) | ✅ |
| Chef endpoints | ❌ | ❌ | ✅ | ✅ |
| System endpoints | ❌ | ❌ | ❌ | ✅ |

---

## 📁 **File Storage & S3 Integration**

### **DigitalOcean Spaces Configuration**

```typescript
const s3Config = {
  endpoint: 'https://fra1.digitaloceanspaces.com',
  region: 'fra1',
  credentials: {
    accessKeyId: process.env.DO_SPACES_KEY,
    secretAccessKey: process.env.DO_SPACES_SECRET,
  }
};
```

### **Directory Structure**

```
ksrcranes-files/
├── 👤 employee-profiles/      # Profile pictures
│   └── {employee_id}/
│       └── profile_{timestamp}.jpg
├── 📄 documents/             # Worker documents  
│   └── {employee_id}/
│       ├── contracts/
│       ├── certificates/
│       └── general/
├── ✍️ signatures/            # Digital signatures
│   └── {employee_id}/
│       └── signature_{timestamp}.png
└── 🏢 customer-logos/        # Customer branding
    └── {customer_id}/
        └── logo_{timestamp}.png
```

### **File Upload Process**

```typescript
// Multipart file handling
export async function handleFileUpload(
  files: File[],
  basePath: string,
  allowedTypes: string[]
) {
  const uploadResults = [];
  
  for (const file of files) {
    // Validate file type and size
    validateFile(file, allowedTypes);
    
    // Generate unique filename
    const filename = generateUniqueFilename(file.name);
    const fullPath = `${basePath}/${filename}`;
    
    // Upload to DigitalOcean Spaces
    const result = await s3Client.upload({
      Bucket: 'ksrcranes-files',
      Key: fullPath,
      Body: Buffer.from(await file.arrayBuffer()),
      ContentType: file.type,
      ACL: 'public-read'
    }).promise();
    
    uploadResults.push({
      filename,
      url: result.Location,
      size: file.size
    });
  }
  
  return uploadResults;
}
```

---

## 🎭 **Role-Based API Endpoints**

### **👷 Worker (Arbejder) Endpoints**

#### **Profile Management** (`/api/app/worker/profile/`)
```typescript
GET /[employeeId]           # Get worker profile
PUT /[employeeId]           # Update profile information  
POST /[employeeId]/avatar   # Upload profile picture
```

#### **Timesheet Management** (`/api/app/worker/timesheets/`)
```typescript
GET /                       # Get timesheet history
POST /                      # Submit new timesheet
GET /stats                  # Get timesheet statistics
```

#### **Leave Management** (`/api/app/worker/leave/`)
```typescript
GET /                       # Get personal leave requests
POST /                      # Submit leave request
PUT /                       # Update pending request
DELETE /                    # Cancel request

GET /balance               # Get leave balance
GET /holidays              # Get public holidays
POST /[id]/documents       # Upload sick note
```

### **👔 Manager (Byggeleder) Endpoints**

#### **Project Management** (`/api/app/supervisor/projects/`)
```typescript
GET /                       # Get assigned projects
GET /[id]                   # Get project details
PUT /[id]                   # Update project status
```

#### **Team Management** (`/api/app/supervisor/workers/`)
```typescript
GET /                       # Get team members
GET /[id]                   # Get worker details
PUT /[id]/status            # Update worker status
```

#### **Profile & Signature** (`/api/app/supervisor/profile/`)
```typescript
GET /[supervisorId]         # Get supervisor profile
POST /[supervisorId]/avatar # Upload profile picture
POST /signature             # Submit digital signature
```

### **🏢 Chef/Boss Endpoints**

#### **Employee Management** (`/api/app/chef/workers/`)
```typescript
GET /                       # List all employees
POST /                      # Create new employee
GET /[id]                   # Get employee details
PUT /[id]                   # Update employee
DELETE /[id]                # Terminate employee

GET /stats                  # Employee statistics
GET /search                 # Search employees
GET /availability           # Worker availability matrix

# Document Management
GET /[id]/documents         # List worker documents
POST /[id]/documents        # Upload documents
DELETE /[id]/documents/[docId]  # Remove document

# Rate Management
GET /[id]/rates             # Get employee rates
PUT /[id]/rates             # Update hourly rates

# Certification Tracking
GET /[id]/certificates      # List certifications
POST /[id]/certificates     # Add certification
PUT /[id]/certificates/[certId]  # Update certification
```

#### **Customer Management** (`/api/app/chef/customers/`)
```typescript
GET /                       # List customers
POST /                      # Create customer
GET /[id]                   # Get customer details
PUT /[id]                   # Update customer
DELETE /[id]                # Archive customer

GET /search                 # Search customers
GET /stats                  # Customer statistics

# Logo Management
POST /[id]/logo/presigned   # Get presigned upload URL
POST /[id]/logo/confirm     # Confirm logo upload
DELETE /[id]/logo           # Remove logo
```

#### **Project Management** (`/api/app/chef/projects/`)
```typescript
GET /                       # List all projects
POST /                      # Create project
GET /[id]                   # Get project details
PUT /[id]                   # Update project
DELETE /[id]                # Archive project

GET /[id]/timeline          # Project timeline
GET /[id]/buisness-timeline # Business timeline
GET /[id]/available-workers # Available workers for project

# Task Management
GET /[id]/tasks             # Project tasks
POST /[id]/tasks            # Create task for project

# Billing Settings
GET /[id]/billing-settings  # Get billing configuration
PUT /[id]/billing-settings  # Update billing settings
```

#### **Task Management** (`/api/app/chef/tasks/`)
```typescript
GET /                       # List all tasks
POST /                      # Create task
GET /[id]                   # Get task details
PUT /[id]                   # Update task
DELETE /[id]                # Remove task

# Assignment Management
GET /[id]/assignments       # Task assignments
POST /[id]/assignments      # Assign workers to task
PUT /[id]/assignments/[assignmentId]  # Update assignment

# Certificate Requirements
GET /[id]/certificates      # Required certificates for task
POST /[id]/certificates     # Add certificate requirement

# Worker Availability
GET /[id]/available-workers # Workers eligible for task
```

#### **Payroll Management** (`/api/app/chef/payroll/`)
```typescript
GET /dashboard/stats        # Payroll dashboard statistics
GET /activity              # Recent payroll activity

# Batch Management
GET /batches                # List payroll batches
POST /batches               # Create new batch
GET /batches/[id]           # Get batch details
PUT /batches/[id]           # Update batch
DELETE /batches/[id]        # Cancel batch

# Period Management
GET /periods/available      # Available payroll periods
GET /ready                  # Hours ready for processing
```

#### **Leave Management** (`/api/app/chef/leave/`)
```typescript
GET /requests               # All leave requests
PUT /requests               # Approve/reject requests

GET /calendar               # Team leave calendar
GET /statistics             # Leave usage analytics

# Balance Management
GET /balance                # All employee balances
PUT /balance                # Adjust employee balance
POST /balance/recalculate   # Recalculate balances
```

#### **Certificate Management** (`/api/app/chef/certificates/`)
```typescript
GET /                       # List all certificates
POST /                      # Create certificate type
GET /[id]                   # Get certificate details
PUT /[id]                   # Update certificate
DELETE /[id]                # Remove certificate

GET /expiring               # Certificates expiring soon
GET /statistics             # Certificate statistics
```

#### **Management Calendar** (`/api/app/chef/management-calendar/`)
```typescript
POST /unified               # Get unified calendar data
POST /summary               # Calendar summary for date
POST /conflicts             # Detect scheduling conflicts
POST /validate              # Validate schedule
```

### **🔄 Shared Endpoints**

#### **Work Entries** (`/api/app/work-entries/`)
```typescript
GET /                       # Get work entries (role-filtered)
POST /                      # Submit work entry
PUT /                       # Update work entry
DELETE /                    # Delete work entry

GET /confirmed              # Get confirmed entries
```

#### **Notifications** (`/api/app/notifications/`)
```typescript
GET /                       # Get user notifications
POST /[id]/read             # Mark notification as read
GET /unread-count           # Get unread count
```

#### **Push Notifications** (`/api/app/push/`)
```typescript
POST /register-token        # Register device token
POST /register-token-v2     # Register with user info
POST /send                  # Send push notification
POST /send-test             # Send test notification
GET /test                   # Test push notification setup
```

---

## 📋 **Data Models & Validation**

### **Common Validation Patterns**

```typescript
// Email validation
const emailSchema = z.string()
  .email("Invalid email format")
  .min(1, "Email is required");

// Phone validation (Danish format)
const phoneSchema = z.string()
  .regex(/^(\+45\s?)?(\d{2}\s?\d{2}\s?\d{2}\s?\d{2})$/, "Invalid Danish phone number");

// Date validation
const dateSchema = z.string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format")
  .refine(date => !isNaN(Date.parse(date)), "Invalid date");

// Work hours validation
const workHoursSchema = z.number()
  .min(0, "Hours cannot be negative")
  .max(24, "Hours cannot exceed 24 per day");
```

### **Standard Response Formats**

#### **Success Response**
```typescript
interface SuccessResponse<T> {
  success: true;
  data: T;
  message?: string;
  metadata?: {
    total?: number;
    page?: number;
    limit?: number;
    hasNext?: boolean;
  };
}
```

#### **Error Response**
```typescript
interface ErrorResponse {
  success: false;
  error: string;
  details?: string[];
  code?: number;
  timestamp: string;
}
```

#### **Paginated Response**
```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalCount: number;
    hasNext: boolean;
    hasPrevious: boolean;
  };
}
```

### **Data Transformation Patterns**

```typescript
// Database to API model transformation
function transformEmployeeForAPI(dbEmployee: Employee): EmployeeAPI {
  return {
    id: dbEmployee.employee_id,
    name: dbEmployee.name,
    email: dbEmployee.email,
    phone: dbEmployee.phone_number,
    role: dbEmployee.role,
    isActive: dbEmployee.is_activated,
    profilePictureUrl: dbEmployee.profilePictureUrl,
    createdAt: dbEmployee.created_at.toISOString(),
    // Computed fields
    displayName: dbEmployee.name || 'Unknown Employee',
    isManager: ['byggeleder', 'chef'].includes(dbEmployee.role)
  };
}

// API to database model transformation
function transformAPIToDatabase(apiData: CreateEmployeeRequest): DatabaseEmployee {
  return {
    name: apiData.name?.trim(),
    email: apiData.email?.toLowerCase(),
    phone_number: apiData.phone,
    role: apiData.role,
    operator_normal_rate: new Decimal(apiData.hourlyRate),
    is_activated: true,
    created_at: new Date()
  };
}
```

---

## 💼 **Business Logic & Rules**

### **Danish Employment Law Compliance**

#### **Leave Management Rules**
```typescript
const LEAVE_RULES = {
  VACATION: {
    annualDays: 25,           // 25 vacation days per year
    advanceNoticeDays: 14,    // 14 days advance notice required
    maxConsecutiveDays: 20,   // Max 20 consecutive days without approval
    carryOverDays: 5,         // Max 5 days can be carried over
    carryOverExpiry: '2025-09-30'  // Carryover expires September 30
  },
  SICK: {
    unlimitedDays: true,      // No limit on sick days
    documentationRequired: 3, // Sick note required after 3 days
    emergencyAllowed: true,   // Emergency sick leave allowed
    retroactiveDays: 3        // Can report up to 3 days retroactively
  },
  PERSONAL: {
    annualDays: 5,           // 5 personal days per year
    advanceNoticeHours: 24,  // 24 hours advance notice
    emergencyOverride: true  // Emergency personal days allowed
  }
};
```

#### **Work Hours Rules**
```typescript
const WORK_HOURS_RULES = {
  NORMAL: {
    dailyMax: 8,             // 8 hours normal time per day
    weeklyMax: 37,           // 37 hours normal time per week
  },
  OVERTIME: {
    dailyThreshold: 8,       // Overtime after 8 hours
    weeklyThreshold: 37,     // Overtime after 37 hours
    rate1Multiplier: 1.5,    // 150% rate for first overtime hours
    rate2Multiplier: 2.0,    // 200% rate for excessive overtime
  },
  WEEKEND: {
    saturdayMultiplier: 1.5, // 150% rate for Saturday
    sundayMultiplier: 2.0,   // 200% rate for Sunday
    holidayMultiplier: 2.0   // 200% rate for public holidays
  }
};
```

#### **Payroll Processing Rules**
```typescript
const PAYROLL_RULES = {
  PERIOD: {
    type: 'bi-weekly',       // Bi-weekly payroll periods
    startDay: 'monday',      // Periods start on Monday
    durationDays: 14,        // Exactly 14 days per period
    format: 'YYYY-PP'        // Format: 2024-26 (year-period)
  },
  RATES: {
    currency: 'DKK',         // Danish Kroner
    precision: 2,            // 2 decimal places
    minimumWage: 165.0,      // Minimum hourly rate in DKK
    overtimeThreshold: 37    // Weekly hours before overtime
  }
};
```

### **Task Assignment Rules**

```typescript
async function validateTaskAssignment(
  taskId: number, 
  workerId: number, 
  assignmentDate: Date
): Promise<ValidationResult> {
  const validations = [
    // Check worker availability
    async () => await checkWorkerAvailability(workerId, assignmentDate),
    
    // Verify required certifications
    async () => await verifyWorkerCertifications(taskId, workerId),
    
    // Check for scheduling conflicts
    async () => await checkSchedulingConflicts(workerId, assignmentDate),
    
    // Validate equipment requirements
    async () => await validateEquipmentRequirements(taskId, workerId),
    
    // Check client approval requirements
    async () => await checkClientApprovalRequirements(taskId, workerId)
  ];
  
  for (const validation of validations) {
    const result = await validation();
    if (!result.isValid) {
      return result;
    }
  }
  
  return { isValid: true, message: 'Assignment validated successfully' };
}
```

### **Crane Operator Certification System**

```typescript
const DANISH_CRANE_CERTIFICATIONS = {
  // No tonnage limits in Danish system - based on crane type
  MOBILE_CRANE: {
    code: 'MC',
    description: 'Mobile Crane Operator',
    validityYears: 5,
    renewalRequired: true
  },
  TOWER_CRANE: {
    code: 'TC', 
    description: 'Tower Crane Operator',
    validityYears: 5,
    renewalRequired: true
  },
  TELEHANDLER: {
    code: 'TH',
    description: 'Telehandler Operator', 
    validityYears: 3,
    renewalRequired: true
  }
};

async function validateWorkerForTask(workerId: number, taskId: number) {
  const task = await getTaskWithRequirements(taskId);
  const workerCerts = await getWorkerCertifications(workerId);
  
  const requiredCerts = task.required_crane_types || [];
  const missingCerts = [];
  
  for (const requiredType of requiredCerts) {
    const hasValidCert = workerCerts.some(cert => 
      cert.crane_type === requiredType && 
      cert.status === 'ACTIVE' &&
      cert.expiry_date > new Date()
    );
    
    if (!hasValidCert) {
      missingCerts.push(requiredType);
    }
  }
  
  return {
    eligible: missingCerts.length === 0,
    missingCertifications: missingCerts
  };
}
```

---

## ⚠️ **Error Handling**

### **HTTP Status Code Usage**

```typescript
const HTTP_STATUS = {
  200: 'OK - Request successful',
  201: 'Created - Resource created successfully', 
  400: 'Bad Request - Invalid request data',
  401: 'Unauthorized - Authentication required',
  403: 'Forbidden - Insufficient permissions',
  404: 'Not Found - Resource not found',
  409: 'Conflict - Resource conflict (e.g., duplicate)',
  422: 'Unprocessable Entity - Validation failed',
  500: 'Internal Server Error - Server error'
};
```

### **Error Response Patterns**

```typescript
// Validation Error (422)
{
  "success": false,
  "error": "Validation failed",
  "details": [
    "Email is required",
    "Phone number must be in Danish format",
    "Hourly rate must be at least 165 DKK"
  ],
  "timestamp": "2024-06-10T10:30:00Z"
}

// Authentication Error (401)
{
  "success": false,
  "error": "Authentication failed",
  "details": ["Token expired or invalid"],
  "timestamp": "2024-06-10T10:30:00Z"
}

// Business Logic Error (409)
{
  "success": false,
  "error": "Leave request conflict",
  "details": ["You already have approved leave from 2024-06-15 to 2024-06-20"],
  "conflicting_request": {
    "id": 123,
    "type": "vacation",
    "start_date": "2024-06-15",
    "end_date": "2024-06-20"
  },
  "timestamp": "2024-06-10T10:30:00Z"
}
```

### **Common Error Patterns**

```typescript
// Resource not found
export function createNotFoundError(resource: string, id: string) {
  return NextResponse.json({
    success: false,
    error: `${resource} not found`,
    details: [`No ${resource.toLowerCase()} found with ID ${id}`],
    timestamp: new Date().toISOString()
  }, { status: 404 });
}

// Validation error
export function createValidationError(errors: string[]) {
  return NextResponse.json({
    success: false,
    error: "Validation failed",
    details: errors,
    timestamp: new Date().toISOString()
  }, { status: 422 });
}

// Permission error
export function createPermissionError(action: string) {
  return NextResponse.json({
    success: false,
    error: "Insufficient permissions",
    details: [`You don't have permission to ${action}`],
    timestamp: new Date().toISOString()
  }, { status: 403 });
}
```

---

## 📱 **iOS App Integration**

### **BaseAPIService Pattern**

The iOS app uses a centralized `BaseAPIService` that handles:

```swift
// Automatic authentication header injection
func addAuthHeaders(to request: inout URLRequest) {
    if let token = AuthService.shared.getAuthToken() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// Consistent error handling
enum APIError: Error {
    case authenticationError     // Maps to 401
    case permissionError        // Maps to 403
    case notFoundError          // Maps to 404
    case validationError([String])  // Maps to 422
    case serverError(String)    // Maps to 500
}

// Response parsing
func parseResponse<T: Codable>(_ data: Data, type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(type, from: data)
}
```

### **Authentication Flow**

```
iOS App Startup → Check Keychain for token
     ↓
Token exists → Validate with server (/api/auth/validate)
     ↓
Valid → Load user role and initialize app
     ↓
Invalid → Show login screen
     ↓
Login success → Store token in Keychain → Initialize app
```

### **Offline Support Strategy**

```typescript
// iOS caching strategy for offline support
const CACHE_STRATEGIES = {
  USER_PROFILE: 'persistent',      // Always cached
  WORK_ENTRIES: 'session',         // Cached per session  
  LEAVE_BALANCE: 'persistent',     // Cached with TTL
  NOTIFICATIONS: 'none',           // Always fetch fresh
  DASHBOARD_STATS: 'session'       // Cached per session
};
```

### **Error Handling Pattern**

```swift
// ViewModel error handling
func handleAPIError(_ error: BaseAPIService.APIError) {
    DispatchQueue.main.async {
        switch error {
        case .authenticationError:
            // Logout user and show login
            AuthService.shared.logout()
        case .validationError(let errors):
            self.errorMessage = "Please check: \(errors.joined(separator: ", "))"
        case .permissionError:
            self.errorMessage = "You don't have permission for this action"
        case .serverError(let message):
            self.errorMessage = "Server error: \(message)"
        }
        
        self.isLoading = false
    }
}
```

---

## 🚀 **Performance & Optimization**

### **Database Optimization**

```sql
-- Key indexes for performance
CREATE INDEX idx_employees_role ON Employees(role);
CREATE INDEX idx_work_entries_employee_date ON WorkEntries(employee_id, work_date);
CREATE INDEX idx_leave_requests_employee_status ON LeaveRequests(employee_id, status);
CREATE INDEX idx_notifications_employee_read ON Notifications(employee_id, is_read);

-- Composite indexes for common queries
CREATE INDEX idx_tasks_project_status ON Tasks(project_id, status);
CREATE INDEX idx_payroll_period_status ON PayrollBatches(period_start, status);
```

### **API Response Optimization**

```typescript
// Pagination for large datasets
const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

export function paginate<T>(
  query: any,
  page: number = 1,
  limit: number = DEFAULT_PAGE_SIZE
) {
  const offset = (page - 1) * Math.min(limit, MAX_PAGE_SIZE);
  return query.skip(offset).take(limit);
}

// Field selection to reduce payload size
export function selectEmployeeFields(includePrivate: boolean = false) {
  const baseFields = {
    employee_id: true,
    name: true,
    email: true,
    role: true,
    is_activated: true,
    profilePictureUrl: true
  };
  
  if (includePrivate) {
    return {
      ...baseFields,
      phone_number: true,
      address: true,
      operator_normal_rate: true
    };
  }
  
  return baseFields;
}
```

### **Caching Strategy**

```typescript
// Response caching for frequently accessed data
const CACHE_TTL = {
  PUBLIC_HOLIDAYS: 86400,      // 24 hours
  EMPLOYEE_LIST: 3600,         // 1 hour  
  CUSTOMER_LIST: 1800,         // 30 minutes
  DASHBOARD_STATS: 300,        // 5 minutes
  NOTIFICATIONS: 60            // 1 minute
};

// Memory caching for static data
const memoryCache = new Map();

export function getCachedData(key: string, ttl: number) {
  const cached = memoryCache.get(key);
  if (cached && (Date.now() - cached.timestamp) < (ttl * 1000)) {
    return cached.data;
  }
  return null;
}
```

---

## 🔧 **Development & Deployment**

### **Environment Configuration**

```typescript
// Environment variables
const config = {
  DATABASE_URL: process.env.DATABASE_URL,
  JWT_SECRET: process.env.JWT_SECRET,
  DO_SPACES_KEY: process.env.DO_SPACES_KEY,
  DO_SPACES_SECRET: process.env.DO_SPACES_SECRET,
  PUSH_NOTIFICATION_KEY: process.env.PUSH_NOTIFICATION_KEY,
  
  // Feature flags
  ENABLE_PUSH_NOTIFICATIONS: process.env.ENABLE_PUSH_NOTIFICATIONS === 'true',
  ENABLE_S3_UPLOADS: process.env.ENABLE_S3_UPLOADS === 'true',
  DEBUG_MODE: process.env.NODE_ENV === 'development'
};
```

### **API Documentation Generation**

```typescript
// OpenAPI specification for automatic documentation
export const apiSpec = {
  openapi: '3.0.0',
  info: {
    title: 'KSR Cranes API',
    version: '1.0.0',
    description: 'Crane operator staffing management API'
  },
  servers: [
    {
      url: 'https://ksrcranes.dk/api',
      description: 'Production server'
    }
  ],
  paths: {
    // Auto-generated from route handlers
  }
};
```

### **Testing Strategy**

```typescript
// API endpoint testing
describe('Worker Leave API', () => {
  test('should submit leave request successfully', async () => {
    const response = await request(app)
      .post('/api/app/worker/leave')
      .set('Authorization', `Bearer ${workerToken}`)
      .send({
        type: 'VACATION',
        start_date: '2024-07-01',
        end_date: '2024-07-05',
        reason: 'Summer vacation'
      });
    
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
  
  test('should validate leave dates', async () => {
    const response = await request(app)
      .post('/api/app/worker/leave')
      .set('Authorization', `Bearer ${workerToken}`)
      .send({
        type: 'VACATION',
        start_date: '2024-06-15',  // Past date
        end_date: '2024-06-20'
      });
    
    expect(response.status).toBe(422);
    expect(response.body.details).toContain('Vacation requires 14 days advance notice');
  });
});
```

This comprehensive server API documentation provides a complete understanding of the backend architecture that powers the KSR Cranes iOS application, enabling effective development, integration, and maintenance of the system.