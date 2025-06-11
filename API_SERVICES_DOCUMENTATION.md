# KSR Cranes App - API Services & Models Documentation

## 🎯 **Architecture Overview**

The KSR Cranes app uses a layered architecture with clear separation between UI, business logic, and data access layers. The API services layer provides the bridge between ViewModels and the backend server.

```
┌──────────────────────────┐
│      SwiftUI Views       │ ← UI Layer
└──────────────────────────┘
             ↓ @ObservedObject
┌──────────────────────────┐
│       ViewModels         │ ← Business Logic Layer
└──────────────────────────┘
             ↓ Method Calls
┌──────────────────────────┐
│      API Services        │ ← Data Access Layer
│   (Role-Specific)        │
└──────────────────────────┘
             ↓ Combine Publishers
┌──────────────────────────┐
│     BaseAPIService       │ ← Network Layer
└──────────────────────────┘
             ↓ HTTP Requests
┌──────────────────────────┐
│     Backend Server       │ ← Next.js API
│     (MySQL Database)     │
└──────────────────────────┘
```

### **Key Design Principles**

1. **Role-Based Separation**: Each user role has dedicated API services
2. **Reactive Programming**: Combine publishers for async data flow
3. **Type Safety**: Codable models with compile-time validation
4. **Error Resilience**: Comprehensive error handling at all layers
5. **Authentication Integration**: Automatic token injection
6. **Testability**: Protocol-based design for easy mocking

---

## 🏗️ **BaseAPIService Architecture**

### **Core Implementation** (`Core/Services/API/BaseAPIService.swift`)

```swift
class BaseAPIService {
    static let shared = BaseAPIService()
    
    // Two session types for different timeout requirements
    private let session: URLSession           // 30s timeout
    private let longTimeoutSession: URLSession  // 300s timeout
    
    // Base URL configuration
    private let baseURL = Configuration.apiBaseURL // "https://ksrcranes.dk"
}
```

### **Key Features**

#### **1. Session Management**
- **Standard Session**: 30-second timeout for regular operations
- **Long Timeout Session**: 5-minute timeout for file uploads and heavy operations
- Custom configuration with retry policies

#### **2. Authentication Integration**
- Automatic token injection via `AuthInterceptor`
- Token refresh handling
- Logout on authentication failures

#### **3. Request Methods**

```swift
// GET Requests
func get<T: Codable>(
    endpoint: String,
    responseType: T.Type,
    timeout: TimeInterval? = nil
) -> AnyPublisher<T, APIError>

// POST/PUT Requests  
func post<T: Codable, U: Codable>(
    endpoint: String,
    body: T,
    responseType: U.Type,
    timeout: TimeInterval? = nil
) -> AnyPublisher<U, APIError>

// Multipart File Upload
func uploadMultipart<T: Codable>(
    endpoint: String,
    fields: [String: String],
    files: [MultipartFile],
    responseType: T.Type
) -> AnyPublisher<T, APIError>
```

#### **4. Custom Date Decoding**
```swift
private static func createJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
}
```

#### **5. Error Handling**
```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case httpError(Int, String?)
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .authenticationError:
            return "Authentication failed. Please log in again."
        case .httpError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        // ... other cases
        }
    }
}
```

---

## 🔐 **Authentication System**

### **AuthService** (`Core/Services/AuthService.swift`)

Central authentication manager providing:

```swift
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var employeeRole: String?
    
    // Core authentication methods
    func login(email: String, password: String) -> AnyPublisher<LoginResponse, APIError>
    func logout()
    func getCurrentUser() -> EmployeeData?
    func getAuthToken() -> String?
    
    // Session management
    func validateStoredToken() -> Bool
    func refreshAuthState()
}
```

**Key Features:**
- Reactive authentication state with `@Published` properties
- Automatic token validation on app launch
- Role-based user data management
- Logout notification broadcasting

### **KeychainService** (`Core/Services/KeychainService.swift`)

Secure token storage with simulator support:

```swift
class KeychainService {
    static let shared = KeychainService()
    
    func store(key: String, value: String) -> Bool
    func retrieve(key: String) -> String?
    func delete(key: String) -> Bool
    
    // Special handling for simulators
    private func isSimulator() -> Bool
    private func storeInUserDefaults(key: String, value: String)
}
```

### **AuthInterceptor** (`Core/Services/AuthInterceptor.swift`)

Automatic token injection for all API requests:

```swift
class AuthInterceptor {
    static func addAuthHeaders(to request: inout URLRequest) {
        if let token = AuthService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
```

### **Authentication Flow**

```
User Login → AuthService.login()
     ↓
Token Storage → KeychainService.store()
     ↓
State Update → @Published isAuthenticated = true
     ↓
API Requests → AuthInterceptor.addAuthHeaders()
     ↓
Backend Validation → JWT verification
```

---

## 🎭 **Role-Specific API Services**

### **WorkerAPIService** (`Core/Services/API/Worker/WorkerAPIService.swift`)

Handles all worker-specific operations:

#### **Key Methods:**
```swift
// Task Management
func fetchTasks() -> AnyPublisher<[WorkerTask], BaseAPIService.APIError>
func fetchTaskDetail(taskId: Int) -> AnyPublisher<WorkerTaskDetail, BaseAPIService.APIError>

// Work Entry Management  
func fetchWorkEntries(startDate: String, endDate: String) -> AnyPublisher<[WorkEntry], BaseAPIService.APIError>
func submitWorkEntry(_ entry: WorkEntry) -> AnyPublisher<WorkEntryResponse, BaseAPIService.APIError>

// Timesheet Operations
func fetchTimesheets() -> AnyPublisher<TimesheetResponse, BaseAPIService.APIError>
func submitTimesheet(entries: [WorkEntry]) -> AnyPublisher<TimesheetSubmissionResponse, BaseAPIService.APIError>

// Notifications
func fetchNotifications() -> AnyPublisher<NotificationsResponse, BaseAPIService.APIError>
func markNotificationAsRead(notificationId: Int) -> AnyPublisher<MessageResponse, BaseAPIService.APIError>

// Leave Management
func submitLeaveRequest(_ request: CreateLeaveRequest) -> AnyPublisher<LeaveRequestResponse, BaseAPIService.APIError>
func fetchLeaveBalance() -> AnyPublisher<LeaveBalanceResponse, BaseAPIService.APIError>
```

#### **Example Implementation:**
```swift
func fetchTasks() -> AnyPublisher<[WorkerTask], BaseAPIService.APIError> {
    BaseAPIService.shared.get(
        endpoint: "/api/app/tasks", 
        responseType: [WorkerTask].self
    )
}

func submitWorkEntry(_ entry: WorkEntry) -> AnyPublisher<WorkEntryResponse, BaseAPIService.APIError> {
    BaseAPIService.shared.post(
        endpoint: "/api/app/work-entries",
        body: entry,
        responseType: WorkEntryResponse.self
    )
}
```

### **ManagerAPIService** (`Core/Services/API/Manager/ManagerAPIService.swift`)

Manager-specific functionality:

```swift
// Work Entry Approval
func fetchPendingWorkEntries() -> AnyPublisher<[WorkEntry], BaseAPIService.APIError>
func approveWorkEntry(entryId: Int) -> AnyPublisher<MessageResponse, BaseAPIService.APIError>

// Team Management
func fetchTeamMembers() -> AnyPublisher<[TeamMember], BaseAPIService.APIError>
func updateTeamMemberStatus(memberId: Int, status: String) -> AnyPublisher<MessageResponse, BaseAPIService.APIError>

// Signature Management
func submitSignature(signatureData: Data) -> AnyPublisher<SignatureResponse, BaseAPIService.APIError>
```

### **ChefAPIService** (Multiple specialized services)

#### **Chef Dashboard** (`Core/Services/API/Chef/ChefAPIService.swift`)
```swift
func fetchDashboardStats() -> AnyPublisher<ChefDashboardStats, BaseAPIService.APIError>
func fetchBusinessInsights() -> AnyPublisher<BusinessInsights, BaseAPIService.APIError>
```

#### **Customer Management** (`Features/Chef/Customers/`)
```swift
func fetchCustomers() -> AnyPublisher<CustomersResponse, BaseAPIService.APIError>
func createCustomer(_ customer: CreateCustomerRequest) -> AnyPublisher<Customer, BaseAPIService.APIError>
func updateCustomer(_ customer: UpdateCustomerRequest) -> AnyPublisher<Customer, BaseAPIService.APIError>
```

#### **Payroll Management** (`Core/Services/API/Chef/PayrollAPIService.swift`)
```swift
func fetchPayrollStats() -> AnyPublisher<PayrollDashboardStats, BaseAPIService.APIError>
func createPayrollBatch(_ batch: CreatePayrollBatchRequest) -> AnyPublisher<PayrollBatch, BaseAPIService.APIError>
func fetchAvailableWorkEntries() -> AnyPublisher<[WorkEntryForReview], BaseAPIService.APIError>
```

#### **Worker Management** (`Core/Services/API/Chef/ChefWorkersAPIService.swift`)
```swift
func fetchWorkers() -> AnyPublisher<WorkersResponse, BaseAPIService.APIError>
func createWorker(_ worker: CreateWorkerRequest) -> AnyPublisher<WorkerForChef, BaseAPIService.APIError>
func updateWorker(_ worker: UpdateWorkerRequest) -> AnyPublisher<WorkerForChef, BaseAPIService.APIError>
func deleteWorker(workerId: Int) -> AnyPublisher<MessageResponse, BaseAPIService.APIError>
```

---

## 📋 **Data Models Architecture**

### **Model Organization**

Models are organized by domain and functionality:

```
Core/Models/
├── AppNotification.swift       # Global notifications
├── Announcement.swift          # System announcements
└── NotificationsView.swift     # Notification display models

Core/Services/API/
├── LeaveModels.swift          # Leave management models
├── Chef/
│   ├── PayrollModels.swift    # Payroll system models
│   ├── ProjectModels.swift    # Project management models
│   ├── ChefWorkersModels.swift # Worker management models
│   └── CertificateModels.swift # Certification models
├── Manager/
│   └── [Manager-specific models]
└── Worker/
    └── [Worker-specific models]
```

### **Key Model Patterns**

#### **1. Identifiable Protocol**
```swift
struct WorkerTask: Codable, Identifiable {
    let id: Int
    let task_id: Int  // Server field name
    let title: String
    let description: String?
    let deadline: Date?
    let status: TaskStatus
    
    // Computed property for UI
    var displayTitle: String {
        return title.isEmpty ? "Untitled Task" : title
    }
}
```

#### **2. Custom Decoders**
```swift
struct PayrollPeriod: Codable {
    let id: String
    let startDate: Date
    let endDate: Date
    let weekNumbers: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "period_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case weekNumbers = "week_numbers"
    }
}
```

#### **3. Computed Properties**
```swift
struct WorkEntry: Codable {
    let normalHours: Double
    let overtimeHours: Double
    let weekendHours: Double
    
    // Business logic computed properties
    var totalHours: Double {
        return normalHours + overtimeHours + weekendHours
    }
    
    var hasOvertime: Bool {
        return overtimeHours > 0 || weekendHours > 0
    }
}
```

### **Common Models**

#### **Notification Model**
```swift
struct AppNotification: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let notificationType: NotificationType
    let title: String
    let message: String
    let category: NotificationCategory
    let priority: NotificationPriority
    let isRead: Bool
    let actionRequired: Bool
    let createdAt: Date
    let actionUrl: String?
    let metadata: [String: AnyCodable]?
    
    enum NotificationType: String, Codable, CaseIterable {
        case workEntrySubmitted = "WORK_ENTRY_SUBMITTED"
        case workEntryApproved = "WORK_ENTRY_APPROVED"
        case leaveRequestSubmitted = "LEAVE_REQUEST_SUBMITTED"
        case leaveRequestApproved = "LEAVE_REQUEST_APPROVED"
        // ... more cases
    }
}
```

#### **Work Entry Model**
```swift
struct WorkEntry: Codable, Identifiable {
    let id: Int?
    let employeeId: Int
    let workDate: Date
    let normalHours: Double
    let overtimeHours: Double
    let weekendHours: Double
    let projectId: Int?
    let taskId: Int?
    let notes: String?
    let status: WorkEntryStatus
    let submittedAt: Date?
    let approvedAt: Date?
    let approvedBy: Int?
    
    enum WorkEntryStatus: String, Codable {
        case draft = "DRAFT"
        case submitted = "SUBMITTED"
        case approved = "APPROVED"
        case rejected = "REJECTED"
    }
}
```

---

## 🔄 **API Request/Response Patterns**

### **1. Simple GET Requests**
```swift
// ViewModel usage
func loadData() {
    apiService.fetchTasks()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { tasks in
                self.tasks = tasks
                self.isLoading = false
            }
        )
        .store(in: &cancellables)
}
```

### **2. POST/PUT Requests**
```swift
// Create/Update operations
func createCustomer() {
    let request = CreateCustomerRequest(
        name: customerName,
        email: customerEmail,
        phone: customerPhone
    )
    
    customersAPIService.createCustomer(request)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.showError(error.localizedDescription)
                case .finished:
                    break
                }
            },
            receiveValue: { customer in
                self.customers.append(customer)
                self.showSuccess("Customer created successfully")
            }
        )
        .store(in: &cancellables)
}
```

### **3. Multipart File Upload**
```swift
func uploadProfileImage(imageData: Data) {
    let files = [MultipartFile(
        name: "profile_image",
        filename: "profile.jpg",
        data: imageData,
        mimeType: "image/jpeg"
    )]
    
    workerAPIService.uploadProfileImage(files: files)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.uploadError = error.localizedDescription
                }
            },
            receiveValue: { response in
                self.profileImageUrl = response.imageUrl
            }
        )
        .store(in: &cancellables)
}
```

### **4. Response Patterns**

#### **Simple Response**
```swift
struct MessageResponse: Codable {
    let success: Bool
    let message: String
}
```

#### **Data Response**
```swift
struct CustomersResponse: Codable {
    let customers: [Customer]
    let total: Int
    let page: Int
    let limit: Int
}
```

#### **Paginated Response**
```swift
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
    
    struct PaginationInfo: Codable {
        let currentPage: Int
        let totalPages: Int
        let totalCount: Int
        let hasNext: Bool
        let hasPrevious: Bool
    }
}
```

#### **Nested Response**
```swift
struct ProjectDetailResponse: Codable {
    let project: Project
    let tasks: [Task]
    let assignments: [TaskAssignment]
    let customer: Customer
    let timeline: [TimelineEvent]
}
```

---

## ⚠️ **Error Handling Strategies**

### **Error Types**
```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData  
    case decodingError(Error)
    case networkError(Error)
    case httpError(Int, String?)
    case authenticationError
    case validationError([String])
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .validationError(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .authenticationError:
            return "Authentication failed. Please log in again."
        case .httpError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        default:
            return "An unexpected error occurred"
        }
    }
}
```

### **Error Handling Flow**
```
API Response → BaseAPIService.processResponse()
     ↓
Error Detection → APIError creation
     ↓
Publisher Error → Combine error handling
     ↓
ViewModel → Error state management
     ↓
UI Update → User feedback
```

### **ViewModel Error Handling Pattern**
```swift
class ExampleViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private func handleAPIError(_ error: BaseAPIService.APIError, context: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch error {
            case .authenticationError:
                // Trigger logout
                AuthService.shared.logout()
            case .validationError(let errors):
                self.errorMessage = "Please check: \(errors.joined(separator: ", "))"
            case .networkError:
                self.errorMessage = "Network connection failed. Please try again."
            default:
                self.errorMessage = "\(context) failed: \(error.localizedDescription)"
            }
        }
    }
}
```

---

## 🔄 **Combine Integration**

### **Publisher Patterns**

#### **1. Basic Publisher Chain**
```swift
func fetchData() {
    apiService.fetchTasks()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.handleError(error)
                case .finished:
                    self.isLoading = false
                }
            },
            receiveValue: { data in
                self.updateData(data)
            }
        )
        .store(in: &cancellables)
}
```

#### **2. Chained API Calls**
```swift
func createProjectWithTasks() {
    createProject()
        .flatMap { project in
            self.createTasks(for: project.id)
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.showError(error.localizedDescription)
                }
            },
            receiveValue: { tasks in
                self.projectTasks = tasks
                self.showSuccess("Project and tasks created successfully")
            }
        )
        .store(in: &cancellables)
}
```

#### **3. Parallel API Calls**
```swift
func loadDashboardData() {
    let statsPublisher = apiService.fetchStats()
    let projectsPublisher = apiService.fetchProjects()
    let notificationsPublisher = apiService.fetchNotifications()
    
    Publishers.Zip3(statsPublisher, projectsPublisher, notificationsPublisher)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            },
            receiveValue: { (stats, projects, notifications) in
                self.stats = stats
                self.projects = projects
                self.notifications = notifications
                self.isLoading = false
            }
        )
        .store(in: &cancellables)
}
```

### **Error Recovery**
```swift
func fetchDataWithRetry() {
    apiService.fetchTasks()
        .retry(3)  // Retry up to 3 times
        .catch { error -> AnyPublisher<[Task], Never> in
            // Fallback to cached data
            return Just(self.cachedTasks)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { tasks in
            self.tasks = tasks
        })
        .store(in: &cancellables)
}
```

### **Cancellation Management**
```swift
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()  // Automatic cleanup
    }
    
    func cancelAllRequests() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
```

---

## 💡 **Best Practices & Guidelines**

### **1. API Service Design**
- **Single Responsibility**: Each service handles one domain
- **Protocol-Based**: Define protocols for testing
- **Error Propagation**: Let errors bubble up to ViewModels
- **Type Safety**: Use Codable models for all requests/responses

### **2. Model Design**
- **Immutable**: Use `let` for model properties
- **Computed Properties**: Add business logic as computed properties
- **Validation**: Implement validation methods on models
- **Documentation**: Document complex business rules

### **3. Security**
- **Token Management**: Never store tokens in UserDefaults
- **Input Validation**: Validate all user input before API calls
- **Error Messages**: Don't expose sensitive information in errors
- **Logging**: Log requests but not sensitive data

### **4. Performance**
- **Caching**: Implement caching for frequently accessed data
- **Debouncing**: Use debouncing for search functionality
- **Pagination**: Implement pagination for large datasets
- **Background Tasks**: Use background queues for heavy operations

---

## 🔧 **Common Patterns & Solutions**

### **1. Refresh Pattern**
```swift
func refresh() {
    cancellables.removeAll()  // Cancel ongoing requests
    isLoading = true
    errorMessage = nil
    
    loadData()
}
```

### **2. Search with Debounce**
```swift
@Published var searchText = ""

private var searchCancellable: AnyCancellable?

init() {
    $searchText
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .removeDuplicates()
        .sink { [weak self] searchText in
            self?.performSearch(searchText)
        }
        .store(in: &cancellables)
}
```

### **3. Pagination**
```swift
func loadMore() {
    guard !isLoadingMore else { return }
    
    isLoadingMore = true
    currentPage += 1
    
    apiService.fetchItems(page: currentPage)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { _ in
                self.isLoadingMore = false
            },
            receiveValue: { response in
                self.items.append(contentsOf: response.data)
                self.hasMorePages = response.pagination.hasNext
            }
        )
        .store(in: &cancellables)
}
```

### **4. Optimistic Updates**
```swift
func toggleFavorite(item: Item) {
    // Optimistic update
    item.isFavorite.toggle()
    
    apiService.updateFavoriteStatus(itemId: item.id, isFavorite: item.isFavorite)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    // Revert on failure
                    item.isFavorite.toggle()
                    self.showError("Failed to update favorite status")
                }
            },
            receiveValue: { _ in
                // Success handled by optimistic update
            }
        )
        .store(in: &cancellables)
}
```

---

## 🐛 **Debugging & Troubleshooting**

### **Debug Logging**
```swift
extension BaseAPIService {
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("🌐 API Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        #endif
    }
}
```

### **Common Issues & Solutions**

#### **1. Token Expiration**
- **Issue**: 401 errors after token expires
- **Solution**: Implement automatic token refresh in AuthInterceptor

#### **2. Decoding Errors**
- **Issue**: Model decoding failures
- **Solution**: Use optional properties and custom CodingKeys

#### **3. Memory Leaks**
- **Issue**: ViewModels not deallocating
- **Solution**: Use `[weak self]` in closures and proper cancellable management

#### **4. Network Timeouts**
- **Issue**: Slow API responses causing timeouts
- **Solution**: Use long timeout sessions for heavy operations

---

## 📈 **Migration Guide**

### **Adding New Endpoints**

1. **Define Model**
```swift
struct NewModel: Codable {
    let id: Int
    let name: String
    // ... other properties
}
```

2. **Add API Method**
```swift
extension YourAPIService {
    func fetchNewData() -> AnyPublisher<[NewModel], BaseAPIService.APIError> {
        BaseAPIService.shared.get(
            endpoint: "/api/app/new-endpoint",
            responseType: [NewModel].self
        )
    }
}
```

3. **Update ViewModel**
```swift
@Published var newData: [NewModel] = []

func loadNewData() {
    apiService.fetchNewData()
        .receive(on: DispatchQueue.main)
        .sink(/* ... */)
        .store(in: &cancellables)
}
```

4. **Test Integration**
- Unit tests for model decoding
- Integration tests for API calls
- UI tests for complete workflows

This comprehensive API documentation provides the foundation for understanding and extending the KSR Cranes app's data layer architecture.