//
//  ContentView.swift
//  Instafilter
//
//  Created by Jakub Czerwiec  on 28/11/2024.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    
    @State private var filterName = "Sepia Tone"
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    var enabledChangeFilter: Bool {
        if processedImage != nil { false } else { true }
    }
    
    @State private var enableIntesity = true
    @State private var enableRadius = true
    @State private var enableScale = true
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var currentFilter2: CIFilter = CIFilter.pointillize()
    let context = CIContext()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        VStack {
                            Text("\(filterName)")
                            Spacer()
                            processedImage
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                HStack {
                    VStack {
                        Text("Intensity")
                        Slider(value: $filterIntensity)
                            .onChange(of: filterIntensity, applyProcessing)
                            .disabled(enableIntesity)
                        Text("Radius")
                        Slider(value: $filterRadius)
                            .onChange(of: filterRadius, applyProcessing)
                            .disabled(enableRadius)
                        Text("Scale")
                        Slider(value: $filterScale)
                            .disabled(enableScale)
                    }
                }
                
                HStack {
                    Button("Change filter", action: changeFilter)
                        .disabled(enabledChangeFilter)
                    
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize() )
                    filterName = "Crystallize"}
                Button("Edges") { setFilter(CIFilter.edges() )
                    filterName = "Edges"}
                Button("Gausian Blur") { setFilter(CIFilter.gaussianBlur() )
                    filterName = "Gausian Blur"}
                Button("Pixellate") { setFilter(CIFilter.pixellate() )
                    filterName = "Pixellate"}
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone() )
                    filterName = "Sepia Tone"}
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask() )
                    filterName = "Unsharp Mask"}
                Button("Vignette") { setFilter(CIFilter.vignette() )
                    filterName = "Vignette"}
                Button("Depth of Field") { setFilter(CIFilter.depthOfField() )
                    filterName = "Depth of Field"}
                Button("Sharpen Luminance") { setFilter(CIFilter.sharpenLuminance() )
                    filterName = "Sharpen Luminance"}
                Button("Pointillize") { setFilter(CIFilter.pointillize() )
                    filterName = "Pointillize"}
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
            enableIntesity = false
        } else {enableIntesity = true}
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)
            enableRadius = false
        } else {enableRadius = true}
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterScale * 10, forKey: kCIInputScaleKey)
            enableScale = false
        } else {enableScale = true}
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
