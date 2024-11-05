//
//  PhotoGrid.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import SwiftUI
import Nuke
import NukeUI

struct PhotoGrid: View {
    static let pipeline = ImagePipeline(configuration: .withDataCache(name: "small", sizeLimit: 300*1024*1024))
    let photos: [LLPhotoWithObservation].SubSequence
    let imageWidth: Double = 80
    let imageSpacing: Double = 5.0
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: imageWidth, maximum: imageWidth * 1.5), spacing: imageSpacing)], alignment: .leading, spacing: imageSpacing) {
            ForEach(photos) { photo in
                LazyImage(url: photo.photo.smallURL) { state in
                    if let image = state.image {
                        Link(destination: photo.observation.uri) {
                            image
                                .resizable()
                        }
                    } else if state.error != nil {
                        Color.red
                    } else {
                        Color.gray
                    }
                }
                .pipeline(PhotoGrid.pipeline)
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .aspectRatio(1, contentMode: .fit)
                .frame(minHeight: imageWidth)
            }
        }
    }
}
