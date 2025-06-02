//
//  CustomerLogoPickerView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI
import PhotosUI
import Combine

struct CustomerLogoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var logoUrl: String?
    @State private var showImagePicker = false
    @State private var showPhotosPicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    let size: CGFloat
    let isEditable: Bool
    let placeholder: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        selectedImage: Binding<UIImage?>,
        logoUrl: Binding<String?>,
        size: CGFloat = 80,
        isEditable: Bool = true,
        placeholder: String = "Add Logo"
    ) {
        self._selectedImage = selectedImage
        self._logoUrl = logoUrl
        self.size = size
        self.isEditable = isEditable
        self.placeholder = placeholder
    }
    
    var body: some View {
        VStack {
            logoImageView
            
            if isEditable {
                editButton
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showActionSheet) {
            Button("Camera") {
                sourceType = .camera
                showImagePicker = true
            }
            
            Button("Photo Library") {
                showPhotosPicker = true
            }
            
            if selectedImage != nil || logoUrl != nil {
                Button("Remove Logo", role: .destructive) {
                    selectedImage = nil
                    logoUrl = nil
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                selectedImage: $selectedImage,
                sourceType: sourceType
            )
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        logoUrl = nil // Clear URL when new image is selected
                    }
                }
            }
        }
    }
    
    // MARK: - Logo Image View
    private var logoImageView: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                )
            
            Group {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size - 8, height: size - 8)
                        .clipShape(Circle())
                } else if let logoUrl = logoUrl, !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .ksrPrimary))
                    }
                    .frame(width: size - 8, height: size - 8)
                    .clipShape(Circle())
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: size * 0.3, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if size > 60 {
                            Text(placeholder)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            if isEditable {
                showActionSheet = true
            }
        }
    }
    
    // MARK: - Edit Button
    private var editButton: some View {
        Button {
            showActionSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedImage != nil || (logoUrl != nil && !logoUrl!.isEmpty) ? "pencil" : "plus")
                    .font(.system(size: 12, weight: .semibold))
                
                Text(selectedImage != nil || (logoUrl != nil && !logoUrl!.isEmpty) ? "Edit" : "Add Logo")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color.ksrPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.ksrPrimary.opacity(0.1))
            )
        }
        .padding(.top, 4)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        if selectedImage != nil || (logoUrl != nil && !logoUrl!.isEmpty) {
            return .clear
        }
        return colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    private var borderColor: Color {
        if selectedImage != nil || (logoUrl != nil && !logoUrl!.isEmpty) {
            return Color.ksrPrimary.opacity(0.3)
        }
        return Color.clear
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Customer Logo Manager View Model

class CustomerLogoManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var logoUrl: String?
    @Published var isUploading = false
    @Published var uploadError: String?
    @Published var uploadSuccess = false
    
    private let apiService = ChefAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func uploadLogo(for customerId: Int, completion: @escaping (Bool) -> Void) {
        guard let image = selectedImage else {
            uploadError = "No image selected"
            completion(false)
            return
        }
        
        isUploading = true
        uploadError = nil
        uploadSuccess = false
        
        #if DEBUG
        print("[CustomerLogoManager] Starting logo upload for customer \(customerId)")
        #endif
        
        // Use presigned URL method for better performance
        apiService.uploadCustomerLogoWithPresignedUrl(customerId: customerId, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isUploading = false
                    
                    if case .failure(let error) = result {
                        self?.uploadError = self?.errorMessage(from: error) ?? "Upload failed"
                        completion(false)
                        
                        #if DEBUG
                        print("[CustomerLogoManager] Upload failed: \(error)")
                        #endif
                    }
                },
                receiveValue: { [weak self] response in
                    self?.logoUrl = response.data.logo_url
                    self?.uploadSuccess = true
                    self?.selectedImage = nil // Clear selected image after successful upload
                    completion(true)
                    
                    #if DEBUG
                    print("[CustomerLogoManager] Upload successful: \(response.data.logo_url)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteLogo(for customerId: Int, completion: @escaping (Bool) -> Void) {
        isUploading = true
        uploadError = nil
        
        apiService.deleteCustomerLogo(customerId: customerId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isUploading = false
                    
                    if case .failure(let error) = result {
                        self?.uploadError = self?.errorMessage(from: error) ?? "Delete failed"
                        completion(false)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.logoUrl = nil
                    self?.selectedImage = nil
                    completion(true)
                    
                    #if DEBUG
                    print("[CustomerLogoManager] Logo deleted successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func reset() {
        selectedImage = nil
        logoUrl = nil
        uploadError = nil
        uploadSuccess = false
        isUploading = false
    }
    
    private func errorMessage(from error: BaseAPIService.APIError) -> String {
        switch error {
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let code, let message):
            if code == 413 {
                return "Image file is too large. Please choose a smaller image."
            }
            return message.isEmpty ? "Server error occurred" : message
        case .decodingError:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid server response"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Preview
struct CustomerLogoPickerView_Previews: PreviewProvider {
    @State static var selectedImage: UIImage? = nil
    @State static var logoUrl: String? = "https://example.com/logo.jpg"
    
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                CustomerLogoPickerView(
                    selectedImage: $selectedImage,
                    logoUrl: .constant(nil),
                    size: 80,
                    isEditable: true,
                    placeholder: "Add Logo"
                )
                
                CustomerLogoPickerView(
                    selectedImage: .constant(nil),
                    logoUrl: $logoUrl,
                    size: 60,
                    isEditable: false,
                    placeholder: "Logo"
                )
                
                CustomerLogoPickerView(
                    selectedImage: $selectedImage,
                    logoUrl: .constant(nil),
                    size: 120,
                    isEditable: true,
                    placeholder: "Company Logo"
                )
            }
            .padding()
            .preferredColorScheme(.light)
            
            VStack(spacing: 20) {
                CustomerLogoPickerView(
                    selectedImage: $selectedImage,
                    logoUrl: .constant(nil),
                    size: 80,
                    isEditable: true,
                    placeholder: "Add Logo"
                )
                
                CustomerLogoPickerView(
                    selectedImage: .constant(nil),
                    logoUrl: $logoUrl,
                    size: 60,
                    isEditable: false,
                    placeholder: "Logo"
                )
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
