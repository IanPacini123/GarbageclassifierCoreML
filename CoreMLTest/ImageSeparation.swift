//
//  ImageSeparation.swift
//  CoreMLTest
//
//  Created by Ian Pacini on 21/02/25.
//

import SwiftUI

struct ImageSeparation: View {
    var body: some View {
        Button {
            moveImagesToTestFolder()
        } label: {
            Text("Separar imagens!")
        }
    }
    
    private func getMainFolderURL() -> URL? {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let mainFolder = documentDirectory.appendingPathComponent("imagens", isDirectory: true)
            
            // Criar a pasta se não existir
            if !fileManager.fileExists(atPath: mainFolder.path) {
                do {
                    try fileManager.createDirectory(at: mainFolder, withIntermediateDirectories: true)
                } catch {
                    print("Erro ao criar a pasta principal:", error)
                    return nil
                }
            }
            
            return mainFolder
        }
        return nil
    }
    
    private func moveImagesToTestFolder() {
        guard let mainFolderURL = getMainFolderURL() else {
            print("Pasta principal não encontrada.")
            return
        }
        
        print(mainFolderURL)
        
        let fileManager = FileManager.default

        do {
            // Pegar as 6 subpastas dentro da pasta principal
            let subfolders = try fileManager.contentsOfDirectory(at: mainFolderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            for subfolder in subfolders {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: subfolder.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    
                    // Pegar todas as imagens dentro da subpasta
                    let imageFiles = try fileManager.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                        .filter { $0.pathExtension.lowercased() == "png" || $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }

                    // Definir 20% das imagens para mover
                    let countToMove = max(1, imageFiles.count / 5) // Pelo menos 1 arquivo
                    let imagesToMove = imageFiles.shuffled().prefix(countToMove)
                    
                    // Criar a pasta "teste" dentro da subpasta, se não existir
                    let testFolder = subfolder.appendingPathComponent("teste", isDirectory: true)
                    if !fileManager.fileExists(atPath: testFolder.path) {
                        try fileManager.createDirectory(at: testFolder, withIntermediateDirectories: true)
                    }
                    
                    // Mover os arquivos
                    for image in imagesToMove {
                        let destinationURL = testFolder.appendingPathComponent(image.lastPathComponent)
                        try fileManager.moveItem(at: image, to: destinationURL)
                    }
                    
                    print("Movidos \(countToMove) arquivos para \(testFolder.path)")
                }
            }
        } catch {
            print("Erro ao processar arquivos:", error)
        }
    }
}

#Preview {
    ImageSeparation()
}
