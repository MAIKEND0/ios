# KSR Cranes App - Feature Modules Documentation

## 🎯 **Overview**

The KSR Cranes app is structured around three distinct user roles, each with specialized features tailored to their responsibilities within the crane operator staffing business. This role-based architecture ensures security, usability, and efficient workflow management.

```
┌─────────────────────────────────────────────────────────────────┐
│                    KSR Cranes Business Model                    │
│        Crane Operator Staffing (NOT Equipment Rental)          │
└─────────────────────────────────────────────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
        ┌───────▼───────┐ ┌────▼────┐ ┌──────▼──────┐
        │    Worker      │ │ Manager │ │    Chef     │
        │  (Arbejder)    │ │(Byggldr)│ │   (Boss)    │
        └───────────────┘ └─────────┘ └─────────────┘
```

---

## 👷 **Worker (Arbejder) Role**

**Target Users**: Crane operators who perform hands-on work at client sites

### **Feature Structure** (`Features/Worker/`)

```
Worker/
├── 📊 Dashboard/              # Main overview screen
├── ⏰ WorkHours/              # Time tracking system  
├── 📋 Tasks/                  # Task management
├── 🏖️ Leave/                  # Leave request system
├── 👤 Profile/                # Personal profile
├── 📄 Timesheet/              # Historical reports
└── 🧠 ViewModels/             # Business logic layer
```

### **Core Features & Capabilities**

#### **1. Dashboard** (`Features/Worker/Dashboard/`)

**File**: `WorkerDashboardView.swift`
**ViewModel**: `WorkerDashboardViewModel.swift`

**Key Components:**
- `TimePeriodNavigation.swift` - Week/month navigation with date selection
- `WorkerDashboardComponents.swift` - Reusable dashboard widgets
- `WorkerDashboardSections.swift` - Main content sections

**Features:**
- **Time Period Navigation**: Navigate between weeks/months for work data
- **Work Hours Summary**: Overview of normal, overtime, and weekend hours
- **Upcoming Tasks**: Next assigned tasks with deadlines
- **Recent Activity**: Latest work entries and status updates
- **Quick Actions**: Direct access to common functions

**API Integration:**
```swift
// WorkerDashboardViewModel
func loadDashboardData() {
    // Fetches overview statistics
    workerAPIService.fetchDashboardStats()
    // Loads upcoming tasks
    workerAPIService.fetchUpcomingTasks()
    // Gets recent work entries
    workerAPIService.fetchRecentWorkEntries()
}
```

#### **2. Work Hours Management** (`Features/Worker/WorkHours/`)

**Primary Files:**
- `WorkerWorkHoursView.swift` - Main hours tracking interface
- `WorkHoursUtilities.swift` - Business logic helpers
- `WorkHourEntry.swift` & `WorkHourEntry+Extensions.swift` - Core data models

**ViewModel**: `WorkerWorkHoursViewModel.swift`

**Key Features:**
- **Daily Time Entry**: Log normal, overtime, and weekend hours
- **Project/Task Association**: Link hours to specific projects and tasks
- **Validation Rules**: 
  - Maximum 24 hours per day
  - Overtime calculation (>8 hours normal = overtime)
  - Weekend rate detection (Saturday/Sunday)
- **Status Tracking**: Draft → Submitted → Approved workflow
- **Bulk Operations**: Submit multiple days at once

**Business Logic:**
```swift
// WorkHourEntry model
struct WorkHourEntry: Codable, Identifiable {
    let normalHours: Double
    let overtimeHours: Double  
    let weekendHours: Double
    
    var totalHours: Double {
        return normalHours + overtimeHours + weekendHours
    }
    
    var dailyEarnings: Double {
        return (normalHours * normalRate) + 
               (overtimeHours * overtimeRate) + 
               (weekendHours * weekendRate)
    }
}
```

**Shared Components:**
- `EditableWorkEntry.swift` - Editable time entry form
- `WeeklyWorkEntryForm.swift` - Week-view time entry
- `WeeklyWorkEntryViewModel.swift` - Week management logic

#### **3. Task Management** (`Features/Worker/Tasks/`)

**Files:**
- `WorkerTasksView.swift` - Task list interface
- `WorkerTaskDetailView.swift` - Individual task details

**ViewModel**: `WorkerTasksViewModel.swift`

**Features:**
- **Task List**: View all assigned tasks with status indicators
- **Task Details**: Complete task information including:
  - Client information and location
  - Equipment requirements
  - Deadline and priority
  - Project context
  - Instructions and notes
- **Status Updates**: Mark tasks as started, in progress, completed
- **Time Logging**: Direct integration with work hours system

**Task Status Flow:**
```
Assigned → Started → In Progress → Completed
    ↓        ↓           ↓           ↓
  [Gray]  [Blue]     [Yellow]    [Green]
```

#### **4. Leave Management** (`Features/Worker/Leave/`)

**Primary Files:**
- `WorkerLeaveView.swift` - Main leave interface with tab navigation
- `CreateLeaveRequestView.swift` - Leave request form
- `WorkerLeaveCalendarView.swift` - Calendar visualization
- `LeaveRequestFiltersView.swift` - Advanced filtering

**ViewModel**: `WorkerLeaveViewModel.swift`

**Features:**
- **Leave Request Types**:
  - Vacation (Ferie) - 25 days annual, 14-day advance notice
  - Sick Leave (Sygemeldt) - Unlimited, immediate/emergency support
  - Personal Days (Personlige dage) - 5 days annual, 24-hour notice
  - Parental Leave (Forældreorlov) - Extended family leave
  - Compensatory Time (Afspadsering) - Overtime compensation

- **Request Management**:
  - Create new requests with date picker and validation
  - Edit pending requests
  - Cancel requests (with manager approval for approved leave)
  - View request history with status tracking

- **Balance Tracking**:
  - Real-time vacation day balance (25 days + carryover)
  - Personal day usage tracking
  - Sick day history (tracking only, unlimited)

- **Calendar Integration**:
  - Visual calendar showing approved leave periods
  - Color-coded leave types
  - Danish holiday integration
  - Weekend highlighting (non-work days)

**Business Rules:**
```swift
// Leave validation in WorkerLeaveViewModel
func validateLeaveRequest() -> [String] {
    var errors: [String] = []
    
    // Vacation requires 14 days advance notice
    if leaveType == .vacation && startDate < Date().addingTimeInterval(14 * 24 * 60 * 60) {
        errors.append("Vacation requires 14 days advance notice")
    }
    
    // Check vacation balance
    if leaveType == .vacation && workDays > availableVacationDays {
        errors.append("Insufficient vacation days")
    }
    
    return errors
}
```

#### **5. Profile Management** (`Features/Worker/Profile/`)

**Files:**
- `WorkerProfileView.swift` - Profile display and editing
- `WorkerkProfileComponents.swift` - Reusable profile components

**ViewModel**: `WorkerProfileViewModel.swift`

**Features:**
- **Personal Information**: Name, email, phone, address
- **Employment Details**: Role, hire date, status
- **Rate Information**: Hourly rates (normal, overtime, weekend)
- **Profile Image**: Upload and manage profile pictures
- **Certification Status**: View required certifications
- **Contact Information**: Emergency contacts and preferences

### **Worker Navigation Structure**

```swift
// MainTabView for Worker role
TabView {
    WorkerDashboardView()
        .tabItem { Label("Dashboard", systemImage: "house") }
    
    WorkerWorkHoursView()
        .tabItem { Label("Work Hours", systemImage: "clock") }
    
    WorkerTasksView()
        .tabItem { Label("Tasks", systemImage: "list.bullet") }
    
    WorkerLeaveView()
        .tabItem { Label("Leave", systemImage: "calendar") }
    
    WorkerProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
```

---

## 👔 **Manager (Byggeleder) Role**

**Target Users**: Project managers and supervisors who oversee workers and projects

### **Feature Structure** (`Features/Manager/`)

```
Manager/
├── 📊 Dashboard/              # Manager overview
├── 🏗️ Projects/               # Project management
├── 👥 Workers/                # Team oversight
├── 📅 Workplan/               # Schedule planning
├── 📄 Timesheet/              # Approval workflows
├── ✍️ Signature/              # Digital signatures
└── 🧠 ViewModels/             # Business logic
```

### **Core Features & Capabilities**

#### **1. Manager Dashboard** (`Features/Manager/Dashboard/`)

**File**: `ManagerDashboardView.swift`
**ViewModel**: `ManagerDashboardViewModel.swift`

**Components:**
- `ManagerDashboardComponents.swift` - Dashboard widgets
- `ManagerDashboardSections.swift` - Content organization

**Features:**
- **Pending Approvals**: Outstanding timesheet and leave approvals
- **Team Overview**: Worker status and availability
- **Project Progress**: Current project status and deadlines
- **Alerts & Notifications**: Important items requiring attention
- **Quick Actions**: Fast access to common manager functions

#### **2. Project Management** (`Features/Manager/Projects/`)

**File**: `ManagerProjectsView.swift`
**ViewModel**: `ManagerProjectsViewModel.swift`

**Features:**
- **Project Oversight**: View all assigned projects
- **Worker Assignments**: Manage team member assignments to projects
- **Progress Tracking**: Monitor project milestones and deadlines
- **Resource Allocation**: Optimize worker assignments
- **Client Communication**: Project status updates

#### **3. Worker Management** (`Features/Manager/Workers/`)

**Files:**
- `ManagerWorkersView.swift` - Team member interface
- `TabButton.swift` - Tab navigation component

**ViewModel**: `ManagerWorkersViewModel.swift`

**Features:**
- **Team Overview**: View all direct reports
- **Worker Profiles**: Access team member information
- **Assignment Management**: Assign workers to projects and tasks
- **Performance Monitoring**: Track worker productivity
- **Availability Planning**: Manage team schedules

#### **4. Work Plan Management** (`Features/Manager/Workplan/`)

**Primary Files:**
- `ManagerWorkPlansView.swift` - Work plan overview
- `WorkPlanCreatorView.swift` - Create new work plans
- `EditWorkPlanView.swift` - Modify existing plans
- `WorkPlanPreviewView.swift` - Preview before publishing

**Supporting Components:**
- `WorkPlanComponents.swift` - Reusable UI components
- `ToastView.swift` - Success/error notifications

**ViewModels:**
- `ManagerWorkPlansViewModel.swift` - Work plan management
- `CreateWorkPlanViewModel.swift` - Creation workflow
- `EditWorkPlanViewModel.swift` - Editing workflow

**Features:**
- **Schedule Creation**: Plan worker assignments and schedules
- **Resource Planning**: Optimize worker allocation
- **Template Management**: Save and reuse common plans
- **Conflict Detection**: Identify scheduling conflicts
- **Team Communication**: Share plans with workers

**Work Plan Workflow:**
```
Create Plan → Review → Assign Workers → Publish → Monitor
     ↓          ↓          ↓            ↓         ↓
  [Draft]   [Review]   [Ready]     [Active]  [Complete]
```

#### **5. Timesheet Management** (`Features/Manager/Timesheet/`)

**Files:**
- `TimesheetReportsView.swift` - Timesheet overview and approval
- `TimesheetReceiptView.swift` - Digital receipt generation

**ViewModel**: `TimesheetReportsViewModel.swift`

**Features:**
- **Approval Queue**: Review and approve worker timesheets
- **Batch Processing**: Approve multiple timesheets at once
- **Validation Checks**: Verify hours and project assignments
- **Rejection Handling**: Send feedback for corrections
- **Receipt Generation**: Create approval confirmations

#### **6. Digital Signature System** (`Features/Manager/Signature/`)

**Files:**
- `SignatureModalView.swift` - Signature capture interface
- `SignatureModalViewController.swift` - UIKit integration for signature pad

**Features:**
- **Digital Signatures**: Capture manager signatures for approvals
- **Document Signing**: Sign timesheets, work plans, and reports
- **Signature Storage**: Secure signature image storage
- **Audit Trail**: Track who signed what and when

### **Manager Navigation Structure**

```swift
TabView {
    ManagerDashboardView()
        .tabItem { Label("Dashboard", systemImage: "house") }
    
    ManagerProjectsView()
        .tabItem { Label("Projects", systemImage: "folder") }
    
    ManagerWorkersView()
        .tabItem { Label("Team", systemImage: "person.3") }
    
    ManagerWorkPlansView()
        .tabItem { Label("Work Plans", systemImage: "calendar") }
    
    TimesheetReportsView()
        .tabItem { Label("Timesheets", systemImage: "doc.text") }
}
```

---

## 🏢 **Chef/Boss Role**

**Target Users**: Business owners and executives with full system access

### **Feature Structure** (`Features/Chef/`)

```
Chef/
├── 📊 Dashboard/              # Executive overview
├── 🏢 Customers/              # Client management
├── 🏗️ Projects/               # Full project control
├── 👥 Workers/                # Employee management
├── 🏖️ Leave/                  # Leave oversight
├── 💰 Payroll/                # Payroll processing
├── 📅 ManagementCalendar/     # Resource planning
├── 📋 Tasks/                  # Task management
└── 🧠 ViewModels/             # Business logic
```

### **Core Features & Capabilities**

#### **1. Executive Dashboard** (`Features/Chef/Dashboard/`)

**Files:**
- `ChefDashboardView.swift` - Executive overview
- `ChefDashboardStats.swift` - Statistics components

**ViewModel**: `ChefDashboardViewModel.swift`

**Features:**
- **Business Metrics**: Revenue, utilization, profit margins
- **Quick Actions**: Fast access to critical functions
- **Alert Center**: Important business alerts and notifications
- **Performance Indicators**: Key performance metrics (KPIs)
- **Resource Overview**: Worker availability and utilization

#### **2. Customer Management** (`Features/Chef/Customers/`)

**Primary Files:**
- `CustomersListView.swift` - Customer directory
- `CustomerDetailView.swift` - Individual customer details
- `CreateCustomerView.swift` - New customer onboarding
- `EditCustomerView.swift` - Customer information updates

**Supporting Components:**
- `CustomersFiltersSheet.swift` - Advanced filtering
- `CustomerLogoPickerView.swift` - Logo management
- `CustomerLogoErrorHandler.swift` - Logo upload error handling
- `SharedUIComponents.swift` - Reusable components

**ViewModels:**
- `CustomersViewModel.swift` - Customer list management
- `CustomerDetailViewModel.swift` - Individual customer logic
- `CreateCustomerViewModel.swift` - Customer creation
- `EditCustomerViewModel.swift` - Customer editing

**Models:**
- `CustomerModels.swift` - Customer data structures

**Features:**
- **Customer Directory**: Complete client database
- **Contact Management**: Multiple contact points per customer
- **Project History**: All projects for each customer
- **Billing Information**: Payment terms and billing addresses
- **Document Storage**: Contracts and agreements
- **Logo Management**: Customer branding and identity

**Customer Management Workflow:**
```
Lead → Prospect → Active Customer → Project Assignment → Billing → Renewal
  ↓       ↓            ↓               ↓                ↓        ↓
[Gray] [Yellow]     [Green]        [Blue]          [Orange] [Purple]
```

#### **3. Project Management** (`Features/Chef/Projects/`)

**Files:**
- `ChefProjectDetailView.swift` - Complete project overview
- `ChefCreateProjectView.swift` - Project creation
- `ChefWorkerPickerView.swift` - Worker assignment interface

**ViewModels:**
- `ChefProjectViewModels.swift` - Project management logic

**Features:**
- **Full Project Lifecycle**: From creation to completion
- **Resource Allocation**: Assign workers and equipment
- **Budget Management**: Track costs and profitability
- **Timeline Management**: Milestones and deadlines
- **Client Communication**: Project status updates
- **Billing Integration**: Connect projects to invoicing

#### **4. Employee Management** (`Features/Chef/Workers/`)

**Complete CRUD System:**
- `ChefWorkersView.swift` - Employee directory
- `AddWorkerView.swift` - New employee onboarding
- `EditWorkerView.swift` - Employee information updates
- `WorkerDetailView.swift` - Complete employee profiles

**Document Management:**
- `WorkerDocumentManagerView.swift` - Document handling
- `DocumentUploadSheet.swift` - File uploads
- `DocumentViewerSheet.swift` - Document viewing
- `DocumentBulkActionsSheet.swift` - Bulk operations

**ViewModels:**
- `ChefWorkersViewModel.swift` - Employee list management
- `AddWorkerViewModel.swift` - Employee creation
- `EditWorkerViewModel.swift` - Employee editing
- `WorkerDocumentViewModel.swift` - Document management

**Features:**
- **Complete Employee Lifecycle**: Hire to termination
- **Certification Tracking**: Monitor required certifications
- **Document Management**: Contracts, certificates, photos
- **Rate Management**: Hourly rates and adjustments
- **Performance Tracking**: Employee metrics and evaluations
- **Profile Pictures**: Employee photo management

#### **5. Leave Management** (`Features/Chef/Leave/`)

**File**: `ChefLeaveManagementView.swift`
**ViewModel**: `ChefLeaveManagementViewModel.swift`

**Features:**
- **Company-wide Leave Overview**: All employee leave requests
- **Approval/Rejection Authority**: Final leave decisions
- **Team Calendar**: Visual representation of team availability
- **Leave Analytics**: Usage patterns and trends
- **Policy Management**: Configure leave policies
- **Conflict Resolution**: Handle overlapping requests

**Leave Management Dashboard:**
```
Pending Requests → Review → Approve/Reject → Team Calendar Update
       ↓            ↓           ↓                    ↓
   [Yellow]     [Blue]      [Green/Red]          [Updated]
```

#### **6. Payroll System** (`Features/Chef/Payroll/`)

**Primary Files:**
- `PayrollDashboardView.swift` - Payroll overview
- `PayrollBatchesView.swift` - Batch management
- `CreateBatchView.swift` - Create payroll batches
- `BatchDetailView.swift` - Individual batch details

**Supporting Components:**
- `PayrollActivityView.swift` - Recent activity
- `PayrollReportsView.swift` - Payroll reports
- `PendingHoursView.swift` - Hours awaiting processing

**ViewModels:**
- `PayrollDashboardViewModel.swift` - Dashboard logic
- `PayrollBatchesViewModel.swift` - Batch management
- `CreateBatchViewModel.swift` - Batch creation
- `BatchDetailViewModel.swift` - Batch details
- `PendingHoursViewModel.swift` - Pending hours logic

**Features:**
- **Bi-weekly Processing**: Danish standard payroll periods
- **Batch Management**: Group employees for processing
- **Hours Validation**: Verify submitted time entries
- **Rate Calculations**: Normal, overtime, weekend rates
- **Export Capabilities**: Integration with external payroll systems
- **Audit Trails**: Complete processing history

**Payroll Processing Workflow:**
```
Collect Hours → Validate → Create Batch → Review → Process → Export
      ↓           ↓           ↓          ↓         ↓        ↓
   [Pending]  [Validated]  [Draft]   [Ready]  [Processed] [Exported]
```

#### **7. Task Management** (`Features/Chef/Tasks/`)

**Files:**
- `ChefTaskDetailView.swift` - Complete task management
- `ChefTaskManagementViews.swift` - Task interfaces
- `CertificateSelectionView.swift` - Certification requirements
- `TaskCertificateSelectionView.swift` - Task-specific certificates

**ViewModels:**
- `CreateTaskViewModel.swift` - Task creation
- `EditTaskViewModel.swift` - Task modification

**Features:**
- **Task Creation & Assignment**: Create and assign tasks to workers
- **Equipment Requirements**: Specify crane types and models
- **Certification Validation**: Ensure workers have required certificates
- **Progress Monitoring**: Track task completion
- **Resource Planning**: Optimize task assignments

#### **8. Management Calendar** (`Features/Chef/ManagementCalendar/`)

**Primary Files:**
- `ChefManagementCalendarView.swift` - Resource planning calendar
- `MobileManagementCalendarView.swift` - Mobile-optimized view
- `MobileMonthView.swift` - Month calendar view
- `MobileWeekView.swift` - Week calendar view
- `MobileTeamView.swift` - Team availability view
- `MobileEventDetailSheet.swift` - Event details

**Export & Reporting:**
- `CalendarCSVGenerator.swift` - CSV export functionality
- `CalendarExcelGenerator.swift` - Excel export (planned)
- `SimplePDFGenerator.swift` - PDF report generation
- `PDFPreviewView.swift` - PDF preview interface

**ViewModel**: `ChefManagementCalendarViewModel.swift`

**Features:**
- **Resource Planning**: Visualize worker assignments and availability
- **Conflict Detection**: Identify scheduling conflicts
- **Multi-view Modes**: Month, week, and team views
- **Export Capabilities**: PDF, CSV, and Excel exports
- **Mobile Optimization**: Touch-friendly interface
- **Real-time Updates**: Live calendar updates

### **Chef Navigation Structure**

```swift
TabView {
    ChefDashboardView()
        .tabItem { Label("Dashboard", systemImage: "house") }
    
    CustomersListView()
        .tabItem { Label("Customers", systemImage: "building.2") }
    
    ChefProjectsView()
        .tabItem { Label("Projects", systemImage: "folder") }
    
    ChefWorkersView()
        .tabItem { Label("Workers", systemImage: "person.3") }
    
    ChefLeaveManagementView()
        .tabItem { Label("Leave", systemImage: "calendar") }
    
    PayrollDashboardView()
        .tabItem { Label("Payroll", systemImage: "dollarsign.circle") }
    
    ChefManagementCalendarView()
        .tabItem { Label("Calendar", systemImage: "calendar.badge.clock") }
}
```

---

## 🔄 **Cross-Role Integration**

### **Data Flow Between Roles**

```
Worker Actions → Manager Review → Chef Oversight
     ↓               ↓               ↓
Time Entries → Approval Queue → Payroll Processing
Leave Requests → Manager Approval → Chef Analytics
Task Updates → Progress Tracking → Resource Planning
```

### **Shared Components**

#### **1. Navigation System** (`UI/Views/Navigation/`)
- `RoleBasedRootView.swift` - Role-based navigation router
- `MainTabView.swift` - Common tab structure
- `ManagerMainTabView.swift` - Manager-specific tabs

#### **2. Authentication Flow**
- `LoginView.swift` & `LoginViewModel.swift` - Shared login interface
- `SplashScreenView.swift` - App startup screen

#### **3. Profile Management** (`UI/Views/Profile/`)
- `ProfileView.swift` - Shared profile components
- Profile picture caching system

### **API Integration Points**

Each role connects to specific API endpoints:

```swift
// Worker Role
WorkerAPIService → /api/app/worker/*
WorkerLeaveAPIService → /api/app/worker/leave/*

// Manager Role  
ManagerAPIService → /api/app/supervisor/*
SupervisorProfileApiService → /api/app/supervisor/profile/*

// Chef Role
ChefAPIService → /api/app/chef/*
PayrollAPIService → /api/app/chef/payroll/*
ChefWorkersAPIService → /api/app/chef/workers/*
```

---

## 🏗️ **Technical Architecture**

### **MVVM Pattern Implementation**

Each feature follows consistent MVVM architecture:

```swift
// View Layer (SwiftUI)
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    
    var body: some View {
        // UI Implementation
    }
}

// ViewModel Layer (ObservableObject)
class FeatureViewModel: ObservableObject {
    @Published var data: [Model] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() {
        // API call with Combine
    }
}

// Model Layer (Codable)
struct Model: Codable, Identifiable {
    let id: Int
    // Other properties
}
```

### **State Management**

#### **AppStateManager Integration**
```swift
// Central state coordination
class AppStateManager: ObservableObject {
    // Role-specific ViewModels
    @Published var workerDashboardViewModel: WorkerDashboardViewModel?
    @Published var managerDashboardViewModel: ManagerDashboardViewModel?
    @Published var chefDashboardViewModel: ChefDashboardViewModel?
    
    func initializeForRole(_ role: String) {
        switch role {
        case "arbejder":
            initializeWorkerViewModels()
        case "byggeleder": 
            initializeManagerViewModels()
        case "chef":
            initializeChefViewModels()
        }
    }
}
```

### **Navigation Patterns**

#### **Role-Based Navigation**
```swift
struct RoleBasedRootView: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            switch appStateManager.currentUserRole {
            case "arbejder":
                WorkerTabView()
            case "byggeleder":
                ManagerTabView()
            case "chef":
                ChefTabView()
            default:
                LoginView()
            }
        }
    }
}
```

### **UI/UX Consistency**

#### **Design System**
- **Color Scheme**: KSR Cranes branded colors throughout
- **Component Library**: Shared UI components in `Core/Components/`
- **Typography**: Consistent font sizing and weights
- **Icons**: System icons with role-specific customizations

#### **Responsive Design**
- **iPad Support**: Enhanced layouts for larger screens
- **Landscape Mode**: Optimized horizontal layouts
- **Accessibility**: VoiceOver and Dynamic Type support

### **Performance Optimizations**

#### **Preloaded ViewModels**
- ViewModels initialized during app startup
- Data ready before views appear
- Eliminates loading states in primary interface

#### **Efficient Data Loading**
- Pagination for large datasets
- Caching for frequently accessed data
- Background refresh with pull-to-refresh

#### **Memory Management**
- Proper Combine cancellable management
- Weak references in closures
- Efficient image caching

---

## 🚀 **Best Practices & Guidelines**

### **Feature Development**

1. **Follow MVVM Pattern**
   - Clear separation between View, ViewModel, and Model
   - Use `@Published` properties for reactive UI updates
   - Handle all business logic in ViewModels

2. **API Integration**
   - Use role-specific API services
   - Implement proper error handling
   - Follow Combine publisher patterns

3. **UI Development**
   - Maintain design consistency across roles
   - Use shared components when appropriate
   - Implement proper accessibility features

4. **Testing Strategy**
   - Unit tests for ViewModels
   - Integration tests for API services
   - UI tests for critical user journeys

### **Security Considerations**

1. **Role-Based Access**
   - Complete UI isolation between roles
   - API endpoint restrictions by role
   - No data leakage between roles

2. **Data Protection**
   - Secure storage of sensitive information
   - Proper authentication token handling
   - Input validation and sanitization

### **Future Development**

#### **Planned Enhancements**
- Enhanced analytics and reporting
- Real-time notifications and updates
- Offline capability improvements
- Advanced scheduling algorithms

#### **Scalability Considerations**
- Modular feature architecture
- Plugin-based extensibility
- Performance monitoring
- Database optimization

This comprehensive feature documentation provides a complete understanding of each role's capabilities and how they integrate to support KSR Cranes' business operations.