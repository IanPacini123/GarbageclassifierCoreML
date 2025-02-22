//
//  ImagePicking.swift
//  CoreMLTest
//
//  Created by Ian Pacini on 22/02/25.
//

import SwiftUI

struct ImagePicking: View {
    @Binding var selectedImage: UIImage?
    
    @Binding var isShowing: Bool
    
    private enum garbageAssets: String, CaseIterable {
        case Cardboard, Glass, Metal, Paper, Plastic
    }
    
    var body: some View {
        LazyVGrid(columns: [.init(), .init(), .init()]) {
            ForEach(garbageAssets.allCases, id: \.self) { garbageType in
                VStack {
                    ImageSquare(garbageType.rawValue)
                        .frame(width: 100, height: 100)
                    
                    Text(garbageType.rawValue)
                }
                .border(selectedImage == UIImage(imageLiteralResourceName: garbageType.rawValue) ? .blue : .black)
                .onTapGesture {
                    self.selectedImage = UIImage(imageLiteralResourceName: garbageType.rawValue)
                    self.isShowing.toggle()
                }
            }
        }
    }
}

private struct ImageSquare: View {
    let uiImage: UIImage
    
    init(_ imageName : String) {
        self.uiImage = UIImage(imageLiteralResourceName: imageName)
    }
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
    }
}

#Preview {
    @Previewable @State var selectedImage: UIImage?
    
    ImagePicking(selectedImage: $selectedImage, isShowing: .constant(false))
}
