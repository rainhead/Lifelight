//
//  INaturalistControlledTerm.swift
//  Natgeist
//
//  Created by Peter Abrahamsen on 10/9/24.
//

import Foundation

struct INaturalistControlledTerm: Identifiable, Equatable, Decodable {
    let id: UInt64
    let excepted_taxon_ids: [INaturalistTaxon.ID]
    let is_value: Bool
    let label: String
    let multivalued: Bool
    let taxon_ids: [INaturalistTaxon.ID]
    let values: [INaturalistControlledValue]
}
