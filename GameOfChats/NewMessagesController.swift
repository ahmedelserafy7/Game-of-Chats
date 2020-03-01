//
//  MyFriendMessagesController.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/2/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class NewMessagesController: UITableViewController {
    
    fileprivate let cellId = "cellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        fetchUsers()
    }
    
    var users = [User]()
    
    func fetchUsers() {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapShot) in
            guard let dictionary = snapShot.value as? [String: AnyObject] else { return }
            let user = User()
            user.name = dictionary["name"] as? String
            user.email = dictionary["email"] as? String
            user.profileImageUrl = dictionary["profileImageUrl"] as? String
            // give id to each user
            user.id = snapShot.key
            
//            user.setValuesForKeys(dictionary)
            self.users.append(user)
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
        }, withCancel: nil)
        
    }
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.item]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        cell.detailTextLabel?.textColor = .gray
        cell.imageView?.contentMode = .scaleAspectFill
        
        if let profileImageUrl = user.profileImageUrl {
            cell.profileImageView.loadProfileImagesInCacheWithURL(profileImageUrl)
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    var messagesController: MessagesController?
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismiss(animated: true) {
            let user = self.users[indexPath.item]
            self.messagesController?.showChatLogForUser(user)
            
        }
    }
    
}







