//
// Project: PhotoPickersDemo2026
//  File: ContentView.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger


import SwiftUI
import PhotosUI
import AVKit

struct ContentView: View {
    @State private var selectedItem: [PhotosPickerItem] = []
    @State private var mediaItems: [MediaItem] = []
    var body: some View {
        VStack {
            
            if !mediaItems.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10){
                        ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, item in
                            
                            switch item {
                            case .image(let image):
                                image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(12)
                                
                            case .video(let url):
                                VideoPlayer(player: AVPlayer(url: url))
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(12)
                                    .disabled(true)
                            }
                            
                        }
                    }
                }
                
            } else {
                Text("No image selected")
                
            }
            
            PhotosPicker(selection: $selectedItem, maxSelectionCount: 5, matching: .any(of: [.images, .videos])) {
                Label("Select Media", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(.borderedProminent)
            
        }
        .padding()
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                mediaItems = [] // clear previous images
                for item in newValue {
                    if item.supportedContentTypes.contains(where: { $0.conforms(to: .image)}){
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data){
                        mediaItems.append(.image(Image(uiImage: uiImage)))
                    }
                    }
                    else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie)}) {
                        if let movie = try? await item.loadTransferable(type: Movie.self) {
                            mediaItems.append(.video(movie.url))
                        }
                    }
                }
            }
        }
    }
    
    //    private func loadImage(from item: PhotosPickerItem?) async {
    //        guard let item else {
    //            selectedItem = nil
    //            return
    //        }
    //        if let data = try? await item.loadTransferable(type: Data.self) {
    //            if let uiImage = UIImage(data: data) {
    //                selectedImage = Image(uiImage: uiImage)
    //            }
    //        }
    //    }
}

#Preview {
    ContentView()
}

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { recieved in
            let copy = URL.documentsDirectory.appending(path: "movie.mov")
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: recieved.file, to: copy)
            return Self(url: copy)
        }
    }
}
