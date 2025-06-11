# Edit Task Implementation - Issues Found

## Date: 2025-06-09

## Summary

The EditTaskViewModel.swift file has several critical issues that prevent it from compiling:

1. References non-existent `externalSupervisor` field in ProjectTask
2. Uses `CraneType` as a Set element, but CraneType doesn't conform to Hashable
3. Certificate types are stored as String instead of Int
4. References non-existent `NavigationController` type
5. The UpdateTaskRequest struct is missing all management calendar and equipment fields

All these issues need to be fixed before the edit task functionality will work properly.

### Issues Identified in EditTaskViewModel.swift

1. **External Supervisor Fields Don't Exist in ProjectTask Model**
   - Lines 147-151: `task.externalSupervisor` doesn't exist
   - Lines 329-333: References to `original.externalSupervisor` are invalid
   - The ProjectTask model only has: `supervisorId`, `supervisorName`, `supervisorEmail`, `supervisorPhone`

2. **CraneType is a Struct, Not an Enum**
   - Line 25: `selectedCraneTypes: Set<CraneType>` - CraneType doesn't conform to Hashable
   - Line 64: `originalCraneTypes: Set<CraneType>` - Same issue
   - Line 472: `$0.rawValue` - CraneType is a struct with `id`, not an enum with rawValue
   - Solution: Use `Set<Int>` for crane type IDs instead

3. **Certificate Types Mismatch**
   - Line 32: `selectedCertificates: Set<String>` - Should be `Set<Int>` 
   - ProjectTask has `requiredCertificates: [Int]?` (certificate type IDs)

4. **NavigationController Doesn't Exist**
   - Line 68: `weak var navigationController: NavigationController?`
   - Line 86: Constructor parameter references non-existent type
   - Line 523: `navigationController?.popToRoot()` won't work

5. **UpdateTaskRequest Struct is Incomplete**
   - The UpdateTaskRequest struct exists but is missing all management calendar fields
   - Current fields: title, description, deadline, supervisorId, supervisorName, supervisorEmail, supervisorPhone, isActive
   - Missing fields: startDate, status, priority, estimatedHours, requiredOperators, clientEquipmentInfo, requiredCraneTypes, preferredCraneModelId, equipmentCategoryId, equipmentBrandId, requiredCertificates

### Required Changes

1. **Remove External Supervisor Logic**
   - Remove all references to `externalSupervisor`
   - Remove `isExternalSupervisor`, `externalSupervisorName`, `externalSupervisorPhone` properties
   - Use the existing supervisor fields from ProjectTask

2. **Fix Crane Type Handling**
   ```swift
   @Published var selectedCraneTypes: Set<Int> = []  // Use IDs instead
   private var originalCraneTypes: Set<Int> = []
   
   // In setupInitialValues:
   if let craneTypes = task.requiredCraneTypes {
       selectedCraneTypes = Set(craneTypes)
       originalCraneTypes = selectedCraneTypes
   }
   
   // In saveTask:
   if !selectedCraneTypes.isEmpty {
       updateData["required_crane_types"] = Array(selectedCraneTypes)
   }
   ```

3. **Fix Certificate Types**
   ```swift
   @Published var selectedCertificates: Set<Int> = []  // Use Int for IDs
   private var originalCertificates: Set<Int> = []
   ```

4. **Remove NavigationController**
   - Remove the property and parameter
   - Use environment dismiss or completion handler instead

5. **Update Equipment Field Handling**
   - Remove references to `selectedCategory`, `selectedBrand`, `selectedModel` if not using them
   - Or implement proper equipment selection if needed

### Additional Notes

- The ProjectTask model includes all management calendar fields correctly
- The API service `updateTask` method expects an UpdateTaskRequest object, NOT a dictionary
- Supervisor handling should use the existing fields: `supervisorName`, `supervisorEmail`, `supervisorPhone`

### Complete UpdateTaskRequest Structure Needed

```swift
struct UpdateTaskRequest: Codable {
    let title: String?
    let description: String?
    let deadline: Date?
    let supervisorId: Int?
    let supervisorName: String?
    let supervisorEmail: String?
    let supervisorPhone: String?
    let isActive: Bool?
    
    // Management Calendar Fields
    let startDate: Date?
    let status: String?  // Use raw value
    let priority: String?  // Use raw value
    let estimatedHours: Double?
    let requiredOperators: Int?
    let clientEquipmentInfo: String?
    
    // Equipment Fields
    let requiredCraneTypes: [Int]?
    let preferredCraneModelId: Int?
    let equipmentCategoryId: Int?
    let equipmentBrandId: Int?
    
    // Certificate Fields
    let requiredCertificates: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case deadline
        case supervisorId = "supervisor_id"
        case supervisorName = "supervisor_name"
        case supervisorEmail = "supervisor_email"
        case supervisorPhone = "supervisor_phone"
        case isActive = "is_active"
        
        // Management Calendar Fields
        case startDate = "start_date"
        case status
        case priority
        case estimatedHours = "estimated_hours"
        case requiredOperators = "required_operators"
        case clientEquipmentInfo = "client_equipment_info"
        
        // Equipment Fields
        case requiredCraneTypes = "required_crane_types"
        case preferredCraneModelId = "preferred_crane_model_id"
        case equipmentCategoryId = "equipment_category_id"
        case equipmentBrandId = "equipment_brand_id"
        
        // Certificate Fields
        case requiredCertificates = "required_certificates"
    }
}
```

### Updated saveTask Method

```swift
func saveTask() {
    guard isFormValid && hasChanges else { return }
    
    isLoading = true
    error = nil
    
    // Build UpdateTaskRequest object
    let updateRequest = UpdateTaskRequest(
        title: taskTitle,
        description: description.isEmpty ? nil : description,
        deadline: hasDeadline ? deadline : nil,
        supervisorId: supervisorId,
        supervisorName: supervisorName,
        supervisorEmail: supervisorEmail, 
        supervisorPhone: supervisorPhone,
        isActive: true,
        startDate: hasStartDate ? startDate : nil,
        status: status.rawValue,
        priority: priority.rawValue,
        estimatedHours: hasEstimatedHours ? estimatedHours : nil,
        requiredOperators: hasRequiredOperators ? requiredOperators : nil,
        clientEquipmentInfo: clientEquipmentInfo.isEmpty ? nil : clientEquipmentInfo,
        requiredCraneTypes: selectedCraneTypes.isEmpty ? nil : Array(selectedCraneTypes),
        preferredCraneModelId: preferredCraneModelId,
        equipmentCategoryId: nil,  // Not used in UI
        equipmentBrandId: nil,     // Not used in UI
        requiredCertificates: selectedCertificates.isEmpty ? nil : Array(selectedCertificates)
    )
    
    // Make API call  
    apiService.updateTask(id: task.id, data: updateRequest)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                // ... existing completion code
            },
            receiveValue: { [weak self] updatedTask in
                // ... existing success code
            }
        )
        .store(in: &cancellables)
}
```