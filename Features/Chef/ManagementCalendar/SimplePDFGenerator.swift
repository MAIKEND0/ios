import Foundation
import PDFKit
import SwiftUI

class SimplePDFGenerator {
    private let viewModel: ChefManagementCalendarViewModel
    private let dateRange: (start: Date, end: Date)
    private let includeDetails: Bool
    private let includeWorkerInfo: Bool
    
    init(viewModel: ChefManagementCalendarViewModel, 
         dateRange: (start: Date, end: Date),
         includeDetails: Bool,
         includeWorkerInfo: Bool) {
        self.viewModel = viewModel
        self.dateRange = dateRange
        self.includeDetails = includeDetails
        self.includeWorkerInfo = includeWorkerInfo
    }
    
    func generatePDF() async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "KSR_Calendar_\(formatDateForFileName(dateRange.start))_\(formatDateForFileName(dateRange.end)).pdf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Create a simple text-based PDF using NSAttributedString
        let pdfData = try await generatePDFData()
        
        try pdfData.write(to: fileURL)
        
        print("📄 [PDF] Generated simple calendar PDF: \(fileName)")
        print("📍 [PDF] File saved at: \(fileURL.path)")
        
        // Verify file exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("✅ [PDF] File exists with size: \(fileSize) bytes")
        } else {
            print("❌ [PDF] File does not exist at path!")
        }
        
        return fileURL
    }
    
    private func generatePDFData() async throws -> Data {
        let pageSize = CGSize(width: 595, height: 842) // A4 size
        let margin: CGFloat = 50
        
        // Create mutable data
        let pdfData = NSMutableData()
        
        // Get content from MainActor context
        let content = await generatePDFContent()
        
        // Create PDF context using UIGraphics
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: pageSize), nil)
        UIGraphicsBeginPDFPage()
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            throw SimplePDFError.failedToCreateContext
        }
        
        // Draw content
        try drawContent(content, in: context, pageSize: pageSize, margin: margin)
        
        // End PDF
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
    
    @MainActor
    private func generatePDFContent() -> String {
        var content = ""
        
        // Header
        content += "KSR CRANES - MANAGEMENT CALENDAR REPORT\n"
        content += "=" + String(repeating: "=", count: 50) + "\n\n"
        
        // Date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        content += "Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))\n"
        content += "Generated: \(dateFormatter.string(from: Date()))\n\n"
        
        // Events section
        content += "CALENDAR EVENTS\n"
        content += "-" + String(repeating: "-", count: 30) + "\n\n"
        
        let events = getEventsInDateRange().sorted { $0.date < $1.date }
        
        if events.isEmpty {
            content += "No events found in the selected date range.\n\n"
        } else {
            for event in events {
                content += "• \(DateFormatter.userFriendly.string(from: event.date))\n"
                content += "  \(event.title) (\(event.type.displayName))\n"
                content += "  Priority: \(event.priority.displayName)\n"
                if !event.description.isEmpty {
                    content += "  Description: \(event.description)\n"
                }
                content += "\n"
            }
        }
        
        // Worker availability section (if requested)
        if includeWorkerInfo && viewModel.workerAvailabilityMatrix != nil {
            content += "WORKER AVAILABILITY\n"
            content += "-" + String(repeating: "-", count: 30) + "\n\n"
            
            if let matrix = viewModel.workerAvailabilityMatrix {
                for worker in matrix.workers.prefix(20) {
                    let utilization = Int(worker.weeklyStats.utilization * 100)
                    content += "• \(worker.worker.name) (\(worker.worker.role))\n"
                    content += "  Utilization: \(utilization)%\n"
                    content += "  Weekly Hours: \(String(format: "%.1f", worker.weeklyStats.totalHours))\n"
                    content += "  Projects: \(worker.weeklyStats.projectCount), Tasks: \(worker.weeklyStats.taskCount)\n\n"
                }
            }
        }
        
        // Summary
        content += "SUMMARY\n"
        content += "-" + String(repeating: "-", count: 30) + "\n\n"
        content += "Total Events: \(events.count)\n"
        
        if let summary = viewModel.calendarSummary {
            content += "Available Workers: \(summary.availableWorkers)\n"
            content += "Workers on Leave: \(summary.workersOnLeave)\n"
            content += "Capacity Utilization: \(String(format: "%.0f", summary.capacityUtilization * 100))%\n"
        }
        
        content += "\n\nGenerated by KSR Cranes Management System\n"
        
        return content
    }
    
    private func drawContent(_ content: String, in context: CGContext, pageSize: CGSize, margin: CGFloat) throws {
        let textRect = CGRect(x: margin, y: margin, 
                             width: pageSize.width - 2 * margin, 
                             height: pageSize.height - 2 * margin)
        
        // Create attributed string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: content, attributes: attributes)
        
        // Draw text
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        
        CTFrameDraw(frame, context)
    }
    
    @MainActor
    private func getEventsInDateRange() -> [ManagementCalendarEvent] {
        return viewModel.filteredEvents.filter { event in
            event.date >= dateRange.start && event.date <= dateRange.end
        }
    }
    
    private func formatDateForFileName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum SimplePDFError: Error, LocalizedError {
    case failedToCreateContext
    case failedToWrite
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateContext:
            return "Failed to create PDF context"
        case .failedToWrite:
            return "Failed to write PDF data"
        }
    }
}

