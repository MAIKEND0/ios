// ProfilePictureView.swift
import SwiftUI
import PhotosUI

struct ProfilePictureView: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture Display
            profileImageView
            
            // Action Buttons
            actionButtonsView
        }
        .padding()
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, _ in
            Task {
                if let selectedItem = selectedItem,
                   let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    viewModel.uploadProfilePicture(image)
                } else {
                    viewModel.showError("Failed to load selected image")
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Profile Picture"),
                message: Text("Choose an option"),
                buttons: [
                    .default(Text("Choose from Library")) {
                        showingImagePicker = true
                    },
                    .destructive(Text("Remove Picture")) {
                        viewModel.deleteProfilePicture()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Profile Image View
    
    private var profileImageView: some View {
        ZStack {
            // Background Circle
            Circle()
                .fill(Color.ksrLightGray)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(Color.ksrPrimary, lineWidth: 3)
                )
            
            // Profile Image or Placeholder
            Group {
                if let profilePictureUrl = viewModel.profileData.profilePictureUrl,
                   !profilePictureUrl.isEmpty,
                   let url = URL(string: profilePictureUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                } else {
                    // Placeholder Icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.ksrSecondary)
                }
            }
            
            // Loading Overlay
            if viewModel.isUploadingImage {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 120, height: 120)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
            
            // Camera Icon Overlay
            if !viewModel.isUploadingImage {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingActionSheet = true
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.ksrPrimary)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: -8, y: -8)
                    }
                }
                .frame(width: 120, height: 120)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Supervisor Name
            Text(viewModel.profileData.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.ksrDarkGray)
            
            Text(viewModel.profileData.role)
                .font(.subheadline)
                .foregroundColor(.ksrSecondary)
            
            // Action Buttons
            HStack(spacing: 16) {
                // Change Picture Button
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Change Photo")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.ksrPrimary)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isUploadingImage)
                
                // Remove Picture Button (only show if picture exists)
                if viewModel.profileData.profilePictureUrl != nil {
                    Button(action: {
                        viewModel.deleteProfilePicture()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .foregroundColor(.ksrError)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ksrError.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isUploadingImage)
                }
            }
            
            // Upload Status
            if viewModel.isUploadingImage {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading...")
                        .font(.caption)
                        .foregroundColor(.ksrSecondary)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Compact Version

struct CompactProfilePictureView: View {
    @ObservedObject var viewModel: ManagerProfileViewModel
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.ksrLightGray)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.ksrPrimary, lineWidth: 2)
                    )
                
                if let profilePictureUrl = viewModel.profileData.profilePictureUrl,
                   !profilePictureUrl.isEmpty,
                   let url = URL(string: profilePictureUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                    .frame(width: 55, height: 55)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.ksrSecondary)
                }
                
                if viewModel.isUploadingImage {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 60, height: 60)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
            .onTapGesture {
                showingImagePicker = true
            }
            
            // Name and Role
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profileData.name)
                    .font(.headline)
                    .foregroundColor(.ksrDarkGray)
                
                Text(viewModel.profileData.role)
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            
            Spacer()
            
            // Change Button
            Button(action: {
                showingImagePicker = true
            }) {
                Image(systemName: "camera")
                    .foregroundColor(.ksrPrimary)
            }
            .disabled(viewModel.isUploadingImage)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, _ in
            Task {
                if let selectedItem = selectedItem,
                   let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.uploadProfilePicture(image)
                } else {
                    viewModel.showError("Failed to load selected image")
                }
            }
        }
    }
}

// MARK: - Preview

struct ProfilePictureView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePictureView(viewModel: ManagerProfileViewModel())
            .padding()
    }
}
