//
//  Message.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/13/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class Message: NSObject {
    
    var fromId: String?
    var messageTime: NSNumber?
    var textMessage: String?
    var toId: String?
    
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    var videoUrl: String?
    
    // to solve thew problem that you should add new property, after add new child node
    init(dictionary: [String: Any]) {
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        textMessage = dictionary["textMessage"] as? String
        messageTime = dictionary["messageTime"] as? NSNumber
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
        
        /*
         if fromId == Auth.auth().currentUser?.uid {
         return toId
         }
         else {
         return fromId
         }*/
    }
}
