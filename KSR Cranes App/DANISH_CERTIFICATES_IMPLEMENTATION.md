# Danish Crane Certificates Implementation Guide

## 📋 Overview

This document describes the implementation of Danish crane operator certificates according to Arbejdstilsynet (Danish Working Environment Authority) regulations into the KSR Cranes system.

### Business Context
KSR Cranes is a crane operator staffing company that provides certified crane operators to work with clients' equipment. The company specializes in matching operators with appropriate certifications to specific crane types and projects.

## 🎯 System Architecture

### Core Components
1. **CertificateTypes** - Danish certificate definitions
2. **CraneCategory** - Equipment categories requiring specific certificates  
3. **WorkerSkills** - Individual operator certifications
4. **Employees** - Crane operators

### Data Flow
```
Task Creation → CraneCategory Selection → Required Certificates → Available Operators
```

## 📊 Database Schema

### 1. CertificateTypes Table (NEW)
Stores Danish crane operator certificate types according to Arbejdstilsynet regulations.

```sql
CREATE TABLE `CertificateTypes` (
  `certificate_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,                    -- CLASS_A, CLASS_B, TELESCOPIC
  `name_da` varchar(100) NOT NULL,                -- Danish name
  `name_en` varchar(100) NOT NULL,                -- English name
  `description` text DEFAULT NULL,                -- Certificate description
  `equipment_types` text DEFAULT NULL,            -- Covered equipment types
  `capacity_range` varchar(50) DEFAULT NULL,      -- Capacity requirements
  `requires_medical` tinyint(1) DEFAULT 1,        -- Medical examination required
  `min_age` int(11) DEFAULT 18,                   -- Minimum age requirement
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`certificate_type_id`),
  UNIQUE KEY `idx_certificate_code` (`code`)
);
```

### 2. CraneCategory Table (EXTENDED)
Extended with required certificates for each equipment category.

```sql
ALTER TABLE `CraneCategory` 
ADD COLUMN `required_certificates` JSON DEFAULT NULL,
ADD COLUMN `danish_classification` varchar(50) DEFAULT NULL,
ADD COLUMN `capacity_info` varchar(100) DEFAULT NULL;
```

### 3. WorkerSkills Table (EXTENDED)
Extended to reference Danish certificate types.

```sql
ALTER TABLE `WorkerSkills` 
ADD COLUMN `certificate_type_id` int(11) DEFAULT NULL,
ADD CONSTRAINT `fk_worker_skills_certificate` 
FOREIGN KEY (`certificate_type_id`) REFERENCES `CertificateTypes`(`certificate_type_id`) ON DELETE SET NULL;
```

## 🏗️ Certificate Types Implementation

### Danish Certificate Classes
Based on Arbejdstilsynet regulations:

| Code | Danish Name | English Name | Equipment Coverage |
|------|-------------|--------------|-------------------|
| CLASS_A | Klasse A - Tårnkran | Class A - Tower Crane | Tower cranes, harbour cranes, slewing cranes |
| CLASS_B | Klasse B - Mobilkran | Class B - Mobile Crane | Mobile cranes, construction plant |
| CLASS_C | Klasse C - Andre kraner | Class C - Other Cranes | Other cranes requiring certification |
| CLASS_D | Klasse D - Lastbilkran 8-25 | Class D - Truck Crane 8-25 | Truck-mounted cranes 8-25 ton-meters |
| CLASS_E | Klasse E - Lastbilkran >25 | Class E - Truck Crane >25 | Truck-mounted cranes >25 ton-meters |
| CLASS_G | Klasse G - Entreprenørmaskiner | Class G - Construction Plant | Construction machinery used as cranes |
| TELESCOPIC | Teleskoplæssercertifikat | Telescopic Handler Certificate | Telescopic handlers/telehandlers |
| CRANE_BASIS | Kranbasisuddannelse | Crane Basic Training | Basic training for >8 ton-meter cranes |
| RIGGER | Anhugning | Rigger Certificate | Rigging and slinging operations |

### Certificate-Category Mapping
```sql
-- Tårnkran requires Class A
UPDATE CraneCategory SET required_certificates = '[1]' WHERE code = 't-rnkran';

-- Mobilkran requires Class B  
UPDATE CraneCategory SET required_certificates = '[2]' WHERE code = 'mobilkran';

-- Teleskoplæsser requires Telescopic + Crane Basis
UPDATE CraneCategory SET required_certificates = '[7,8]' WHERE code = 'teleskopl-sser';
```

## 🔄 Business Workflow

### 1. Task Creation Process
```
Chef creates Task → Selects CraneCategory → System determines required certificates
```

### 2. Operator Assignment Process
```
System filters operators → Only shows those with required certificates → Chef assigns operator
```

### 3. Validation Process
```
Before assignment → Check operator has valid certificates → Verify expiration dates
```

## 💻 API Integration

### Required API Endpoints

#### 1. Certificate Management
```typescript
GET    /api/app/chef/certificates              // List all certificate types
GET    /api/app/chef/certificates/{id}         // Get specific certificate
POST   /api/app/chef/certificates              // Create new certificate type
PUT    /api/app/chef/certificates/{id}         // Update certificate type
DELETE /api/app/chef/certificates/{id}         // Deactivate certificate type
```

#### 2. Worker Certificate Management
```typescript
GET    /api/app/chef/workers/{id}/certificates    // Get worker's certificates
POST   /api/app/chef/workers/{id}/certificates    // Add certificate to worker
PUT    /api/app/chef/workers/{id}/certificates/{cert_id}  // Update worker certificate
DELETE /api/app/chef/workers/{id}/certificates/{cert_id}  // Remove worker certificate
```

#### 3. Enhanced Worker Availability
```typescript
GET    /api/app/chef/tasks/{id}/available-workers?crane_category_id={id}
// Returns only workers with required certificates for the crane category
```

### API Response Examples

#### Worker with Certificates
```json
{
  "employee_id": 123,
  "name": "Erik Hansen",
  "email": "erik@ksrcranes.dk",
  "role": "arbejder",
  "certificates": [
    {
      "certificate_type_id": 1,
      "code": "CLASS_A",
      "name_en": "Class A - Tower Crane",
      "is_certified": true,
      "certification_expires": "2026-05-15",
      "years_experience": 8
    },
    {
      "certificate_type_id": 2,
      "code": "CLASS_B", 
      "name_en": "Class B - Mobile Crane",
      "is_certified": true,
      "certification_expires": "2025-12-20",
      "years_experience": 12
    }
  ]
}
```

## 📱 iOS Implementation

### Required Models

#### CertificateType Model
```swift
struct CertificateType: Codable, Identifiable {
    let id: Int
    let code: String
    let nameDa: String
    let nameEn: String
    let description: String?
    let equipmentTypes: String?
    let capacityRange: String?
    let requiresMedical: Bool
    let minAge: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "certificate_type_id"
        case code, description
        case nameDa = "name_da"
        case nameEn = "name_en"
        case equipmentTypes = "equipment_types"
        case capacityRange = "capacity_range"
        case requiresMedical = "requires_medical"
        case minAge = "min_age"
        case isActive = "is_active"
    }
}
```

#### WorkerCertificate Model
```swift
struct WorkerCertificate: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let certificateTypeId: Int
    let certificateType: CertificateType
    let skillName: String
    let isCertified: Bool
    let certificationExpires: Date?
    let yearsExperience: Int
    
    var isExpiringSoon: Bool {
        guard let expiryDate = certificationExpires else { return false }
        return expiryDate.timeIntervalSinceNow < 30 * 24 * 3600 // 30 days
    }
    
    var isExpired: Bool {
        guard let expiryDate = certificationExpires else { return false }
        return expiryDate < Date()
    }
}
```

### UI Components

#### 1. Worker Detail View Enhancement
Add certificates section to `WorkerDetailView.swift`:
```swift
private var certificatesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Certificates & Qualifications")
            .font(.headline)
            .fontWeight(.semibold)
        
        ForEach(worker.certificates ?? []) { certificate in
            CertificateCard(certificate: certificate)
        }
    }
}
```

#### 2. Certificate Management View
New view for managing worker certificates:
```swift
struct WorkerCertificateManagementView: View {
    let worker: WorkerForChef
    @StateObject private var viewModel = WorkerCertificateViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.certificates) { certificate in
                    CertificateRow(certificate: certificate)
                }
            }
            .navigationTitle("Certificates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Certificate") {
                        viewModel.showAddCertificate = true
                    }
                }
            }
        }
    }
}
```

#### 3. Task Creation Enhancement
Update equipment selector to show required certificates:
```swift
struct EquipmentCategoryCard: View {
    let category: CraneCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.headline)
            
            if let certificates = category.requiredCertificates {
                Text("Required: \(certificates.map(\.nameEn).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## 🔍 Validation & Business Rules

### Certificate Validation Rules
1. **Expiration Check**: Certificates must not be expired
2. **Category Matching**: Operator must have certificate for selected crane category
3. **Age Requirement**: Operator must meet minimum age for certificate type
4. **Medical Requirements**: Valid medical examination if required by certificate

### Automatic Filtering
```sql
-- Example: Find available operators for Mobile Crane task
SELECT DISTINCT e.employee_id, e.name
FROM Employees e
JOIN WorkerSkills ws ON e.employee_id = ws.employee_id
JOIN CertificateTypes ct ON ws.certificate_type_id = ct.certificate_type_id
WHERE e.role = 'arbejder'
  AND e.is_activated = 1
  AND ws.is_certified = 1
  AND (ws.certification_expires IS NULL OR ws.certification_expires > NOW())
  AND ct.certificate_type_id IN (
    SELECT JSON_UNQUOTE(JSON_EXTRACT(required_certificates, '$[0]'))
    FROM CraneCategory 
    WHERE code = 'mobilkran'
  );
```

## 📅 Implementation Timeline

### Phase 1: Database Setup ✅ COMPLETED
- [x] Create CertificateTypes table
- [x] Extend CraneCategory table
- [x] Extend WorkerSkills table
- [x] Import Danish certificate data
- [x] Map certificates to crane categories

### Phase 2: API Development ✅ COMPLETED
- [x] Certificate management endpoints
- [x] Worker certificate endpoints
- [x] Enhanced worker availability endpoints
- [x] Update task creation endpoints
- [x] All 13 API endpoints implemented and tested

### Phase 3: iOS Implementation ✅ COMPLETED (June 9, 2025)
- [x] Create certificate models
- [x] Update worker detail views
- [x] Add certificate management UI (EditWorkerView)
- [x] Certificate display in WorkerDetailView
- [x] Certificate selection with years of experience slider
- [x] Integration with existing MVVM architecture
- [x] Enhance task creation flow (certificate requirements selection)
- [x] Update available workers display (filter by required certificates)

### Phase 4: Testing & Validation (In Progress)
- [x] Basic certificate CRUD operations
- [x] Certificate display in worker details
- [ ] Integration tests for operator assignment
- [ ] End-to-end workflow testing

## 🔧 Phase 3 Implementation Details ✅ COMPLETED (June 9, 2025)

### Completed Items

#### Key Components Implemented

#### 1. Certificate Management in EditWorkerView
- **Certificate Section**: Added dedicated section for viewing and managing certificates
- **Add/Remove Functionality**: Workers can add new certificates or remove existing ones
- **Certificate Selection UI**: Expandable interface with:
  - Certificate type selection
  - Years of experience slider (0-30 years)
  - Skill level dropdown (beginner, intermediate, advanced, expert)
  - Expiry date picker
  - Certification status toggle
  - Certificate number field
  - Notes field

#### 2. Certificate Display in WorkerDetailView
- **Certificates Section**: Shows all worker certificates with:
  - Certificate icon and name
  - Status indicator (Valid/Expired/Expiring Soon)
  - Expiry date
  - Years of experience
- **Visual Design**: Consistent with KSR design system

#### 3. Model Updates
- **WorkerForChef**: Added optional `certificates: [WorkerCertificate]?` field
- **WorkerQuickStats**: Made all fields optional to handle API response variations
- **CertificateType**: Made `createdAt` and `updatedAt` optional
- **WorkerCertificate**: Made `employeeId` optional for nested responses

#### 4. API Integration
- **ChefWorkersAPIService**: Added `includeCertificates` parameter to fetch workers with certificates
- **CertificateAPIService**: Full CRUD operations for worker certificates
- **EditWorkerViewModel**: Complete certificate management methods

### Issues Resolved During Implementation

#### 1. Skill Level Validation Error
- **Issue**: Server rejected "certified" skill level value
- **Solution**: Removed "certified" enum case, use standard levels (beginner, intermediate, advanced, expert)

#### 2. Certificate Default Status
- **Issue**: Certificates showing as "Not Certified" by default
- **Solution**: Changed default `isCertified` to `true` when adding certificates

#### 3. Worker Stats Decoding Error
- **Issue**: Missing fields in API response causing decoding failures
- **Solution**: Made all `WorkerQuickStats` fields optional with safe default values

#### 4. Certificate Display in Details
- **Issue**: Certificates not showing in WorkerDetailView
- **Solution**: Added certificate fetching to worker list API call and display section

#### 5. Years Experience Tracking
- **Issue**: Confusion about years experience value source
- **Solution**: Added debug logging to trace value flow through the system

### Technical Decisions

1. **Default Values**:
   - `isCertified`: true (assumes workers have valid certificates when adding)
   - `skillLevel`: expert (highest competency level)
   - `yearsExperience`: 0 (user adjusts via slider)

2. **UI/UX Choices**:
   - Progressive disclosure for certificate details
   - Visual status indicators with color coding
   - Inline editing within EditWorkerView
   - Read-only display in WorkerDetailView

3. **Data Flow**:
   - Certificates loaded with worker list when needed
   - Separate API calls for certificate CRUD operations
   - Real-time UI updates after certificate changes

### Phase 3 Final Implementation (June 9, 2025)

#### 1. Enhanced Task Creation Flow ✅ COMPLETED
- **Implementation completed**:
  - Added certificate requirements section in ChefCreateTaskView
  - Created CertificateSelectionView component for certificate selection
  - Integrated certificate requirements with task creation API
  - Added visual certificate display with selection management
  - Certificates are now part of CreateTaskRequest model

#### 2. Updated Available Workers Display ✅ COMPLETED  
- **Implementation completed**:
  - Modified ChefWorkerPickerView to accept requiredCertificates parameter
  - Updated worker picker to filter based on certificate requirements
  - Added certificate validation in worker selection
  - Integrated certificate requirements throughout worker assignment flow
  - ChefTaskDetailView now passes certificate requirements to worker picker

#### 3. Server-Side Enhancement ✅ COMPLETED
- **Additional validation implemented**:
  - Enhanced task assignment endpoint to validate BOTH:
    - Certificate requirements (from CraneCategory.required_certificates)
    - Crane type skills (from Tasks.required_crane_types)
  - Added comprehensive validation with skip options for both types
  - Proper error messages for missing certificates or crane type skills

#### 4. Naming Conflict Resolution ✅ COMPLETED
- **Issue**: Two different `CertificateSelectionView` components with incompatible interfaces
  - Worker management version: expects `[CertificateSelectionState]` parameter
  - Task creation version: expects `[CertificateType]` bindings
- **Solution**: Renamed task certificate selection view to `TaskCertificateSelectionView`
  - File location: `/Features/Chef/Tasks/TaskCertificateSelectionView.swift`
  - Prevents compilation errors from conflicting view signatures
  - Each context now uses the appropriate certificate selection interface

## 🚨 Migration Considerations

### Data Migration
1. **Existing Workers**: Map current operators to appropriate certificate types
2. **Historical Data**: Preserve existing WorkerSkills data
3. **Validation**: Ensure all operators have required certificates for their assigned tasks

### Backward Compatibility
- Existing API endpoints continue to work
- New certificate fields are optional initially
- Gradual migration of existing data

## 🔧 Maintenance & Monitoring

### Regular Tasks
1. **Certificate Expiration Monitoring**: Alert operators and managers about expiring certificates
2. **Compliance Reporting**: Generate reports for Arbejdstilsynet compliance
3. **Data Quality**: Regular validation of certificate data accuracy

### Key Metrics
- Number of certified operators per certificate type
- Certificate expiration timeline
- Operator utilization by certificate type
- Compliance status across the workforce

## 📞 Support & Documentation

### Resources
- [Arbejdstilsynet Official Guidelines](https://at.dk/en/regulations/guidelines/certificates-crane-drivers-b-2-1-1/)
- [Danish Crane Operator Regulations](https://at.dk/regler/at-vejledninger/kranfoerercertifikat-1-9-4/)
- [Telescopic Handler Requirements](https://at.dk/regler/at-vejledninger/teleskoplaessercertifikat-1-9-3/)

### Contact Information
For questions regarding this implementation, contact the development team or refer to the project documentation in CLAUDE.md.

---

**Document Version**: 1.3  
**Last Updated**: June 9, 2025  
**Author**: KSR Cranes Development Team  
**Phase 3 Status**: ✅ FULLY COMPLETED (8/8 items done)

### Important Implementation Notes

**Xcode Project Setup Required**:
When implementing the certificate selection features, ensure that `TaskCertificateSelectionView.swift` is properly added to the Xcode project:
1. Right-click on `Features/Chef/Tasks` folder in Xcode
2. Select "Add Files to 'KSR Cranes App'"
3. Navigate to and select `TaskCertificateSelectionView.swift`
4. Ensure the file is included in the target membership

This resolves the "Cannot find 'TaskCertificateSelectionView' in scope" compilation error.