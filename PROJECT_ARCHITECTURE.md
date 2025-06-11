# KSR Cranes App - Project Architecture Documentation

## 📱 **Project Overview**

KSR Cranes App is a comprehensive iOS application for managing crane operator staffing operations. Built using SwiftUI and MVVM architecture, it serves KSR Cranes, a Danish company that provides certified crane operators to work with clients' equipment.

**Key Business Model**: Staff augmentation for crane operators, NOT equipment rental.

---

## 🏗️ **Architecture Overview**

### **Core Architectural Pattern: MVVM + Reactive Programming**

```
┌─────────────────┐
│   SwiftUI View │ ← User Interface Layer
└─────────────────┘
         ↓ @ObservedObject
┌─────────────────┐
│    ViewModel    │ ← Business Logic Layer
└─────────────────┘
         ↓ Combine Publishers
┌─────────────────┐
│  Service Layer  │ ← Data Access Layer
└─────────────────┘
         ↓ HTTP/API Calls
┌─────────────────┐
│  Backend API    │ ← Next.js Server
└─────────────────┘
```

### **Key Architectural Decisions**

1. **Preloaded ViewModels Pattern**
   - ViewModels initialized during app startup in `AppStateManager`
   - Eliminates loading states in primary user interface
   - Data ready before views appear

2. **Role-Based UI Isolation**
   - Complete separation between user roles (Worker, Manager, Chef)
   - Dedicated API services per role
   - Enhanced security through UI segregation

3. **Centralized State Management**
   - `AppStateManager` as single source of truth
   - Coordinates authentication state changes
   - Manages app-wide data refresh and initialization

4. **No External Dependencies**
   - Pure Swift/SwiftUI implementation
   - Custom networking, caching, and utility solutions
   - Reduced app size and maintenance complexity

---

## 📁 **Directory Structure**

```
KSR Cranes App/
├── 📦 Core/                     # Core business logic & services
│   ├── 🔧 Services/            # API services, auth, notifications
│   ├── 📋 Models/              # Domain models & data structures
│   ├── 🎯 ViewModels/          # Core ViewModels
│   ├── 🏪 Cache/               # Custom caching implementation
│   ├── 🛠️ Utilities/           # Configuration & helpers
│   └── 📱 Components/          # Reusable UI components
├── 🎨 Features/                # Feature-based modules
│   ├── 👷 Worker/              # Worker role features
│   ├── 👔 Manager/             # Manager role features
│   └── 🏢 Chef/                # Chef/Boss role features
├── 🧭 UI/                      # Navigation & shared UI
│   ├── 📍 Navigation/          # App navigation system
│   ├── 👤 Profile/             # Shared profile components
│   └── 🎬 Splash/              # App startup screens
├── ⚡ Extensions/              # Swift extensions
├── 🔧 Utils/                   # Utility functions & helpers
├── 🐛 Debug/                   # Development & debug tools
└── 📱 KSR Cranes App/          # Xcode project files
    ├── 🗄️ server/              # Next.js backend API
    └── 💾 database_migrations/ # Database schema updates
```

---

## 🎭 **User Roles & Features**

### **👷 Worker (Arbejder)**
```
Features/Worker/
├── Dashboard/          # Work stats, upcoming tasks
├── WorkHours/          # Time tracking & submission
├── Tasks/              # Assigned tasks management
├── Leave/              # Leave requests (vacation, sick)
├── Profile/            # Personal profile management
├── Timesheet/          # Historical timesheet reports
└── ViewModels/         # Worker-specific business logic
```

**Key Capabilities:**
- Track work hours (normal, overtime, weekend rates)
- Submit and manage leave requests
- View assigned tasks and project details
- Access personal timesheet reports
- Update profile information

### **👔 Manager (Byggeleder)**
```
Features/Manager/
├── Dashboard/          # Team overview & pending approvals
├── Projects/           # Project management
├── Workers/            # Team member management
├── Workplan/           # Work schedule planning
├── Timesheet/          # Timesheet review & approval
├── Signature/          # Digital signature system
└── ViewModels/         # Manager-specific business logic
```

**Key Capabilities:**
- Approve timesheets and leave requests
- Manage project assignments
- Create and edit work plans
- Oversee team members
- Digital signature workflows

### **🏢 Chef/Boss**
```
Features/Chef/
├── Dashboard/          # Executive overview & KPIs
├── Customers/          # Client management
├── Projects/           # Full project oversight
├── Workers/            # Employee management (CRUD)
├── Payroll/            # Bi-weekly payroll processing
├── Leave/              # Company-wide leave management
├── ManagementCalendar/ # Resource planning & scheduling
└── ViewModels/         # Chef-specific business logic
```

**Key Capabilities:**
- Full business oversight and analytics
- Customer relationship management
- Employee lifecycle management
- Payroll processing (bi-weekly Danish system)
- Resource planning and allocation
- Company-wide leave management

---

## 🔌 **Core Services Architecture**

### **BaseAPIService** (`Core/Services/BaseAPIService.swift`)
Foundation for all API communication providing:
- JWT token injection via `AuthInterceptor`
- Standardized error handling
- Request/response logging
- Retry mechanisms
- Combine publisher integration

### **Authentication Flow**
```
AuthService ←→ KeychainService ←→ BaseAPIService
     ↓
AppStateManager
     ↓
RoleBasedRootView
```

**Components:**
- `AuthService.swift`: Authentication state management
- `KeychainService.swift`: Secure token storage
- `AuthInterceptor.swift`: Automatic API authentication
- `AuthenticationHandler.swift`: Auth workflow coordination

### **Role-Specific API Services**
- `WorkerAPIService.swift`: Worker endpoints
- `ManagerAPIService.swift`: Manager endpoints  
- `ChefAPIService.swift`: Chef endpoints
- Plus specialized services (PayrollAPIService, LeaveAPIService, etc.)

---

## 🗄️ **Backend Architecture**

### **Technology Stack**
- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript for full type safety
- **Database**: MySQL with 50+ tables
- **ORM**: Prisma for type-safe database operations
- **Storage**: AWS S3 for file management
- **Authentication**: JWT with role-based access control

### **API Endpoint Structure**
```
server/api/app/
├── worker/             # Worker-specific endpoints
│   ├── leave/         # Leave management
│   ├── timesheets/    # Timesheet operations
│   └── profile/       # Worker profile
├── supervisor/         # Manager endpoints
│   ├── projects/      # Project management
│   ├── workers/       # Team management
│   └── workplans/     # Work planning
├── chef/              # Chef/Boss endpoints
│   ├── customers/     # Customer management
│   ├── payroll/       # Payroll processing
│   ├── workers/       # Employee management
│   └── analytics/     # Business intelligence
└── shared/            # Common endpoints
    ├── auth/          # Authentication
    ├── notifications/ # Notification system
    └── upload/        # File upload
```

---

## 🔄 **Data Flow & State Management**

### **Application Initialization Flow**
1. **App Launch** → `KSR_Cranes_AppApp.swift`
2. **Firebase Setup** → Push notification registration
3. **Auth Check** → `AuthService` validates stored token
4. **State Init** → `AppStateManager` determines user role
5. **ViewModel Preload** → Role-specific ViewModels initialized
6. **UI Display** → `RoleBasedRootView` shows appropriate interface

### **Data Synchronization**
```
User Action → ViewModel → API Service → Backend
                ↓              ↓
            UI Update ← Combine Publisher ← Response
```

### **Global State Management**
- **AppStateManager**: Singleton managing app-wide state
- **NotificationCenter**: Auth state change broadcasts
- **@EnvironmentObject**: AppStateManager injection throughout app
- **@ObservedObject**: ViewModel reactive binding to views

---

## 🌍 **Internationalization & Localization**

### **Language Support**
- **Primary**: English (latest implementations)
- **Legacy**: Danish text in some older components
- **Date Formats**: Danish format (dd.MM.yyyy) throughout
- **Currency**: DKK (Danish Kroner) for payroll

### **Business Compliance**
- **Danish Labor Law**: Leave management compliance
- **Bi-weekly Payroll**: Danish standard payroll periods
- **Work Hours**: Danish overtime and weekend rate structures
- **Vacation System**: 25 days annual leave per Danish law

---

## 🚀 **Build & Development**

### **Development Commands**
```bash
# Build app via Xcode
xcodebuild -project "KSR Cranes App.xcodeproj" -scheme "KSR Cranes App" build

# Run tests
xcodebuild test -project "KSR Cranes App.xcodeproj" -scheme "KSR Cranes App"

# Build for simulator
xcodebuild -project "KSR Cranes App.xcodeproj" -scheme "KSR Cranes App" -destination 'platform=iOS Simulator,name=iPhone 16'
```

### **Recommended Development Environment**
- **Xcode**: Latest version with iOS 17+ deployment target
- **Simulator**: iPhone 16 for testing (as specified in CLAUDE.md)
- **Testing Framework**: Swift Testing (not XCTest)

---

## 📈 **Performance & Optimization**

### **Key Performance Features**
- **Preloaded ViewModels**: Eliminates loading states
- **Custom Image Caching**: Offline-first profile images
- **Async/Await**: Modern Swift concurrency throughout
- **Combine**: Reactive data binding for efficient UI updates
- **Memory Management**: Proper object lifecycle management

### **Network Optimization**
- **Request Debouncing**: Prevents excessive API calls
- **Offline Support**: Cached data for essential features
- **Error Recovery**: Automatic retry mechanisms
- **Token Refresh**: Seamless authentication renewal

---

## 🛡️ **Security & Privacy**

### **Data Protection**
- **Keychain Storage**: Secure token persistence
- **Role-Based Access**: UI and API endpoint restrictions
- **JWT Authentication**: Stateless authentication system
- **Input Validation**: Comprehensive client and server validation

### **Privacy Compliance**
- **Minimal Data Collection**: Only business-necessary data
- **Secure File Storage**: S3 with presigned URLs
- **Audit Trails**: Activity logging for compliance
- **Data Retention**: Configurable retention policies

---

This architecture supports KSR Cranes' complex business requirements while maintaining scalability, security, and user experience excellence across all roles and platforms.