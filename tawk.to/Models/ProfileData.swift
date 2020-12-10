//
//  ProfileData.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import Foundation

struct ProfileData: Decodable {
    
    let blog: String?
    let followers: Int?
    let following: Int?
    let id: Int
    let avatar_url: String?
    let company: String?
    let login: String?
    let name: String?
    
}
