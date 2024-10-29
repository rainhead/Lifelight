//
//  PhotoGrid.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import CachedAsyncImage
import SwiftUI
import NukeUI

struct PhotoGrid: View {
    let photos: [LLPhotoWithObservation].SubSequence
    let imageWidth: Double = 82
    let imageSpacing: Double = 5.0
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: imageWidth, maximum: imageWidth))], alignment: .leading, spacing: imageSpacing) {
            ForEach(photos) { photo in
                LazyImage(url: photo.photo.smallURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped()
                            .aspectRatio(1, contentMode: .fit)
                    } else if state.error != nil {
                        Color.red
                    } else {
                        Color.gray
                    }
                }.frame(height: imageWidth)
            }
        }
    }
}
