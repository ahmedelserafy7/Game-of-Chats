//
//  UserCell.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/15/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class UserCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            setupUserWithProfileImage()
            
            if message?.videoUrl != nil {
                self.detailTextLabel?.text = "Sent a Video..."
            } else if message?.imageUrl != nil {
                self.detailTextLabel?.text = "Sent an image..."
            } else {
                // appear / show the messages into detail
                self.detailTextLabel?.text = message?.textMessage
            }
            
            if let messagesTimeInSeconds = message?.messageTime?.doubleValue {
                
                let timeMessageDate = Date(timeIntervalSince1970: messagesTimeInSeconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                //dateFormatter.dateFormat = "hh:mm:ss a"
                
                timeLabel.text = dateFormatter.string(from: timeMessageDate)
            }
            
        }
    }
    func setupUserWithProfileImage() {
        if let id = message?.chatPartnerId() {
            Database.database().reference().child("users").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.textLabel?.text = dictionary["name"] as? String
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                        self.profileImageView.loadProfileImagesInCacheWithURL(profileImageUrl)
                    }
                    
                }
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 66, y: textLabel!.frame.origin.y - 6, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 66, y: detailTextLabel!.frame.origin.y - 6, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.layer.cornerRadius = 25
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        // needs x, y, width, and height constraint anchors
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // needs x, y, width, and height constraint anchors
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor,constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
