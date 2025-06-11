import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfURL: URL
    let onShare: () -> Void
    let onDismiss: () -> Void
    
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // PDF Viewer
                ZStack {
                    PDFKitRepresentable(
                        url: pdfURL,
                        currentPage: $currentPage,
                        totalPages: $totalPages,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage
                    )
                    .opacity(isLoading ? 0 : 1)
                    
                    if isLoading {
                        VStack(spacing: 20) {
                            if errorMessage == nil {
                                ProgressView("Loading PDF...")
                            }
                            
                            if let error = errorMessage {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                
                                Text("You can still share the PDF file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                    }
                }
                
                // Page navigation bar
                if !isLoading && totalPages > 1 {
                    HStack {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        .disabled(currentPage <= 1)
                        
                        Spacer()
                        
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: nextPage) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                        .disabled(currentPage >= totalPages)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onShare) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .foregroundColor(.ksrPrimary)
                        .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    private func previousPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
    }
    
    private func nextPage() {
        if currentPage < totalPages {
            currentPage += 1
        }
    }
}

// PDFKit View Wrapper
struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        
        // Load PDF document
        print("🔍 [PDFPreview] Attempting to load PDF from URL: \(url.path)")
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: url.path) {
            print("✅ [PDFPreview] File exists at path")
            
            // Try to load PDF
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async {
                    pdfView.document = document
                    self.totalPages = document.pageCount
                    self.isLoading = false
                    self.errorMessage = nil
                    print("✅ [PDFPreview] Successfully loaded PDF with \(document.pageCount) pages")
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load PDF document"
                    self.isLoading = false
                    print("❌ [PDFPreview] PDFDocument failed to initialize from URL")
                }
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "PDF file not found at specified location"
                self.isLoading = false
                print("❌ [PDFPreview] File does not exist at path: \(url.path)")
            }
        }
        
        // Set up notification observer for page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        context.coordinator.pdfView = pdfView
        context.coordinator.parent = self
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update current page if changed externally
        if let document = pdfView.document,
           let currentPageObj = document.page(at: currentPage - 1),
           pdfView.currentPage != currentPageObj {
            pdfView.go(to: currentPageObj)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFKitRepresentable
        weak var pdfView: PDFView?
        
        init(_ parent: PDFKitRepresentable) {
            self.parent = parent
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = pdfView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }
            
            let pageIndex = document.index(for: currentPage)
            
            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex + 1
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// Preview provider
struct PDFPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PDFPreviewView(
            pdfURL: URL(string: "https://example.com/sample.pdf")!,
            onShare: {},
            onDismiss: {}
        )
    }
}