//
//  PDFViewer.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 18/05/2025.
//

import SwiftUI
import PDFKit

// Wyliczenie do obsługi różnych źródeł PDF
enum PDFSource {
    case data(Data)
    case url(URL)
}

// Widok do wyświetlania PDF
struct PDFViewer: View {
    let source: PDFSource
    
    var body: some View {
        PDFKitView(source: source)
            .edgesIgnoringSafeArea(.bottom)
    }
}

// Komponent PDFKit do renderowania PDF
struct PDFKitView: UIViewRepresentable {
    let source: PDFSource
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        updatePDFView(pdfView)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        updatePDFView(uiView)
    }
    
    private func updatePDFView(_ pdfView: PDFView) {
        switch source {
        case .data(let data):
            pdfView.document = PDFDocument(data: data)
            #if DEBUG
            if pdfView.document == nil {
                print("[PDFKitView] Failed to create PDFDocument from data")
            } else {
                print("[PDFKitView] PDFDocument created successfully from data")
            }
            #endif
        case .url(let url):
            pdfView.document = PDFDocument(url: url)
            #if DEBUG
            if pdfView.document == nil {
                print("[PDFKitView] Failed to create PDFDocument from URL: \(url)")
            } else {
                print("[PDFKitView] PDFDocument created successfully from URL: \(url)")
            }
            #endif
        }
    }
}
