//
//  SharedTimesheetComponents.swift
//  KSR Cranes App
//
//  Shared components for Manager and Worker Timesheet views
//

import SwiftUI

// MARK: - Shared PDF viewer component
struct TimesheetPDFViewer: View {
    let url: URL
    let title: String
    let onClose: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDownloading = false
    @State private var showDownloadAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PDFViewer(source: PDFSource.url(url))
                
                if isDownloading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.ksrYellow)
                        
                        Text("Preparing PDF...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.ksrMediumGray.opacity(0.9))
                    )
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onClose()
                    }
                    .foregroundColor(.ksrYellow)
                    .disabled(isDownloading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sharePDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.ksrSuccess)
                    }
                    .disabled(isDownloading)
                }
            }
            .alert("Download Failed", isPresented: $showDownloadAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to download PDF for sharing. Please try again.")
            }
        }
    }
    
    private func sharePDF() {
        Task {
            await MainActor.run {
                isDownloading = true
            }
            
            do {
                let data = try await URLSession.shared.data(from: url).0
                
                await MainActor.run {
                    isDownloading = false
                    
                    let tempDir = NSTemporaryDirectory()
                    let filename = "Timesheet_\(title.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970)).pdf"
                    let tempPath = (tempDir as NSString).appendingPathComponent(filename)
                    let tempURL = URL(fileURLWithPath: tempPath)
                    
                    do {
                        try data.write(to: tempURL)
                        
                        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            
                            var topViewController = rootViewController
                            while let presentedViewController = topViewController.presentedViewController {
                                topViewController = presentedViewController
                            }
                            
                            topViewController.present(activityVC, animated: true)
                        }
                        
                    } catch {
                        showDownloadAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    showDownloadAlert = true
                }
            }
        }
    }
}
