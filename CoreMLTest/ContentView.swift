//
//  ContentView.swift
//  CoreMLTest
//
//  Created by Ian Pacini on 21/02/25.
//

import SwiftUI
import CoreML
import PhotosUI
import Vision

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var predictionValues: [String: Double].Element?
    
    @State private var isShowingPickImageFromApp: Bool = false
    
    var body: some View {
        VStack {
            PhotosPicker("Pick an Image from phone", selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
            
            Button("Pick an Image from app") {
                isShowingPickImageFromApp.toggle()
            }
            
            Button("Predict!") {
                Task {
                    self.predictionValues = await garbagePredict(image: selectedImage)
                }
            }
            
            if let predictionValues = predictionValues {
                
                Text("Posso dizer que a imagem é \(predictionValues.key) com \(predictionValues.value * 100)% de certeza!")
            }
            
            if let image = selectedImage {
                Image(uiImage: image)
            }
        }
        .padding()
        .sheet(isPresented: $isShowingPickImageFromApp) {
            ImagePicking(selectedImage: $selectedImage, isShowing: $isShowingPickImageFromApp)
        }
    }
    
    func garbagePredict(image: UIImage?) async -> [String: Double].Element? {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        
        guard let uiimage = image, let pixelBuffer = convertUIImageToCVPixelBuffer(image: uiimage, size: .init(width: 360, height: 360)) else {
            print("Could not convert image to pixel buffer.")
            return nil
        }
        
        do {
            let model = try GarbageClassifier(configuration: config)
            print("loaded model: \(model)")
            
            let prediction = try model.prediction(image: pixelBuffer)
            
            if let bestPrediction = prediction.targetProbability.max(by: { $0.value < $1.value }) {
                return (bestPrediction.key, bestPrediction.value)
            }
            
            return nil
            
        } catch {
            print("Error during prediction: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertUIImageToCVPixelBuffer(image: UIImage, size: CGSize) -> CVPixelBuffer? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let cgImage = resizedImage.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                         kCVPixelFormatType_32ARGB, attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Failed to create pixel buffer")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}

#Preview {
    ContentView()
}
