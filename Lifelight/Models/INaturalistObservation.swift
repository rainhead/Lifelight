//
//  Obs.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

// The JSON representation of an observation, as returned by the API.
struct INaturalistObservation: Decodable, Equatable, Identifiable, Hashable {
    static let fieldSpecification = "(id:!t,description:!t,uuid:!t,uri:!t,time_observed_at:!t,created_at:!t,updated_at:!t,"
    + "created_time_zone:!t,observed_on:!t,observed_time_zone:!t,"
    + "annotations:\(INaturalistAnnotation.fieldSpecification),"
    + "quality_grade:!t,faves_count:!t,"
    + "identifications:\(INaturalistIdentification.fieldSpecification),"
    + "taxon:\(INaturalistTaxon.fieldSpecification),user:\(INaturalistUser.fieldSpecification),"
    + "observation_photos:\(INaturalistObservationPhoto.fieldDescription),location:!t)"

    let id: Int64

    let annotations: [INaturalistAnnotation]
    let created_time_zone: String
    let description: String?
    let geoprivacy: Geoprivacy?
    let identifications: [INaturalistIdentification]
    let observation_photos: [INaturalistObservationPhoto]
    let taxon: INaturalistTaxon?
    let uri: URL
    let uuid: UUID
    
    let created_at: String
    let updated_at: String
    let observed_on: String?
    let time_observed_at: String?

    static func == (lhs: INaturalistObservation, rhs: INaturalistObservation) -> Bool {
        lhs.id == rhs.id && lhs.updated_at == rhs.updated_at
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(updated_at)
    }
    
    enum Geoprivacy: String, Decodable, Equatable {
        case open
        case `private`
        case obscured
    }
    
    var llObservation: LLObservation {
        LLObservation(
            id: id,
            createdAt: created_at.asDate()!,
            description: description,
            observedAt: time_observed_at?.asDate(),
            observedOn: observed_on?.asDay(),
            updatedAt: updated_at.asDate()!,
            taxonID: taxon?.id
        )
    }
    
    var llObservationPhotos: [LLObservationPhoto] {
        observation_photos.map { obs_photo in
            LLObservationPhoto(
                id: obs_photo.id,
                observationID: id,
                position: obs_photo.position,
                originalHeight: obs_photo.photo.original_dimensions.height,
                originalWidth: obs_photo.photo.original_dimensions.width,
                squareURL: obs_photo.photo.squareURL
            )
        }
    }
}

struct INaturalistAnnotation: Decodable, Equatable, Identifiable, Hashable {
    static let fieldSpecification = "(id:!t,uuid:!t,controlled_attribute_id:!t,controlled_value_id:!t,user_id:!t,vote_score:!t)"
    
    let uuid: UUID
    var id: UUID { uuid }
    let controlled_attribute_id: INaturalistControlledTerm.ID
    let controlled_value_id: INaturalistControlledValue.ID
    let user_id: INaturalistUser.ID
    let vote_score: Int
}

struct INaturalistIdentification: Decodable, Equatable, Identifiable, Hashable {
    static let fieldSpecification = "(id:!t,uuid:!t,body:!t,category:!t,created_at:!t,current:!t,disagreement:!t,"
    + "user:\(INaturalistUser.fieldSpecification),taxon:\(INaturalistTaxon.fieldSpecification))"

    let id: Int64
    
    let body: String?
    let category: Category?
    @DateFormatted<ISO8601DateStrategy> var created_at: Date
    let current: Bool
    let disagreement: Bool?
    let taxon: INaturalistTaxon
    let uuid: UUID
    let user: INaturalistUser
    
    static func == (lhs: INaturalistIdentification, rhs: INaturalistIdentification) -> Bool {
        lhs.id == rhs.id && lhs.body == rhs.body
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(body)
        hasher.combine(category)
    }

    // https://github.com/inaturalist/inaturalist/blob/main/app/models/identification.rb#L80-L85
    enum Category: String, Decodable, Equatable {
        case improving
        case supporting
        case leading
        case maverick
    }
}

struct INaturalistObservationPhoto: Equatable, Identifiable, Hashable, Decodable {
    static let fieldDescription = "(id:!t,photo:\(INaturalistPhoto.fieldDescription),position:!t)"
    
    let id: Int64
    let photo: INaturalistPhoto
    let position: Int
}

struct INaturalistPhoto: Identifiable, Hashable, Decodable {
    static let fieldDescription = "(id:!t,attribution:!t,hidden:!t,license_code:!t,url:!t,original_dimensions:(height:!t,width:!t))"
    
    let id: Int64
    let attribution: String
//    let hidden: Bool
    let license_code: String?
    private var url: URL
    var original_dimensions: Dimensions
    
    var largeURL: URL { URL(string: "large.\(url.pathExtension)", relativeTo: url)! } // max dimension 1024px
    var mediumURL: URL { URL(string: "medium.\(url.pathExtension)", relativeTo: url)! } // max dimension 500px
    var originalURL: URL { URL(string: "original.\(url.pathExtension)", relativeTo: url)! } // max dimension 2048px
    var smallURL: URL { URL(string: "small.\(url.pathExtension)", relativeTo: url)! } // max dimension 240px
    var squareURL: URL { url } // 75px square
    var thumbURL: URL { URL(string: "thumb.\(url.pathExtension)", relativeTo: url)! } // max dimension 100px
    
    static func == (lhs: INaturalistPhoto, rhs: INaturalistPhoto) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    struct Dimensions: Decodable, Hashable {
        var height: UInt
        var width: UInt
    }
}

private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let isoFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
}()

extension String {
    func asDay() -> Date? {
        dayFormatter.date(from: self)
    }
    
    func asDate() -> Date? {
        isoFormatter.date(from: self)
    }
}
