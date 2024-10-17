//
//  INaturalistTaxon.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

struct INaturalistTaxon: Decodable, Equatable, Identifiable, Hashable {
    static let fieldSpecification = "(id:!t,is_active:!t,name:!t,rank:!t,parent_id:!t,preferred_common_name:!t,rank:!t,uuid:!t,wikipedia_url:!t)"

    let id: UInt64
    let is_active: Bool
    let name: String
    let parent_id: ID?
    let preferred_common_name: String?
    let rank: Rank
//    let uuid: UUID
    let wikipedia_url: URL?
    
    static func == (lhs: INaturalistTaxon, rhs: INaturalistTaxon) -> Bool {
        lhs.id == rhs.id
    }
    
    // NB: ranks on iNaturalist have a rank level, a non-unique double between 0 and 100, forming a semi-lattice. For now, we order ranks of equal level arbitrarily as given by the order of the below cases.
    // For now we use rank only when describing a taxon. The only hierarchy we use is the ancestry relationship derived from the parent_id field.
    // https://github.com/inaturalist/inaturalist/blob/main/app/models/taxon.rb#L168-L204
    enum Rank: String, Decodable, Equatable {
        case stateofmatter // level 100
        case kingdom
        case phylum
        case subphylum
        case superclass
        case `class`
        case subclass
        case infraclass
        case subterclass
        case superorder
        case order
        case suborder
        case infraorder
        case parvorder
        case zoosection
        case zoosubsection
        case superfamily
        case epifamily
        case family
        case subfamily
        case supertribe
        case tribe
        case subtribe
        case genus
        case genushybrid
        case subgenus
        case section
        case subsection
        case complex
        case species
        case hybrid
        case subspecies
        case variety
        case form
        case infrahybrid // level 5
    }
}
