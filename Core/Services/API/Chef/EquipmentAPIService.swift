//
//  EquipmentAPIService.swift
//  KSR Cranes App
//
//  ✅ COMPLETELY FIXED - Equipment Hierarchy API Service with String to Decimal Conversion
//

import Foundation
import Combine

// MARK: - Enhanced Equipment API Service with Hierarchy

final class EquipmentAPIService: BaseAPIService {
    static let shared = EquipmentAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - 1. Crane Categories API (ROOT LEVEL)
    
    /// Fetch crane categories (top level of hierarchy) - NEW ENDPOINT
    func fetchCraneCategories(
        isActive: Bool = true,
        includeTypesCount: Bool = false,
        search: String? = nil
    ) -> AnyPublisher<[CraneCategoryAPIResponse], APIError> {
        var endpoint = "/api/app/chef/crane-categories"
        var queryParams: [String] = []
        
        queryParams.append("is_active=\(isActive)")
        
        if includeTypesCount {
            queryParams.append("include_types_count=true")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[EquipmentAPIService] 📞 Categories API Call: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [CraneCategoryAPIResponse].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 2. Crane Types API (LEVEL 2) - ENHANCED
    
    /// Fetch crane types filtered by category
    func fetchCraneTypes(
        categoryId: Int? = nil,
        isActive: Bool = true,
        includeModelsCount: Bool = false
    ) -> AnyPublisher<[CraneTypeAPIResponse], APIError> {
        var endpoint = "/api/app/chef/crane-types"
        var queryParams: [String] = []
        
        if let categoryId = categoryId {
            queryParams.append("category_id=\(categoryId)")
        }
        
        queryParams.append("is_active=\(isActive)")
        
        if includeModelsCount {
            queryParams.append("include_models_count=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[EquipmentAPIService] 📞 Types API Call: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [CraneTypeAPIResponse].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 3. Crane Brands API (LEVEL 3) - EXISTING
    
    /// Fetch crane brands (independent of hierarchy but can be filtered)
    func fetchCraneBrands(
        isActive: Bool = true,
        includeModelsCount: Bool = false,
        search: String? = nil
    ) -> AnyPublisher<[CraneBrandAPIResponse], APIError> {
        var endpoint = "/api/app/chef/crane-brands"
        var queryParams: [String] = []
        
        queryParams.append("is_active=\(isActive)")
        
        if includeModelsCount {
            queryParams.append("include_models_count=true")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[EquipmentAPIService] 📞 Brands API Call: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [CraneBrandAPIResponse].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 4. Crane Models API (FINAL LEVEL) - FIXED WITH STRING TO DECIMAL CONVERSION
    
    /// Fetch crane models with comprehensive filtering
    func fetchCraneModels(
        typeId: Int? = nil,
        brandId: Int? = nil,
        categoryId: Int? = nil,
        search: String? = nil,
        isActive: Bool = true,
        includeDiscontinued: Bool = false
    ) -> AnyPublisher<[CraneModelAPIResponse], APIError> {
        var endpoint = "/api/app/chef/crane-models"
        var queryParams: [String] = []
        
        if let typeId = typeId {
            queryParams.append("type_id=\(typeId)")
        }
        
        if let brandId = brandId {
            queryParams.append("brand_id=\(brandId)")
        }
        
        if let categoryId = categoryId {
            queryParams.append("category_id=\(categoryId)")
        }
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        queryParams.append("is_active=\(isActive)")
        
        if includeDiscontinued {
            queryParams.append("include_discontinued=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[EquipmentAPIService] 📞 Models API Call: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [CraneModelAPIResponse].self, decoder: EquipmentAPIService.specialCraneModelDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - ✅ SPECIAL DECODER FOR CRANE MODELS TO HANDLE STRING TO DECIMAL CONVERSION
    
    static func specialCraneModelDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Custom date decoding strategy for API format
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try API format with milliseconds first
            let apiFormatter = DateFormatter()
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            apiFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Try without milliseconds
            apiFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = apiFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }
        
        return decoder
    }
    
    // MARK: - 5. HIERARCHY CONVENIENCE METHODS
    
    /// Get the complete equipment hierarchy for building cascading selectors
    func fetchCompleteEquipmentHierarchy() -> AnyPublisher<EquipmentHierarchy, APIError> {
        #if DEBUG
        print("[EquipmentAPIService] 🔄 Loading complete equipment hierarchy...")
        #endif
        
        return Publishers.Zip4(
            fetchCraneCategories(includeTypesCount: true),
            fetchCraneTypes(includeModelsCount: true),
            fetchCraneBrands(includeModelsCount: true),
            fetchCraneModels()
        )
        .map { categories, types, brands, models in
            EquipmentHierarchy(
                categories: categories,
                types: types,
                brands: brands,
                models: models
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Get types for specific category (cascading selection)
    func fetchTypesForCategory(_ categoryId: Int) -> AnyPublisher<[CraneTypeAPIResponse], APIError> {
        #if DEBUG
        print("[EquipmentAPIService] 🔄 Loading types for category: \(categoryId)")
        #endif
        
        return fetchCraneTypes(categoryId: categoryId, includeModelsCount: true)
    }
    
    /// Get models for specific type and brand combination
    func fetchModelsForTypeAndBrand(typeId: Int, brandId: Int? = nil) -> AnyPublisher<[CraneModelAPIResponse], APIError> {
        #if DEBUG
        print("[EquipmentAPIService] 🔄 Loading models for type: \(typeId), brand: \(brandId?.description ?? "any")")
        #endif
        
        return fetchCraneModels(typeId: typeId, brandId: brandId)
    }
    
    /// Get brands that have models for specific type (smart filtering)
    func fetchBrandsForType(_ typeId: Int) -> AnyPublisher<[CraneBrandAPIResponse], APIError> {
        #if DEBUG
        print("[EquipmentAPIService] 🔄 Loading brands with models for type: \(typeId)")
        #endif
        
        // First get all models for this type to determine which brands are available
        return fetchCraneModels(typeId: typeId)
            .flatMap { [weak self] models -> AnyPublisher<[CraneBrandAPIResponse], APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                // Get unique brand IDs from the models
                let brandIds = Set(models.map { $0.brandId })
                
                #if DEBUG
                print("[EquipmentAPIService] 🔍 Found \(models.count) models with brand IDs: \(brandIds)")
                #endif
                
                // Fetch all brands and filter by the ones that have models for this type
                return self.fetchCraneBrands(includeModelsCount: true)
                    .map { allBrands in
                        let filteredBrands = allBrands.filter { brandIds.contains($0.id) }
                        #if DEBUG
                        print("[EquipmentAPIService] 🏢 Filtered to \(filteredBrands.count) brands that have models for type \(typeId)")
                        filteredBrands.forEach { brand in
                            print("   - \(brand.name) (ID: \(brand.id))")
                        }
                        #endif
                        return filteredBrands
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 6. VALIDATION HELPERS
    
    /// Validate equipment selection hierarchy
    func validateEquipmentSelection(
        categoryId: Int?,
        typeId: Int?,
        brandId: Int?,
        modelId: Int?
    ) -> AnyPublisher<EquipmentValidationResult, APIError> {
        
        // Start validation chain
        var validationPublisher: AnyPublisher<EquipmentValidationResult, APIError>
        
        if let categoryId = categoryId {
            validationPublisher = validateCategoryExists(categoryId)
        } else {
            validationPublisher = Just(EquipmentValidationResult()).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        // Chain type validation if provided
        if let typeId = typeId {
            validationPublisher = validationPublisher
                .flatMap { result -> AnyPublisher<EquipmentValidationResult, APIError> in
                    self.validateTypeInCategory(typeId: typeId, categoryId: categoryId)
                        .map { isValid in
                            var newResult = result
                            newResult.isTypeValid = isValid
                            return newResult
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        
        // Chain brand validation if provided
        if let brandId = brandId {
            validationPublisher = validationPublisher
                .flatMap { result -> AnyPublisher<EquipmentValidationResult, APIError> in
                    self.validateBrandHasModelsForType(brandId: brandId, typeId: typeId)
                        .map { isValid in
                            var newResult = result
                            newResult.isBrandValid = isValid
                            return newResult
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        
        // Chain model validation if provided
        if let modelId = modelId {
            validationPublisher = validationPublisher
                .flatMap { result -> AnyPublisher<EquipmentValidationResult, APIError> in
                    self.validateModelMatchesSelection(modelId: modelId, typeId: typeId, brandId: brandId)
                        .map { isValid in
                            var newResult = result
                            newResult.isModelValid = isValid
                            return newResult
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        
        return validationPublisher
    }
    
    // MARK: - Private Validation Methods
    
    private func validateCategoryExists(_ categoryId: Int) -> AnyPublisher<EquipmentValidationResult, APIError> {
        return fetchCraneCategories()
            .map { categories in
                var result = EquipmentValidationResult()
                result.isCategoryValid = categories.contains { $0.id == categoryId }
                return result
            }
            .eraseToAnyPublisher()
    }
    
    private func validateTypeInCategory(typeId: Int, categoryId: Int?) -> AnyPublisher<Bool, APIError> {
        return fetchCraneTypes(categoryId: categoryId)
            .map { types in
                types.contains { $0.id == typeId }
            }
            .eraseToAnyPublisher()
    }
    
    private func validateBrandHasModelsForType(brandId: Int, typeId: Int?) -> AnyPublisher<Bool, APIError> {
        return fetchCraneModels(typeId: typeId, brandId: brandId)
            .map { models in
                !models.isEmpty
            }
            .eraseToAnyPublisher()
    }
    
    private func validateModelMatchesSelection(modelId: Int, typeId: Int?, brandId: Int?) -> AnyPublisher<Bool, APIError> {
        return fetchCraneModels(typeId: typeId, brandId: brandId)
            .map { models in
                models.contains { $0.id == modelId }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Crane Model Detail API
    
    /// Fetch detailed crane model information
    func fetchCraneModelDetail(id: Int) -> AnyPublisher<CraneModelDetailAPIResponse, APIError> {
        let endpoint = "/api/app/chef/crane-models/\(id)"
        
        #if DEBUG
        print("[EquipmentAPIService] 📞 API Call: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CraneModelDetailAPIResponse.self, decoder: EquipmentAPIService.specialCraneModelDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Enhanced Response Models

struct EquipmentHierarchy: Codable {
    let categories: [CraneCategoryAPIResponse]
    let types: [CraneTypeAPIResponse]
    let brands: [CraneBrandAPIResponse]
    let models: [CraneModelAPIResponse]
}

struct EquipmentValidationResult {
    var isCategoryValid: Bool = true
    var isTypeValid: Bool = true
    var isBrandValid: Bool = true
    var isModelValid: Bool = true
    
    var isCompletelyValid: Bool {
        return isCategoryValid && isTypeValid && isBrandValid && isModelValid
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if !isCategoryValid { errors.append("Invalid category selection") }
        if !isTypeValid { errors.append("Type not available in selected category") }
        if !isBrandValid { errors.append("Brand has no models for selected type") }
        if !isModelValid { errors.append("Model not available for selected type/brand combination") }
        
        return errors
    }
}

// MARK: - ✅ COMPLETELY FIXED API Response Models with String to Decimal Conversion

/// Crane Category API Response
struct CraneCategoryAPIResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
    let description: String?
    let iconUrl: String?
    let displayOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let _count: CategoryCountResponse?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, code, description
        case iconUrl = "iconUrl"
        case displayOrder = "displayOrder"
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case _count
    }
}

/// Crane Type API Response
struct CraneTypeAPIResponse: Codable, Identifiable {
    let id: Int
    let categoryId: Int
    let name: String
    let code: String
    let description: String?
    let technicalSpecs: [String: AnyCodable]?
    let iconUrl: String?
    let imageUrl: String?
    let displayOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let category: CraneCategoryAPIResponse
    let _count: ModelCountResponse?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "categoryId"
        case name, code, description
        case technicalSpecs = "technicalSpecs"
        case iconUrl = "iconUrl"
        case imageUrl = "imageUrl"
        case displayOrder = "displayOrder"
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case category, _count
    }
}

/// Crane Brand API Response
struct CraneBrandAPIResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
    let logoUrl: String?
    let website: String?
    let description: String?
    let foundedYear: Int?
    let headquarters: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let _count: ModelCountResponse?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, code
        case logoUrl = "logoUrl"
        case website, description
        case foundedYear = "foundedYear"
        case headquarters
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case _count
    }
}

/// ✅ FIXED: Crane Model API Response with Custom String to Decimal Conversion
struct CraneModelAPIResponse: Codable, Identifiable {
    let id: Int
    let brandId: Int
    let typeId: Int
    let name: String
    let code: String
    let description: String?
    let maxLoadCapacity: Decimal?
    let maxHeight: Decimal?
    let maxRadius: Decimal?
    let enginePower: Int?
    let specifications: [String: AnyCodable]?
    let imageUrl: String?
    let brochureUrl: String?
    let videoUrl: String?
    let releaseYear: Int?
    let isDiscontinued: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Flattened fields from API response
    let brand_name: String?
    let brand_code: String?
    let brand_logo_url: String?
    let type_name: String?
    let type_code: String?
    let category_id: Int?
    let category_name: String?
    let category_code: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case brandId = "brandId"
        case typeId = "typeId"
        case name, code, description
        case maxLoadCapacity = "maxLoadCapacity"
        case maxHeight = "maxHeight"
        case maxRadius = "maxRadius"
        case enginePower = "enginePower"
        case specifications
        case imageUrl = "imageUrl"
        case brochureUrl = "brochureUrl"
        case videoUrl = "videoUrl"
        case releaseYear = "releaseYear"
        case isDiscontinued = "isDiscontinued"
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        
        // Flattened fields
        case brand_name, brand_code, brand_logo_url
        case type_name, type_code
        case category_id, category_name, category_code
    }
    
    // ✅ CUSTOM INITIALIZER FOR STRING TO DECIMAL CONVERSION
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Standard fields
        id = try container.decode(Int.self, forKey: .id)
        brandId = try container.decode(Int.self, forKey: .brandId)
        typeId = try container.decode(Int.self, forKey: .typeId)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // ✅ FIXED: Convert string values to Decimal
        if let capacityString = try container.decodeIfPresent(String.self, forKey: .maxLoadCapacity) {
            maxLoadCapacity = Decimal(string: capacityString)
        } else if let capacityDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxLoadCapacity) {
            maxLoadCapacity = capacityDecimal
        } else {
            maxLoadCapacity = nil
        }
        
        if let heightString = try container.decodeIfPresent(String.self, forKey: .maxHeight) {
            maxHeight = Decimal(string: heightString)
        } else if let heightDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxHeight) {
            maxHeight = heightDecimal
        } else {
            maxHeight = nil
        }
        
        if let radiusString = try container.decodeIfPresent(String.self, forKey: .maxRadius) {
            maxRadius = Decimal(string: radiusString)
        } else if let radiusDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxRadius) {
            maxRadius = radiusDecimal
        } else {
            maxRadius = nil
        }
        
        // Rest of the fields
        enginePower = try container.decodeIfPresent(Int.self, forKey: .enginePower)
        specifications = try container.decodeIfPresent([String: AnyCodable].self, forKey: .specifications)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        brochureUrl = try container.decodeIfPresent(String.self, forKey: .brochureUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        releaseYear = try container.decodeIfPresent(Int.self, forKey: .releaseYear)
        isDiscontinued = try container.decode(Bool.self, forKey: .isDiscontinued)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Flattened fields
        brand_name = try container.decodeIfPresent(String.self, forKey: .brand_name)
        brand_code = try container.decodeIfPresent(String.self, forKey: .brand_code)
        brand_logo_url = try container.decodeIfPresent(String.self, forKey: .brand_logo_url)
        type_name = try container.decodeIfPresent(String.self, forKey: .type_name)
        type_code = try container.decodeIfPresent(String.self, forKey: .type_code)
        category_id = try container.decodeIfPresent(Int.self, forKey: .category_id)
        category_name = try container.decodeIfPresent(String.self, forKey: .category_name)
        category_code = try container.decodeIfPresent(String.self, forKey: .category_code)
    }
}

/// Supporting response structures
struct CategoryCountResponse: Codable {
    let craneTypes: Int
}

struct ModelCountResponse: Codable {
    let craneModels: Int
}

/// ✅ FIXED: Crane Model Detail with String to Decimal conversion
struct CraneModelDetailAPIResponse: Codable {
    let id: Int
    let brandId: Int
    let typeId: Int
    let name: String
    let code: String
    let description: String?
    let maxLoadCapacity: Decimal?
    let maxHeight: Decimal?
    let maxRadius: Decimal?
    let enginePower: Int?
    let specifications: [String: AnyCodable]?
    let imageUrl: String?
    let brochureUrl: String?
    let videoUrl: String?
    let releaseYear: Int?
    let isDiscontinued: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let brand: CraneBrandDetailAPIResponse
    let type: CraneTypeDetailAPIResponse
    let usage_statistics: UsageStatisticsResponse
    
    private enum CodingKeys: String, CodingKey {
        case id
        case brandId = "brandId"
        case typeId = "typeId"
        case name, code, description
        case maxLoadCapacity = "maxLoadCapacity"
        case maxHeight = "maxHeight"
        case maxRadius = "maxRadius"
        case enginePower = "enginePower"
        case specifications
        case imageUrl = "imageUrl"
        case brochureUrl = "brochureUrl"
        case videoUrl = "videoUrl"
        case releaseYear = "releaseYear"
        case isDiscontinued = "isDiscontinued"
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case brand, type, usage_statistics
    }
    
    // ✅ CUSTOM INITIALIZER FOR STRING TO DECIMAL CONVERSION
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Standard fields
        id = try container.decode(Int.self, forKey: .id)
        brandId = try container.decode(Int.self, forKey: .brandId)
        typeId = try container.decode(Int.self, forKey: .typeId)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // ✅ FIXED: Convert string values to Decimal
        if let capacityString = try container.decodeIfPresent(String.self, forKey: .maxLoadCapacity) {
            maxLoadCapacity = Decimal(string: capacityString)
        } else if let capacityDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxLoadCapacity) {
            maxLoadCapacity = capacityDecimal
        } else {
            maxLoadCapacity = nil
        }
        
        if let heightString = try container.decodeIfPresent(String.self, forKey: .maxHeight) {
            maxHeight = Decimal(string: heightString)
        } else if let heightDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxHeight) {
            maxHeight = heightDecimal
        } else {
            maxHeight = nil
        }
        
        if let radiusString = try container.decodeIfPresent(String.self, forKey: .maxRadius) {
            maxRadius = Decimal(string: radiusString)
        } else if let radiusDecimal = try container.decodeIfPresent(Decimal.self, forKey: .maxRadius) {
            maxRadius = radiusDecimal
        } else {
            maxRadius = nil
        }
        
        // Rest of the fields
        enginePower = try container.decodeIfPresent(Int.self, forKey: .enginePower)
        specifications = try container.decodeIfPresent([String: AnyCodable].self, forKey: .specifications)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        brochureUrl = try container.decodeIfPresent(String.self, forKey: .brochureUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        releaseYear = try container.decodeIfPresent(Int.self, forKey: .releaseYear)
        isDiscontinued = try container.decode(Bool.self, forKey: .isDiscontinued)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        brand = try container.decode(CraneBrandDetailAPIResponse.self, forKey: .brand)
        type = try container.decode(CraneTypeDetailAPIResponse.self, forKey: .type)
        usage_statistics = try container.decode(UsageStatisticsResponse.self, forKey: .usage_statistics)
    }
}

struct CraneBrandDetailAPIResponse: Codable {
    let id: Int
    let name: String
    let code: String
    let logoUrl: String?
    let website: String?
    let description: String?
    let foundedYear: Int?
    let headquarters: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, code
        case logoUrl = "logoUrl"
        case website, description
        case foundedYear = "foundedYear"
        case headquarters
    }
}

struct CraneTypeDetailAPIResponse: Codable {
    let id: Int
    let categoryId: Int
    let name: String
    let code: String
    let description: String?
    let category: CraneCategoryAPIResponse
    
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "categoryId"
        case name, code, description, category
    }
}

struct UsageStatisticsResponse: Codable {
    let current_assignments: Int
    let active_projects: Int
    let assigned_operators: Int
    let assignments: [AssignmentInfoResponse]
}

struct AssignmentInfoResponse: Codable {
    let task_id: Int
    let task_title: String
    let project_id: Int?
    let project_title: String?
    let operator_name: String
    let assigned_at: Date?
}

/// ✅ Helper for JSON with Any values - Enhanced version
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let anyArray = array.map { AnyCodable($0) }
            try container.encode(anyArray)
        case let dictionary as [String: Any]:
            let anyDict = dictionary.mapValues { AnyCodable($0) }
            try container.encode(anyDict)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
