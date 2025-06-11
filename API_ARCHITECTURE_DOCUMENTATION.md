# KSR Cranes App - API Services & Models Architecture Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [BaseAPIService - Core Foundation](#baseapiservice---core-foundation)
3. [Authentication System](#authentication-system)
4. [Role-Specific API Services](#role-specific-api-services)
5. [Data Models Architecture](#data-models-architecture)
6. [API Request/Response Patterns](#api-requestresponse-patterns)
7. [Error Handling Strategies](#error-handling-strategies)
8. [Combine Integration](#combine-integration)
9. [Best Practices & Guidelines](#best-practices--guidelines)

## Architecture Overview

The KSR Cranes app follows a layered architecture for API communication:

```
┌─────────────────────────────────────────────┐
│              UI Layer (Views)               │
├─────────────────────────────────────────────┤
│         ViewModels (ObservableObject)       │
├─────────────────────────────────────────────┤
│      Role-Specific API Services             │
│  (WorkerAPIService, ManagerAPIService,      │
│   ChefAPIService)                           │
├─────────────────────────────────────────────┤
│           BaseAPIService                     │
├─────────────────────────────────────────────┤
│    Authentication Layer (AuthService,        │
│    AuthInterceptor, KeychainService)        │
├─────────────────────────────────────────────┤
│         Network Layer (URLSession)          │
└─────────────────────────────────────────────┘
```

### Key Design Principles

1. **Role-Based Separation**: Each user role (Worker, Manager, Chef) has its own API service
2. **Inheritance Pattern**: All API services inherit from `BaseAPIService`
3. **Reactive Programming**: Uses Combine framework for asynchronous operations
4. **Automatic Authentication**: Token injection handled by base service
5. **Type Safety**: Strongly typed models with Codable protocol
6. **Error Handling**: Unified error handling with custom `APIError` enum

## BaseAPIService - Core Foundation

### Overview
`BaseAPIService` is the foundation class that provides core functionality for all API communication.

### Key Features

#### 1. Configuration
```swift
class BaseAPIService {
    let baseURL: String              // From Configuration.API.baseURL
    let session: URLSession          // Standard session (30s timeout)
    var authToken: String?           // Authentication token
    
    private lazy var longTimeoutSession: URLSession  // 60s timeout for uploads
}
```

#### 2. Session Management
- **Standard Session**: 30-second timeout for regular requests
- **Long Timeout Session**: 60-second timeout for file uploads and heavy operations
- **Automatic Retry**: Network timeout retry logic with configurable attempts

#### 3. Authentication Token Management
```swift
// Automatic token refresh from Keychain
func refreshTokenFromKeychain()

// Token injection into requests
func addAuthToken(to request: URLRequest) -> URLRequest

// Legacy compatibility method
func applyAuthToken(to request: inout URLRequest)
```

#### 4. Request Methods

**Generic Request Handler**:
```swift
func performRequest<T: Codable>(
    _ request: URLRequest,
    decoder: JSONDecoder = BaseAPIService.createAPIDecoder()
) -> AnyPublisher<T, APIError>
```

**Convenience Methods**:
```swift
// Standard request
func makeRequest<T: Encodable>(
    endpoint: String,
    method: String,
    body: T?,
    useLongTimeout: Bool = false
) -> AnyPublisher<Data, APIError>

// Request with retry logic
func makeRequestWithRetry<T: Encodable>(
    endpoint: String,
    method: String,
    body: T?,
    retryCount: Int = 2
) -> AnyPublisher<Data, APIError>
```

#### 5. Date Decoding Strategy
Custom date decoder handles multiple formats:
- API format: `"2025-06-01T14:53:05.000Z"`
- Without milliseconds: `"2025-06-01T14:53:05Z"`
- ISO8601 with fractional seconds
- Fallback to standard ISO8601

### Error Handling

```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknown
}
```

**Error Response Handling**:
- 200-299: Success, decode response
- 401: Authentication expired, post notification
- 400-499: Client error with parsed message
- 500-599: Server error with parsed message

## Authentication System

### Components

#### 1. AuthService (Singleton)
Central authentication manager handling:
- User login/logout
- Token persistence
- Role-based token distribution
- Authentication state management

**Key Methods**:
```swift
// Login with credentials
func login(email: String, password: String) -> AnyPublisher<AuthResponse, BaseAPIService.APIError>

// Check authentication status
var isLoggedIn: Bool

// Logout and cleanup
func logout()

// Get user information
func getEmployeeRole() -> String?
func getEmployeeId() -> String?
func getEmployeeName() -> String?
```

**Authentication Flow**:
1. User provides credentials
2. `AuthService.login()` sends POST to `/api/app-login`
3. Receives `AuthResponse` with token and user info
4. Stores token in Keychain (with simulator fallback)
5. Stores user data in UserDefaults
6. Sets token in appropriate API service based on role
7. Posts login notification

#### 2. KeychainService (Singleton)
Secure token storage with simulator fallback:

```swift
// Store token with automatic fallback
func storeToken(_ token: String) -> Bool

// Retrieve token from Keychain or fallback
func getToken() -> String?

// Delete token from all sources
func deleteToken() -> Bool
```

**Storage Strategy**:
- **Device**: Keychain primary, UserDefaults fallback
- **Simulator**: UserDefaults only (Keychain issues on simulator)
- **Automatic cleanup**: Removes fallback when Keychain works

#### 3. AuthInterceptor (Singleton)
Automatic token injection for all API requests:

```swift
// Intercept and add auth headers
func intercept(_ request: inout URLRequest)

// Handle 401 responses
func handle401Response(for request: URLRequest) -> AnyPublisher<Data, BaseAPIService.APIError>
```

**Token Selection Logic**:
1. Check user role from UserDefaults
2. Select appropriate API service based on role
3. Get token from service or fallback to Keychain
4. Add "Bearer {token}" header to request

### Authentication State Management

**Login State Verification**:
1. Check for token in Keychain
2. Verify user role exists
3. Ensure API service has token
4. Restore token to service if needed

**Token Expiry Handling**:
- 401 responses trigger `authTokenExpired` notification
- Forces logout and returns to login screen
- Cleans up all authentication data

## Role-Specific API Services

### WorkerAPIService

Handles all worker-specific functionality:

#### Core Features
- Task management
- Work hour entries
- Timesheet management
- Notifications
- Leave requests
- Announcements

#### Key Endpoints
```swift
// Tasks
func fetchTasks() -> AnyPublisher<[Task], APIError>

// Work Entries
func fetchWorkEntries(employeeId: String, weekStartDate: String, isDraft: Bool?) -> AnyPublisher<[WorkHourEntry], APIError>
func upsertWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<WorkEntryResponse, APIError>

// Timesheets
func fetchWorkerTimesheets(employeeId: String) -> AnyPublisher<[WorkerTimesheet], APIError>
func fetchWorkerTimesheetStats(employeeId: String) -> AnyPublisher<WorkerTimesheetStats, APIError>

// Notifications
func fetchNotifications(params: NotificationQueryParams) -> AnyPublisher<NotificationsResponse, APIError>
func markNotificationAsRead(id: Int) -> AnyPublisher<MarkAsReadResponse, APIError>

// Leave Management
func fetchLeaveRequests(employeeId: String) -> AnyPublisher<[LeaveRequest], APIError>
func submitLeaveRequest(_ request: CreateLeaveRequest) -> AnyPublisher<LeaveRequest, APIError>
```

### ManagerAPIService

Specialized for supervisor/manager operations:

#### Core Features
- Work entry approval/rejection
- Team management
- Project oversight
- Timesheet generation
- Signature management

#### Key Endpoints
```swift
// Supervisor Tasks
func fetchSupervisorTasks(supervisorId: Int) -> AnyPublisher<[Task], APIError>

// Work Entry Management
func fetchPendingWorkEntriesForManager(weekStartDate: String, isDraft: Bool?) -> AnyPublisher<[WorkHourEntry], APIError>
func updateWorkEntryStatus(entry: WorkHourEntry, confirmationStatus: String, rejectionReason: String?) -> AnyPublisher<WorkEntryResponse, APIError>

// Team Management
func fetchAssignedWorkers(supervisorId: Int) -> AnyPublisher<[Worker], APIError>
func fetchProjects() -> AnyPublisher<[Project], APIError>

// Timesheet Operations
func uploadPDF(pdfData: Data, employeeId: Int, taskId: Int, weekNumber: Int, year: Int, entryIds: [Int]) -> AnyPublisher<TimesheetUploadResponse, APIError>

// Signature
func saveSignature(_ signatureImage: UIImage) -> AnyPublisher<SignatureResponse, APIError>
```

### ChefAPIService

Complete business management functionality:

#### Core Features
- Dashboard statistics
- Customer management
- Project management
- Task creation/management
- Worker management
- Payroll operations
- Leave approval
- Business analytics

#### Key Endpoints
```swift
// Dashboard
func fetchChefDashboardStats() -> AnyPublisher<ChefDashboardStats, APIError>

// Customer Management
func fetchCustomers(search: String?, limit: Int?, offset: Int?, includeLogo: Bool) -> AnyPublisher<[Customer], APIError>
func createCustomer(_ customerData: CreateCustomerRequest) -> AnyPublisher<Customer, APIError>
func uploadCustomerLogo(customerId: Int, image: UIImage, fileName: String?) -> AnyPublisher<LogoUploadResponse, APIError>

// Project Management
func fetchProjects(includeInactive: Bool) -> AnyPublisher<[Project], APIError>
func createProject(_ project: CreateProjectRequest) -> AnyPublisher<CreateProjectResponse, APIError>

// Task Management
func createTask(_ task: CreateTaskRequest) -> AnyPublisher<ProjectTask, APIError>
func updateTask(taskId: Int, updates: UpdateTaskRequest) -> AnyPublisher<ProjectTask, APIError>

// Worker Management
func fetchWorkers(search: String?, employmentType: String?, status: String?) -> AnyPublisher<WorkersResponse, APIError>
func createWorker(_ worker: CreateWorkerRequest) -> AnyPublisher<WorkerForChef, APIError>

// Payroll
func fetchPayrollDashboardStats() -> AnyPublisher<PayrollDashboardStats, APIError>
func createPayrollBatch(_ request: CreatePayrollBatchRequest) -> AnyPublisher<PayrollBatch, APIError>
```

## Data Models Architecture

### Model Organization

Models are organized by domain and API service:

```
Core/Models/
├── AppNotification.swift      # Notification system models
├── NotificationResponse.swift # API response models
└── Announcement.swift         # Announcement models

Core/Services/API/
├── LeaveModels.swift         # Leave management models
├── Chef/
│   ├── PayrollModels.swift   # Payroll-specific models
│   ├── ProjectModels.swift   # Project/Task models
│   ├── CustomerModels.swift  # Customer models
│   └── WorkerModels.swift    # Worker management
├── Manager/
│   └── (Uses shared models)
└── Worker/
    └── (Uses shared models)
```

### Key Model Patterns

#### 1. Identifiable Protocol
All models conform to `Identifiable` for SwiftUI integration:
```swift
struct Task: Codable, Identifiable {
    let id = UUID()  // Client-side ID
    let task_id: Int // Server-side ID
}
```

#### 2. Custom Decoders
Models with complex parsing needs implement custom decoders:
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // Custom decoding logic
}
```

#### 3. Computed Properties
Models include computed properties for UI display:
```swift
var displayTitle: String {
    return title ?? type.displayName
}

var formattedDate: String {
    // Date formatting logic
}
```

#### 4. Nested Types
Related models are often nested for organization:
```swift
struct Project {
    struct Customer {
        let customer_id: Int
        let name: String
    }
    
    let customer: Customer?
}
```

### Common Model Examples

#### Notification Model
```swift
struct AppNotification: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let type: NotificationType
    let title: String?
    let message: String
    let isRead: Bool
    let createdAt: Date
    
    // Computed properties
    var displayTitle: String
    var iconName: String
    var requiresAction: Bool
}
```

#### Work Entry Model
```swift
struct WorkHourEntry: Codable, Identifiable {
    let entry_id: Int
    let employee_id: Int
    let task_id: Int
    let work_date: Date
    let start_time: Date?
    let end_time: Date?
    let pause_minutes: Int?
    let status: String?
    let confirmation_status: String?
    
    // Relations
    let tasks: Task?
    let employees: Employee?
}
```

#### Project Model
```swift
struct Project: Codable, Identifiable {
    let project_id: Int
    let title: String
    let description: String?
    let start_date: Date?
    let end_date: Date?
    let status: ProjectStatus?
    
    // Relations
    let customer: Customer?
    let tasks: [Task]
    
    // Computed
    var fullAddress: String?
}
```

## API Request/Response Patterns

### Request Patterns

#### 1. GET Requests (No Body)
```swift
func fetchData() -> AnyPublisher<[Model], APIError> {
    let endpoint = "/api/app/endpoint"
    return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
        .decode(type: [Model].self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
}
```

#### 2. POST/PUT Requests (With Body)
```swift
func createResource(_ data: CreateRequest) -> AnyPublisher<Model, APIError> {
    let endpoint = "/api/app/resource"
    return makeRequest(endpoint: endpoint, method: "POST", body: data)
        .decode(type: Model.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
}
```

#### 3. Multipart Requests (File Upload)
```swift
func uploadFile(data: Data, metadata: [String: String]) -> AnyPublisher<Response, APIError> {
    // Create multipart form data
    var request = URLRequest(url: URL(string: baseURL + endpoint)!)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    // Build multipart body
    var body = Data()
    // Add file data and metadata fields
    
    return session.dataTaskPublisher(for: request)
        // Handle response
}
```

### Response Patterns

#### 1. Simple Response
```swift
struct DeleteResponse: Codable {
    let success: Bool
    let message: String
}
```

#### 2. Data Response
```swift
struct CreateProjectResponse: Codable {
    let project: Project
    let message: String?
}
```

#### 3. Paginated Response
```swift
struct WorkersResponse: Codable {
    let workers: [Worker]
    let total: Int
    let page: Int
    let limit: Int
}
```

#### 4. Complex Nested Response
```swift
struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let pagination: PaginationInfo
    let unreadCount: Int
    let categories: [CategoryCount]
}
```

## Error Handling Strategies

### Error Types

1. **Network Errors**: Connection issues, timeouts
2. **Server Errors**: 4xx, 5xx responses
3. **Decoding Errors**: JSON parsing failures
4. **Authentication Errors**: Token expiry, unauthorized

### Error Handling Flow

```swift
return apiCall()
    .mapError { error in
        // Map to APIError
        if let apiError = error as? APIError {
            return apiError
        } else if let urlError = error as? URLError {
            return APIError.networkError(urlError)
        } else {
            return APIError.unknown
        }
    }
    .catch { error -> AnyPublisher<Model, APIError> in
        // Handle specific errors
        switch error {
        case .serverError(401, _):
            // Handle authentication failure
            NotificationCenter.default.post(name: .authTokenExpired, object: nil)
            return Fail(error: error).eraseToAnyPublisher()
        default:
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
```

### ViewModel Error Handling

```swift
func loadData() {
    isLoading = true
    errorMessage = nil
    
    apiService.fetchData()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            },
            receiveValue: { data in
                self.data = data
            }
        )
        .store(in: &cancellables)
}

private func handleError(_ error: APIError) {
    switch error {
    case .networkError:
        errorMessage = "Network connection issue. Please try again."
    case .serverError(_, let message):
        errorMessage = message
    case .decodingError:
        errorMessage = "Data format error. Please contact support."
    default:
        errorMessage = "An unexpected error occurred."
    }
}
```

## Combine Integration

### Publisher Patterns

#### 1. Basic API Call
```swift
apiService.fetchData()
    .receive(on: DispatchQueue.main)  // UI updates on main thread
    .sink(
        receiveCompletion: { /* Handle completion */ },
        receiveValue: { /* Handle data */ }
    )
    .store(in: &cancellables)
```

#### 2. Chained Calls
```swift
apiService.fetchProject(id: projectId)
    .flatMap { project in
        apiService.fetchTasksForProject(projectId: project.id)
    }
    .receive(on: DispatchQueue.main)
    .sink(/* ... */)
    .store(in: &cancellables)
```

#### 3. Parallel Calls
```swift
Publishers.Zip(
    apiService.fetchProjects(),
    apiService.fetchWorkers()
)
.receive(on: DispatchQueue.main)
.sink { projects, workers in
    // Handle both results
}
.store(in: &cancellables)
```

#### 4. Error Recovery
```swift
apiService.fetchData()
    .retry(2)  // Retry twice on failure
    .catch { error -> AnyPublisher<[Model], Never> in
        // Return empty array on error
        Just([]).eraseToAnyPublisher()
    }
    .sink { /* Always succeeds */ }
    .store(in: &cancellables)
```

### Cancellation Management

```swift
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        // Automatically cancels all subscriptions
        cancellables.forEach { $0.cancel() }
    }
}
```

## Best Practices & Guidelines

### 1. API Service Design

**DO:**
- Inherit from `BaseAPIService`
- Use singleton pattern for API services
- Return `AnyPublisher` for all methods
- Handle errors consistently
- Add debug logging in DEBUG builds

**DON'T:**
- Create multiple instances of API services
- Handle authentication manually
- Use completion handlers instead of Combine
- Ignore error cases

### 2. Model Design

**DO:**
- Conform to `Codable` and `Identifiable`
- Use `CodingKeys` for property mapping
- Implement custom decoders for complex types
- Add computed properties for UI display
- Document model properties

**DON'T:**
- Use force unwrapping
- Ignore optional properties from API
- Mix UI logic in models
- Use mutable properties unless necessary

### 3. Error Handling

**DO:**
- Map all errors to `APIError`
- Provide user-friendly error messages
- Handle authentication failures globally
- Log errors in DEBUG builds
- Implement retry logic for network failures

**DON'T:**
- Expose technical errors to users
- Ignore error states in UI
- Retry indefinitely
- Handle 401 errors locally

### 4. Performance

**DO:**
- Use appropriate timeout values
- Cancel subscriptions when not needed
- Cache responses when appropriate
- Use pagination for large data sets
- Minimize API calls

**DON'T:**
- Make redundant API calls
- Keep references to cancelled publishers
- Parse large JSON on main thread
- Ignore memory management

### 5. Security

**DO:**
- Store tokens in Keychain
- Clear sensitive data on logout
- Use HTTPS for all requests
- Validate server certificates
- Handle token expiry gracefully

**DON'T:**
- Log sensitive information
- Store tokens in UserDefaults (except simulator)
- Trust all certificates
- Expose API keys in code

### 6. Testing

**DO:**
- Mock API services for unit tests
- Test error scenarios
- Verify Combine pipelines
- Test model decoding
- Use dependency injection

**DON'T:**
- Make real API calls in tests
- Test implementation details
- Ignore edge cases
- Skip error testing

## Common Patterns & Solutions

### 1. Refreshing Data
```swift
func refreshData() {
    lastRefreshTime = Date()
    
    apiService.fetchData()
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveSubscription: { _ in self.isRefreshing = true },
            receiveCompletion: { _ in self.isRefreshing = false }
        )
        .sink(
            receiveCompletion: { /* Handle */ },
            receiveValue: { self.data = $0 }
        )
        .store(in: &cancellables)
}
```

### 2. Search with Debounce
```swift
@Published var searchText = ""

init() {
    $searchText
        .debounce(for: 0.3, scheduler: DispatchQueue.main)
        .removeDuplicates()
        .sink { [weak self] text in
            self?.performSearch(text)
        }
        .store(in: &cancellables)
}
```

### 3. Pagination
```swift
func loadMoreData() {
    guard !isLoadingMore, hasMoreData else { return }
    
    isLoadingMore = true
    let nextPage = currentPage + 1
    
    apiService.fetchData(page: nextPage, limit: pageSize)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { _ in self.isLoadingMore = false },
            receiveValue: { newData in
                self.data.append(contentsOf: newData)
                self.currentPage = nextPage
                self.hasMoreData = newData.count == self.pageSize
            }
        )
        .store(in: &cancellables)
}
```

### 4. Optimistic Updates
```swift
func updateResource(_ update: Update) {
    // Optimistically update UI
    let originalData = self.data
    self.data = updatedData
    
    apiService.updateResource(update)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    // Revert on failure
                    self.data = originalData
                    self.showError("Update failed")
                }
            },
            receiveValue: { /* Success */ }
        )
        .store(in: &cancellables)
}
```

## Debugging Tips

### 1. Enable Debug Logging
All API services include debug logging:
```swift
#if DEBUG
print("[APIService] Request: \(endpoint)")
print("[APIService] Response: \(response)")
#endif
```

### 2. Network Debugging
Use environment variable to enable verbose logging:
```swift
// In scheme settings
CFNETWORK_DIAGNOSTICS = 1
```

### 3. Combine Pipeline Debugging
```swift
apiCall()
    .handleEvents(
        receiveSubscription: { print("Started") },
        receiveOutput: { print("Received: \($0)") },
        receiveCompletion: { print("Completed: \($0)") }
    )
    .sink(/* ... */)
```

### 4. Authentication State Debugging
```swift
// Check authentication state
AuthService.shared.debugAuthenticationState()

// Test token manually
AuthService.shared.testTokenStorageManually()
```

## Migration Guide

### Adding New Endpoints

1. **Define Models**:
```swift
// In appropriate models file
struct NewFeature: Codable, Identifiable {
    let id: Int
    // Properties
}
```

2. **Add API Method**:
```swift
// In appropriate API service
func fetchNewFeature() -> AnyPublisher<NewFeature, APIError> {
    let endpoint = "/api/app/new-feature"
    return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
        .decode(type: NewFeature.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
}
```

3. **Update ViewModel**:
```swift
// In ViewModel
@Published var newFeature: NewFeature?

func loadNewFeature() {
    apiService.fetchNewFeature()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { /* Handle */ },
            receiveValue: { self.newFeature = $0 }
        )
        .store(in: &cancellables)
}
```

### Changing Authentication

If authentication mechanism changes:

1. Update `AuthService.login()`
2. Modify `AuthResponse` model
3. Update token storage in `KeychainService`
4. Adjust `AuthInterceptor.intercept()`
5. Test on both device and simulator

## Troubleshooting

### Common Issues

1. **Decoding Errors**
   - Check server response format
   - Verify property names match
   - Check date format handling
   - Look for null values

2. **Authentication Failures**
   - Verify token is stored
   - Check token format (Bearer prefix)
   - Ensure role-based service selection
   - Look for 401 responses

3. **Network Timeouts**
   - Use long timeout session for uploads
   - Implement retry logic
   - Check network conditions
   - Verify server availability

4. **Memory Leaks**
   - Cancel subscriptions properly
   - Use weak self in closures
   - Clear cancellables on deinit
   - Avoid retain cycles

This documentation provides a comprehensive guide to the API architecture in the KSR Cranes app. Follow these patterns and guidelines to maintain consistency and reliability across the application.