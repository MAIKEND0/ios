//
//  SignatureModalView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

struct SignatureModalView: View {
    @Binding var isPresented: Bool
    @State private var paths: [[CGPoint]] = []
    @State private var currentPath: [CGPoint] = []
    let onSave: (UIImage?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Timesheet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ksrDarkGray)
            
            // Obszar do rysowania podpisu
            Canvas { context, size in
                context.withCGContext { cgContext in
                    cgContext.setLineWidth(3)
                    cgContext.setStrokeColor(UIColor.black.cgColor)
                    cgContext.setLineCap(.round)
                    
                    for path in paths {
                        guard !path.isEmpty else { continue }
                        cgContext.beginPath()
                        cgContext.move(to: path[0])
                        for point in path.dropFirst() {
                            cgContext.addLine(to: point)
                        }
                        cgContext.strokePath()
                    }
                    
                    if !currentPath.isEmpty {
                        cgContext.beginPath()
                        cgContext.move(to: currentPath[0])
                        for point in currentPath.dropFirst() {
                            cgContext.addLine(to: point)
                        }
                        cgContext.strokePath()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        currentPath.append(value.location)
                    }
                    .onEnded { _ in
                        paths.append(currentPath)
                        currentPath = []
                    }
            )
            
            HStack(spacing: 16) {
                Button(action: {
                    paths = []
                    currentPath = []
                }) {
                    Text("Clear")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    let image = generateSignatureImage()
                    // Przywróć orientację pionową przed zamknięciem
                    OrientationManager.shared.lockOrientation(.portrait)
                    onSave(image)
                    isPresented = false
                }) {
                    Text("Save")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    // Przywróć orientację pionową przed zamknięciem
                    OrientationManager.shared.lockOrientation(.portrait)
                    onSave(nil)
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .frame(maxWidth: 600)
        .onAppear {
            // Dodatkowe zapewnienie, że orientacja zostanie ustawiona na poziomą
            OrientationManager.shared.lockOrientation(.landscape)
        }
    }
    
    private func generateSignatureImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 300))
        return renderer.image { context in
            context.cgContext.setLineWidth(3)
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineCap(.round)
            
            for path in paths {
                guard !path.isEmpty else { continue }
                context.cgContext.beginPath()
                context.cgContext.move(to: path[0])
                for point in path.dropFirst() {
                    context.cgContext.addLine(to: point)
                }
                context.cgContext.strokePath()
            }
        }
    }
}

struct SignatureModalView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureModalView(isPresented: .constant(true), onSave: { _ in })
            .preferredColorScheme(.light)
    }
}
