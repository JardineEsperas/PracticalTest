//
//  UserData.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import Foundation

struct UserData: Decodable {
    let login: String?
    let id: Int
    let avatar_url: String?
    let url: String?
}
