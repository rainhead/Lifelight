//
//  PhotoGrid.swift
//  Lifelight
//
//  Created by Peter Abrahamsen on 10/17/24.
//

import CachedAsyncImage
import SwiftUI

struct PhotoGrid: View {
    let observations: [INaturalistObservation].SubSequence
    let imageWidth: Double = 80
    let imageSpacing: Double = 5.0
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: imageWidth, maximum: imageWidth*1.2))], alignment: .leading, spacing: imageSpacing) {
            ForEach(observations.flatMap { obs in obs.observation_photos.map { photo in (obs, photo) } }, id: \.1.id) { pair in
                let (observation, photo) = pair
                CachedAsyncImage(url: photo.photo.smallURL) { phase in
                    switch phase {
                    case .failure(_): Color.gray
                    case .success(let image): Link(destination: observation.uri) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped()
                            .aspectRatio(1, contentMode: .fit)
                    }
                    default: ProgressView()
                    }
                }.frame(height: imageWidth)
            }
        }
    }
}
