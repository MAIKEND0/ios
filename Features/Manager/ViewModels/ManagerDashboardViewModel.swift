//
//  ManagerDashboardViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 16/05/2025.
//

import Foundation
import Combine
import SwiftUI
import PDFKit

class ManagerDashboardViewModel: ObservableObject {
    @Published var supervisorTasks: [ManagerAPIService.Task] = []
    @Published var pendingEntriesByTask: [TaskWeekEntry] = []
    @Published var selectedMonday: Date = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    @Published var pendingHoursCount: Int = 0
    @Published var activeWorkersCount: Int = 0
    @Published var totalApprovedHours: Double = 0
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    private var isProcessingApproval: Bool = false
    private var isViewActive: Bool = true
    private var lastLoadTime: Date?
    private let managerService = ManagerAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    struct TaskWeekEntry: Identifiable {
        let id: String
        let taskId: Int
        let weekNumber: Int
        let year: Int
        let taskTitle: String
        let entries: [ManagerAPIService.WorkHourEntry]
        let totalKm: Double
        let canBeConfirmed: Bool

        init(taskId: Int, weekNumber: Int, year: Int, taskTitle: String, entries: [ManagerAPIService.WorkHourEntry], totalKm: Double) {
            self.taskId = taskId
            self.weekNumber = weekNumber
            self.year = year
            self.taskTitle = taskTitle
            self.entries = entries
            self.totalKm = totalKm
            self.id = "\(taskId)-\(weekNumber)-\(year)"
            self.canBeConfirmed = entries.allSatisfy { entry in
                guard let start = entry.start_time, let end = entry.end_time else { return false }
                return start < end && entry.confirmation_status != "confirmed"
            }
        }
    }

    func viewAppeared() {
        isViewActive = true
        loadData()
    }

    func viewDisappeared() {
        isViewActive = false
        cancellables.removeAll()
    }

    func loadData() {
        guard lastLoadTime == nil || Date().timeIntervalSince(lastLoadTime!) > 5 else {
            #if DEBUG
            print("[ManagerDashboardViewModel] Skipped data load due to recent refresh")
            #endif
            return
        }
        lastLoadTime = Date()
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStartStr = formatter.string(from: selectedMonday)

        Publishers.Zip(
            managerService.fetchSupervisorTasks(supervisorId: 0),
            managerService.fetchPendingWorkEntriesForManager(weekStartDate: weekStartStr)
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completionStatus in
            guard let self = self, self.isViewActive else { return }
            self.isLoading = false
            if case .failure(let error) = completionStatus {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
            }
        }, receiveValue: { [weak self] tasks, entries in
            guard let self = self, self.isViewActive else { return }
            self.supervisorTasks = tasks
            let pendingEntries = entries.filter { $0.confirmation_status != "confirmed" }
            let grouped = Dictionary(grouping: pendingEntries) { $0.task_id }
            self.pendingEntriesByTask = grouped.map { taskId, entries in
                let taskTitle = entries.first?.tasks?.title ?? "Task ID: \(taskId)"
                let weekNumber = Calendar.current.component(.weekOfYear, from: self.selectedMonday)
                let year = Calendar.current.component(.year, from: self.selectedMonday)
                let totalKm = entries.reduce(0.0) { sum, entry in
                    sum + (entry.km ?? 0.0)
                }
                return TaskWeekEntry(
                    taskId: taskId,
                    weekNumber: weekNumber,
                    year: year,
                    taskTitle: taskTitle,
                    entries: entries,
                    totalKm: totalKm
                )
            }.sorted { $0.taskId < $1.taskId }
            self.updateSummaryStats()
            self.isLoading = false
        })
        .store(in: &cancellables)
    }

    func changeWeek(by offset: Int) {
        let calendar = Calendar.current
        if let newMonday = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedMonday) {
            selectedMonday = newMonday
            loadData()
        }
    }

    func approveTaskWeekWithSignature(_ taskWeek: TaskWeekEntry, signatureImage: UIImage, completionHandler: @escaping (String?) -> Void) {
        guard !isProcessingApproval else {
            #if DEBUG
            print("[ManagerDashboardViewModel] Ignoring approval request - processing in progress")
            #endif
            return
        }

        isProcessingApproval = true
        isLoading = true

        guard let pdfData = generateTimesheetPDF(taskWeek: taskWeek, signatureImage: signatureImage) else {
            isProcessingApproval = false
            isLoading = false
            self.alertTitle = "Error"
            self.alertMessage = "Failed to generate PDF"
            self.showAlert = true
            completionHandler(nil)
            return
        }

        #if DEBUG
        print("[ManagerDashboardViewModel] PDF generated, size: \(pdfData.count) bytes")
        #endif
        
        let entriesToConfirm = taskWeek.entries.map { entry in
            ManagerAPIService.UpdateWorkEntryRequest(
                entry_id: entry.entry_id,
                confirmation_status: "confirmed",
                work_date: entry.work_date,
                task_id: entry.task_id,
                employee_id: entry.employee_id,
                rejection_reason: nil,
                km: entry.km
            )
        }
        
        managerService.approveEntriesWithoutPDF(entries: entriesToConfirm)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isProcessingApproval = false
                    self?.isLoading = false
                    self?.alertTitle = "Error"
                    self?.alertMessage = "Failed to approve entries: \(error.localizedDescription)"
                    self?.showAlert = true
                    completionHandler(nil)
                }
                self?.loadData()
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                
                let employeeId = taskWeek.entries.first?.employee_id ?? 0
                let taskId = taskWeek.taskId
                let entryIds = taskWeek.entries.map { $0.entry_id }
                
                self.managerService.uploadPDF(
                    pdfData: pdfData,
                    employeeId: employeeId,
                    taskId: taskId,
                    weekNumber: taskWeek.weekNumber,
                    year: taskWeek.year,
                    entryIds: entryIds
                )
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.isProcessingApproval = false
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.alertTitle = "Warning"
                        self?.alertMessage = "Entries approved but PDF upload failed: \(error.localizedDescription)"
                        self?.showAlert = true
                        let fileURL = self?.savePdfDataToTempFile(pdfData, fileName: "timesheet-\(taskWeek.id).pdf")
                        completionHandler(fileURL?.absoluteString)
                    }
                    self?.loadData()
                }, receiveValue: { [weak self] response in
                    self?.pendingEntriesByTask.removeAll { $0.id == taskWeek.id }
                    self?.updateSummaryStats()
                    
                    #if DEBUG
                    print("[ManagerDashboardViewModel] PDF uploaded successfully, URL: \(response.timesheetUrl)")
                    #endif
                    
                    let fileURL = self?.savePdfDataToTempFile(pdfData, fileName: "timesheet-\(taskWeek.id).pdf")
                    completionHandler(fileURL?.absoluteString)
                    self?.loadData()
                })
                .store(in: &self.cancellables)
            })
            .store(in: &cancellables)
    }

    private func savePdfDataToTempFile(_ pdfData: Data, fileName: String) -> URL? {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: fileURL)
            #if DEBUG
            print("[ManagerDashboardViewModel] PDF saved at: \(fileURL.absoluteString)")
            #endif
            return fileURL
        } catch {
            #if DEBUG
            print("[ManagerDashboardViewModel] Error saving PDF: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    func generateTimesheetPDF(taskWeek: TaskWeekEntry, signatureImage: UIImage) -> Data? {
        let pageWidth: CGFloat = 595 // A4 in points
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            let darkTextColor = UIColor.black
            let tableLineColor = UIColor.gray.withAlphaComponent(0.5)
            
            let pageIndicatorAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            let pageIndicator = NSAttributedString(string: "1 of 1", attributes: pageIndicatorAttributes)
            
            context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.2).cgColor)
            context.cgContext.fill(CGRect(x: margin, y: yPosition, width: 90, height: 24))
            pageIndicator.draw(in: CGRect(x: margin + 5, y: yPosition + 2, width: 80, height: 20))
            
            if let logoImage = UIImage(named: "logo-horizontal") {
                let logoAspectRatio = logoImage.size.width / logoImage.size.height
                let logoHeight: CGFloat = 40
                let logoWidth = logoHeight * logoAspectRatio
                let logoX = (pageWidth - logoWidth) / 2
                logoImage.draw(in: CGRect(x: logoX, y: yPosition + 30, width: logoWidth, height: logoHeight))
                #if DEBUG
                print("[ManagerDashboardViewModel] Logo rendered with width: \(logoWidth), height: \(logoHeight)")
                #endif
            }
            
            let docTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: darkTextColor
            ]
            let docTitle = NSAttributedString(string: "KSR Cranes - Timesheet", attributes: docTitleAttributes)
            let docTitleSize = docTitle.size()
            docTitle.draw(at: CGPoint(x: (pageWidth - docTitleSize.width) / 2, y: yPosition + 80))
            
            yPosition += 110
            
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: darkTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            let detailsTitle = NSAttributedString(string: "Timesheet Details", attributes: sectionTitleAttributes)
            detailsTitle.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 15))
            yPosition += 20
            
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: darkTextColor
            ]
            
            let employeeName = taskWeek.entries.first?.employees?.name ?? "Unknown"
            let employeeId = taskWeek.entries.first?.employee_id ?? 0
            let taskTitle = taskWeek.taskTitle
            let taskId = taskWeek.taskId
            let projectTitle = taskWeek.entries.first?.tasks?.project?.title ?? "Unknown"
            
            let details = [
                "Employee: \(employeeName) (ID: \(employeeId))",
                "Task: \(taskTitle) (ID: \(taskId))",
                "Project: \(projectTitle)",
                "Week: \(taskWeek.weekNumber), \(String(taskWeek.year))" // Poprawka formatowania roku
            ]
            
            for (index, detail) in details.enumerated() {
                let detailText = NSAttributedString(string: detail, attributes: detailsAttributes)
                detailText.draw(in: CGRect(x: margin, y: yPosition + CGFloat(index * 20), width: pageWidth - 2*margin, height: 20))
            }
            yPosition += CGFloat(details.count * 20) + 20
            
            let hoursTitle = NSAttributedString(string: "Work Hours", attributes: sectionTitleAttributes)
            hoursTitle.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 15))
            yPosition += 25
            
            let tableHeaders = ["Date", "Day", "Start", "End", "Pause", "Hours", "Km"]
            let columnWidths: [CGFloat] = [90, 80, 70, 70, 70, 70, 60]
            let tableWidth: CGFloat = columnWidths.reduce(0, +)
            let tableX = margin
            let tableStartY = yPosition
            
            context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.2).cgColor)
            context.cgContext.fill(CGRect(x: tableX, y: tableStartY, width: tableWidth, height: 25))
            
            var xPos = tableX
            for (index, header) in tableHeaders.enumerated() {
                let headerAttr = NSAttributedString(string: header, attributes: sectionTitleAttributes)
                headerAttr.draw(in: CGRect(x: xPos + 5, y: tableStartY + 5, width: columnWidths[index] - 10, height: 20))
                xPos += columnWidths[index]
            }
            
            context.cgContext.setStrokeColor(tableLineColor.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: tableX, y: tableStartY + 25))
            context.cgContext.addLine(to: CGPoint(x: tableX + tableWidth, y: tableStartY + 25))
            context.cgContext.strokePath()
            
            yPosition += 25
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            dayFormatter.locale = Locale(identifier: "da-DK")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            let sortedEntries = taskWeek.entries.sorted { $0.work_date < $1.work_date }
            
            context.cgContext.setStrokeColor(tableLineColor.cgColor)
            context.cgContext.setLineWidth(0.5)
            
            var totalHours: Double = 0
            var totalKm: Double = 0
            let rowHeight: CGFloat = 25
            let tableRowsStartY = yPosition
            
            for (rowIndex, entry) in sortedEntries.enumerated() {
                guard let start = entry.start_time, let end = entry.end_time else { continue }
                
                let rowY = tableRowsStartY + CGFloat(rowIndex) * rowHeight
                
                if rowIndex % 2 == 1 {
                    context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.05).cgColor)
                    context.cgContext.fill(CGRect(x: tableX, y: rowY, width: tableWidth, height: rowHeight))
                }
                
                let dateStr = dateFormatter.string(from: entry.work_date)
                let dayStr = dayFormatter.string(from: entry.work_date)
                let startStr = timeFormatter.string(from: start)
                let endStr = timeFormatter.string(from: end)
                let pauseStr = "\(entry.pause_minutes ?? 0) min"
                
                let hours = (end.timeIntervalSince(start) - Double(entry.pause_minutes ?? 0) * 60) / 3600
                totalHours += hours
                let hoursStr = String(format: "%.2f", hours)
                let kmStr = entry.km != nil ? String(format: "%.2f", entry.km!) : "-"
                totalKm += entry.km ?? 0.0
                
                let rowData = [dateStr, dayStr, startStr, endStr, pauseStr, hoursStr, kmStr]
                xPos = tableX
                
                for (index, data) in rowData.enumerated() {
                    let cellAttr = NSAttributedString(string: data, attributes: detailsAttributes)
                    cellAttr.draw(in: CGRect(x: xPos + 5, y: rowY + 5, width: columnWidths[index] - 10, height: rowHeight - 5))
                    xPos += columnWidths[index]
                }
                
                context.cgContext.move(to: CGPoint(x: tableX, y: rowY + rowHeight))
                context.cgContext.addLine(to: CGPoint(x: tableX + tableWidth, y: rowY + rowHeight))
                context.cgContext.strokePath()
            }
            
            xPos = tableX
            for i in 0...columnWidths.count {
                context.cgContext.move(to: CGPoint(x: xPos, y: tableStartY))
                context.cgContext.addLine(to: CGPoint(x: xPos, y: tableRowsStartY + CGFloat(sortedEntries.count) * rowHeight))
                context.cgContext.strokePath()
                if i < columnWidths.count {
                    xPos += columnWidths[i]
                }
            }
            
            yPosition = tableRowsStartY + CGFloat(sortedEntries.count) * rowHeight + 15
            
            let totalHoursAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: darkTextColor
            ]
            
            let totalHoursLabel = NSAttributedString(string: "Total Hours: \(String(format: "%.2f", totalHours))", attributes: totalHoursAttributes)
            totalHoursLabel.draw(in: CGRect(x: pageWidth - margin - 280, y: yPosition, width: 150, height: 20))
            
            let totalKmLabel = NSAttributedString(string: "Total Km: \(String(format: "%.2f", totalKm))", attributes: totalHoursAttributes)
            totalKmLabel.draw(in: CGRect(x: pageWidth - margin - 130, y: yPosition, width: 130, height: 20))
            
            yPosition += 30
            
            let approvalTitle = NSAttributedString(string: "Approval", attributes: sectionTitleAttributes)
            approvalTitle.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 15))
            yPosition += 20
            
            let approverName = "John Kowalski"
            let currentDate = Date()
            let dateStr = DateFormatter.localizedString(from: currentDate, dateStyle: .medium, timeStyle: .none)
            
            let approvalDetails = [
                "Approved by: \(approverName)",
                "Confirmation Date: \(dateStr)"
            ]
            
            for (index, detail) in approvalDetails.enumerated() {
                let detailText = NSAttributedString(string: detail, attributes: detailsAttributes)
                detailText.draw(in: CGRect(x: margin, y: yPosition + CGFloat(index * 20), width: pageWidth - 2*margin, height: 20))
            }
            yPosition += CGFloat(approvalDetails.count * 20) + 10
            
            let eSignText = NSAttributedString(string: "Electronic Signature:", attributes: detailsAttributes)
            eSignText.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 20))
            yPosition += 20
            
            signatureImage.draw(in: CGRect(x: margin, y: yPosition, width: 120, height: 40))
            yPosition += 60
            
            let companyTitle = NSAttributedString(string: "Company Details", attributes: sectionTitleAttributes)
            companyTitle.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 15))
            yPosition += 20
            
            let companyDetails = [
                "KSR Cranes",
                "Eskebuen 49",
                "2620 Albertslund, Danmark",
                "+4523262064",
                "CVR: 39095939"
            ]
            
            for (index, detail) in companyDetails.enumerated() {
                let detailText = NSAttributedString(string: detail, attributes: detailsAttributes)
                detailText.draw(in: CGRect(x: margin, y: yPosition + CGFloat(index * 20), width: pageWidth - 2*margin, height: 20))
            }
            yPosition += CGFloat(companyDetails.count * 20) + 20
            
            let thankYouAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            let thankYou = NSAttributedString(string: "Thank you for your cooperation.", attributes: thankYouAttributes)
            thankYou.draw(in: CGRect(x: margin, y: yPosition, width: pageWidth - 2*margin, height: 15))
            
            #if DEBUG
            print("[ManagerDashboardViewModel] PDF generated with data size: \(renderer.pdfData { _ in }.count) bytes")
            #endif
        }
    }

    func rejectEntry(_ entry: ManagerAPIService.WorkHourEntry, rejectionReason: String) {
        isLoading = true
        managerService.updateWorkEntryStatus(entry: entry, confirmationStatus: "rejected", rejectionReason: rejectionReason)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionStatus in
                guard let self = self, self.isViewActive else { return }
                self.isLoading = false
                if case .failure(let error) = completionStatus {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to reject entry: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self, self.isViewActive else { return }
                self.loadData()
            })
            .store(in: &cancellables)
    }

    private func updateSummaryStats() {
        pendingHoursCount = pendingEntriesByTask.reduce(0) { count, taskWeek in
            count + taskWeek.entries.count
        }

        activeWorkersCount = Set(pendingEntriesByTask.flatMap { $0.entries }.map { $0.employee_id }).count

        totalApprovedHours = pendingEntriesByTask.reduce(0.0) { sum, taskWeek in
            sum + taskWeek.entries.reduce(0.0) { innerSum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return innerSum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return innerSum + max(0, (interval - pauseSeconds) / 3600)
            }
        }
    }
}
