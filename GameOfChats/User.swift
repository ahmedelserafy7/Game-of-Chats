//
//  User.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/2/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit

class User: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String
        name = dictionary["name"] as? String
        email = dictionary["email"] as? String
        profileImageUrl = dictionary["profileImageUrl"] as? String
    }
}
