//
//  ContentView.swift
//  InstaFilter
//
//  Created by Robin Phillips on 08/08/2021.
//

import SwiftUI

import CoreImage
import CoreImage.CIFilterBuiltins





struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    //@State private var currentFilter = CIFilter.sepiaTone()
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var showingFilterSheet = false
    @State private var processedImage: UIImage?
    @State private var noImageAlert = false
    @State private var formattedFilterName = ""
    
    let ciPrefix = "CI"
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    // display the image
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    // select an image
                    self.showingImagePicker = true
                }
                
                HStack {
                    Text("Radius")
                        //.multilineTextAlignment(.leading)
                        .frame(minWidth: 100, alignment: .leading)
                    Spacer()
                    Slider(value: radius)
                }.padding(.top)
                
                HStack {
                    Text("Intensity")
                        //.multilineTextAlignment(.leading)
                        .frame(minWidth: 100, alignment: .leading)
                    Spacer()
                    Slider(value: intensity)
                }
                .padding(.bottom)
                
                HStack {
                    Button(filterName()) {
                        // change filter
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        // save the picture
                        guard let processedImage = self.processedImage else {
                            noImageAlert.toggle()
                            return
                        }
                        
                        let imageSaver = ImageSaver()
                        
                        imageSaver.successHandler = {
                            print("Success!")
                        }
                        
                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                            
                        }
                        
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            
            // 1 - alert option
//            .alert(isPresented: $noImageAlert) {
//                Alert(title: Text("Error"), message: Text("Please select an image before saving"), dismissButton: .default(Text("OK")))
//            }
            
//            // 2 - alert option
            .alert("Please select an image", isPresented: $noImageAlert) {
                Button("OK") {}
            } message: {
                Text("Please select an image before saving")
            }
            
            
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                // action sheet here
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { setFilter(CIFilter.crystallize()) },
                    .default(Text("Edges")) { setFilter(CIFilter.edges()) },
                    .default(Text("Gaussian Blur")) { setFilter(CIFilter.gaussianBlur()) },
                    .default(Text("Pixellate")) { setFilter(CIFilter.pixellate()) },
                    .default(Text("Sepia Tone")) { setFilter(CIFilter.sepiaTone()) },
                    .default(Text("Unsharp Mask")) { setFilter(CIFilter.unsharpMask()) },
                    .default(Text("Vignette")) { setFilter(CIFilter.vignette()) },
                    .cancel()
                ])
            }
            
            
        }
        
        
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
    
    func applyProcessing() {
        //currentFilter.intensity = Float(filterIntensity)
        //currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 100, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func filterName() -> String {
        let tempName = currentFilter.name
        var tempNameNoPrefix = tempName.deletingPrefix(ciPrefix)
        
        let capitalIndeces = findCapitalIndeces(str: tempNameNoPrefix)
        
        if capitalIndeces.isEmpty {
            // do nothing
        } else {
            for i in 0 ..< capitalIndeces.count {
                let indexOfCap = capitalIndeces[i]

                tempNameNoPrefix.insert(" ", at: tempNameNoPrefix.index(tempNameNoPrefix.startIndex, offsetBy: indexOfCap))
            }
        }
        return tempNameNoPrefix
    }
    
    
    func findCapitalIndeces(str: String) -> [Int] {
        var indexOfCapital = [Int]()
        var indexCount = 0
        
        for character in str {
            
            if indexCount == 0 {
                indexCount += 1
                continue
            } else if character.isUppercase {
                indexOfCapital.append(indexCount)
            }
            indexCount += 1
        }
        
        indexOfCapital.reverse()
        return indexOfCapital
    }
}


extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



//struct ContentView: View {
//
//    @State private var image: Image?
//    @State private var showingImagePicker = false
//    @State private var inputImage: UIImage?
//
//    var body: some View {
//        VStack {
//            image?
//                .resizable()
//                .scaledToFit()
//
//            Button("Select Image") {
//               showingImagePicker = true
//            }
//        }
//        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage)  {
//            ImagePicker(image: $inputImage)
//        }
//    }
//
//    func loadImage() {
//        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
//        UIImageWriteToSavedPhotosAlbum(inputImage, nil, nil, nil)
//    }
//
//
//    class ImageSaver: NSObject {
//        func writeToPhotoAlbum(image: UIImage) {
//            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
//        }
//
//        @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//            print("Save finished!")
//        }
//    }
//}





// demo of core image filters

//struct ContentView: View {
//    @State private var image: Image?
//
//    var body: some View {
//        VStack {
//            image?
//                .resizable()
//                .scaledToFit()
//        }
//        .onAppear(perform: loadImage)
//    }
//
//    func loadImage() {
//        guard let inputImage = UIImage(named: "Example") else { return }
//        let beginImage = CIImage(image: inputImage)
//
//        let context = CIContext()
//        //        let currentFilter = CIFilter.sepiaTone()
//        //
//        //        currentFilter.inputImage = beginImage
//        //        currentFilter.intensity = 1
//
//        //        let currentFilter = CIFilter.pixellate()
//        //        currentFilter.inputImage = beginImage
//        //        currentFilter.scale = 100
//
//        //        let currentFilter = CIFilter.crystallize()
//        //        currentFilter.inputImage = beginImage
//        //        currentFilter.radius = 200
//
//        guard let currentFilter = CIFilter(name: "CITwirlDistortion") else { return }
//        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
//        currentFilter.setValue(2000, forKey: kCIInputRadiusKey)
//        currentFilter.setValue(CIVector(x: inputImage.size.width / 2, y: inputImage.size.height / 2), forKey: kCIInputCenterKey)
//
//
//        // get a CIImage from our filter or exit if that fails
//        guard let outputImage = currentFilter.outputImage else { return }
//
//        // attempt to get a CGImage from our CIImage
//        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
//            // convert that to a UIImage
//            let uiImage = UIImage(cgImage: cgimg)
//
//            // and convert that to a SwiftUI image
//            image = Image(uiImage: uiImage)
//        }
//    }
//
//}




//struct ContentView: View {
//    @State private var showingActionSheet = false
//    @State private var backgroundColor = Color.white
//
//    var body: some View {
//        Text("Hello, World!")
//            .frame(width: 300, height: 300)
//            .background(backgroundColor)
//            .onTapGesture {
//                self.showingActionSheet = true
//            }
//            .actionSheet(isPresented: $showingActionSheet) {
//                ActionSheet(title: Text("Change background"), message: Text("Select a new color"), buttons: [
//                    .default(Text("Red")) { self.backgroundColor = .red },
//                    .default(Text("Green")) { self.backgroundColor = .green },
//                    .default(Text("Blue")) { self.backgroundColor = .blue },
//                    .cancel()
//                ])
//            }
//    }
//}



//struct ContentView: View {
//    @State private var blurAmount: CGFloat = 0
//
//    var body: some View {
//        let blur = Binding<CGFloat>(
//            get: {
//                self.blurAmount
//            },
//            set: {
//                self.blurAmount = $0
//                print("New value is \(self.blurAmount)")
//            }
//        )
//
//        return VStack {
//            Text("Hello, World!")
//                .blur(radius: blurAmount)
//
//            Slider(value: blur, in: 0...20)
//        }
//    }
//}

