import SwiftUI

struct SyncProgressView: View {
    let currentItem: String?
    let progress: Double
    let totalItems: Int
    let syncedItems: Int
    
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    init(currentItem: String? = nil, progress: Double = 0, totalItems: Int = 0, syncedItems: Int = 0) {
        self.currentItem = currentItem
        self.progress = progress
        self.totalItems = totalItems
        self.syncedItems = syncedItems
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ksrInfo)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                Text("Syncing...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if totalItems > 0 {
                    Text("\(syncedItems)/\(totalItems)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if let currentItem = currentItem {
                Text(currentItem)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.ksrInfo, Color.ksrInfo.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            isAnimating = true
        }
    }
    
    // Compact version for toolbars
    var compact: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.ksrInfo)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            if totalItems > 0 {
                Text("\(syncedItems)/\(totalItems)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            } else {
                Text("Syncing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.ksrInfo)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(width: 40, height: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// Sheet presentation for detailed sync progress
struct SyncProgressSheet: View {
    let syncOperations: [SyncOperation]
    @Binding var isPresented: Bool
    
    struct SyncOperation: Identifiable {
        let id = UUID()
        let name: String
        let status: Status
        let error: String?
        
        enum Status {
            case pending
            case syncing
            case completed
            case failed
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(syncOperations) { operation in
                    HStack {
                        statusIcon(for: operation.status)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(operation.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if let error = operation.error {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sync Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusIcon(for status: SyncOperation.Status) -> some View {
        switch status {
        case .pending:
            Image(systemName: "clock.fill")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
        }
    }
}

// Preview
struct SyncProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncProgressView(
                currentItem: "Uploading work hours...",
                progress: 0.65,
                totalItems: 10,
                syncedItems: 6
            )
            
            SyncProgressView(
                progress: 0.3,
                totalItems: 5,
                syncedItems: 1
            )
            
            SyncProgressView().compact
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}