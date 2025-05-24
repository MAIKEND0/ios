//  TimesheetReceiptView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 16/05/2025.
//

import SwiftUI
import PDFKit

// Struktura opakowująca URL, zgodna z Identifiable
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct TimesheetReceiptView: View {
    let entry: ManagerAPIService.WorkHourEntry?
    let timesheetData: Data
    let signatureImage: UIImage
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var tempPDFURL: IdentifiableURL?
    @State private var errorMessage: String?

    private let gradientGreen = LinearGradient(
        colors: [Color(hex: "66bb6a"), Color(hex: "43a047")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Niestandardowy przycisk zamykania
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.ksrDarkGray)
                            .padding()
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Sekcja potwierdzenia
                        confirmationSection()

                        // Sekcja szczegółów wpisu
                        if let entry = entry {
                            entryDetailsSection(entry: entry)
                        }

                        // Podgląd pliku PDF
                        pdfPreviewSection()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Pasek przycisków
                HStack(spacing: 10) {
                    Button(action: {
                        if let url = savePDFToTemporaryFile() {
                            tempPDFURL = IdentifiableURL(url: url)
                        } else {
                            errorMessage = "Failed to prepare PDF for sharing"
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .padding()
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    Button(action: {
                        printPDF()
                    }) {
                        Image(systemName: "printer")
                            .padding()
                            .frame(width: 50, height: 50)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Timesheet Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $tempPDFURL) { identifiableURL in
                ShareSheet(activityItems: [identifiableURL.url])
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func confirmationSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timesheet Confirmed")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            Text("The timesheet has been successfully confirmed. Below are the details of the entry and the generated timesheet document.")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradientGreen)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }

    private func entryDetailsSection(entry: ManagerAPIService.WorkHourEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timesheet Details")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)

            HStack {
                Text("Work Date:")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                Spacer()
                Text(entry.workDateFormatted)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }

            if let startTime = entry.startTimeFormatted, let endTime = entry.endTimeFormatted {
                HStack {
                    Text("Hours:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text("\(startTime) – \(endTime)")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }

            if let tasks = entry.tasks {
                HStack {
                    Text("Task:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text(tasks.title)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }

            if let employee = entry.employees {
                HStack {
                    Text("Worker:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text(employee.name)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }

            if let description = entry.description, !description.isEmpty {
                HStack(alignment: .top) {
                    Text("Notes:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }

    private func pdfPreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timesheet Document")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)

            PDFViewer(source: PDFSource.data(timesheetData))
                .frame(height: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private func savePDFToTemporaryFile() -> URL? {
        let fileManager = FileManager.default
        let fileName = "Timesheet_\(Date().timeIntervalSince1970).pdf"
        let fileURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try timesheetData.write(to: fileURL)
            #if DEBUG
            print("[TimesheetReceiptView] Temporary PDF saved to: \(fileURL.path)")
            #endif
            return fileURL
        } catch {
            #if DEBUG
            print("[TimesheetReceiptView] Error saving temporary PDF: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func printPDF() {
        #if DEBUG
        print("[TimesheetReceiptView] Print button tapped")
        #endif
        
        let printController = UIPrintInteractionController.shared
        printController.printingItem = timesheetData
        printController.present(animated: true) { controller, completed, error in
            if let error = error {
                #if DEBUG
                print("[TimesheetReceiptView] Printing failed: \(error.localizedDescription)")
                #endif
            } else if completed {
                #if DEBUG
                print("[TimesheetReceiptView] Printing completed successfully")
                #endif
            } else {
                #if DEBUG
                print("[TimesheetReceiptView] Printing cancelled")
                #endif
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
