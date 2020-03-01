//
//  ViewController.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 12/26/17.
//  Copyright © 2017 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class MessagesController: UITableViewController {
    
    let cellId = "cellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogoutButton))
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleMessages))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
        checkIfUserLoggedIn()
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = messages[indexPath.item]
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("user_messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                }
                // remove roots of dictionary
                self.messageDictionary.removeValue(forKey: chatPartnerId)
                // to update cells
                self.reloadDataIntoCells()
            })
            
        }
    }
    
    var messages = [Message]()
    var messageDictionary = [String: Message]()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let userMessagesRef = Database.database().reference().child("user_messages").child(uid)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            
            userMessagesRef.child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                
                self.fetchMessageWithMessagesId(messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        // to remove node feom firebase directly
        // to remove the entire node(toId or userId) that underneath the current user
        userMessagesRef.observe(.childRemoved, with: { (snapshot) in
        
            self.messageDictionary.removeValue(forKey: snapshot.key)
            self.reloadDataIntoCells()
        }, withCancel: nil)
    }
    
    
    func fetchMessageWithMessagesId(_ messageId: String) {
        let messagesChildRef = Database.database().reference().child("messages").child(messageId)
        // looke up and search for particular child
        messagesChildRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.toId = dictionary["toId"] as? String
                message.textMessage = dictionary["textMessage"] as? String
                message.messageTime = dictionary["messageTime"] as? NSNumber
                
                message.imageUrl = dictionary["imageUrl"] as? String
                message.imageHeight = dictionary["imageHeight"] as? NSNumber
                message.imageWidth = dictionary["imageWidth"] as? NSNumber
                
                message.videoUrl = dictionary["videoUrl"] as? String
                
                if let chatPartnerId = message.chatPartnerId() {
                    // you have message that has value and key of all messages data from dictionary right above that give data to message, and now self.messageDictionary[message.toId!] means you want value and the value will be all message, but you need unique id for message that could appear one cell for two and more messages in tableView
                    // to save all messages into dictionary, and by id u can appear one user that has alot of messages in one cell instead of two cells or more for two messages of more
                    // self.messageDictionary[toId] represent message that has only one id to all messages that can appear
                    // to group all related messages with who talk to you
                    // that is the way of appearing / showing messages
                    self.messageDictionary[chatPartnerId] = message
                    
                }
                
                self.reloadDataIntoCells()
            }
            
        }, withCancel: nil)
    }
    var timer: Timer?
    func reloadDataIntoCells() {
        
        self.timer?.invalidate()
        
        // create a 'scheduled timer' to reload data at the entire tableView in 0.1 sec
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadData), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadData() {
        
        // to construct array of data cells once, instead of reconstructing array everytime i find new message of new cell
        // the time that i reload data into cell, i will construct array of data
        // the moment that be reloaded tableView, it 's the moment that i show or construct array of data
        
        // then give values to messages that look like library that has all books to show
        self.messages = Array(self.messageDictionary.values)
        //self.messages.append(message)
        
        // delete 'ed' from sorted
        self.messages.sort(by: { (message1, message2) -> Bool in
            
            guard let firMessage = message1.messageTime?.intValue else { return  false }
            guard let secMessage = message2.messageTime?.intValue else { return  false }
            return firMessage > secMessage
        })
        
        //prevent main from getting out to the background thread at every time to fetch data, i need to fetch data just one time and not to crash the app by using DispatchQueue
        DispatchQueue.main.async(execute: {

            // to reloade data from firebase
            self.tableView.reloadData()
            
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.item]
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.item]
        // going to the right id from "didSelect"
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let userRef = Database.database().reference().child("users").child(chatPartnerId)
        userRef.observeSingleEvent(of: .value
            , with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                let user = User()
                user.id = chatPartnerId
//                user.id = dictionary["id"] as? String
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                // right now user has every data(name, email, profile, and id) in one object
//                user.setValuesForKeys(dictionary)
                self.showChatLogForUser(user)
        }, withCancel: nil)
    
    }
    
    @objc func handleMessages() {
            let newMessagesController = NewMessagesController()
            newMessagesController.messagesController = self
            let navController = UINavigationController(rootViewController: newMessagesController)
            self.present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserLoggedIn() {
        
        // currentUser: Synchronously gets the cached current us/Users/elser_10/Desktop/GameOfChats/GameOfChats/ChatInputContainerView.swifter, or null if there is none.
        // uid is nil either currentUser is not existed, or currentUser log out of the application
        if Auth.auth().currentUser?.uid == nil {
            
            // adopt an idead that contains two viewControllers and if the operation is successed, then one of the operation will appear, and the other will be the background thread
            // delay is zero that means no delay of appearing thread message/one of two viewControllers
            perform(#selector(handleLogoutButton), with: self, afterDelay: 0)
            
            // to get rid of console warning: "Unbalanced calls to begin/end appearance transitions for <UINavigationController: 0x7f8ce2817400>". that is showing two viewControllers at the same time.
        } else {
            fetchUserWithNavbarTitle()
            
        }
    }
    
    func fetchUserWithNavbarTitle() {
        // why guard to avoid uid crashed nil
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            let user = User()
            user.id = dictionary["id"] as? String
            user.name = dictionary["name"] as? String
            user.email = dictionary["email"] as? String
            user.profileImageUrl = dictionary["profileImageUrl"] as? String
//            user.setValuesForKeys(dictionary)
            self.setupNavBarTitleWithProfileImageView(user)
        }, withCancel: nil)
    }
    
    func setupNavBarTitleWithProfileImageView(_ user: User) {
        
        
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
 
        observeUserMessages()
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = CustomImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        titleView.addSubview(profileImageView)
        // give user.profileImageUrl to loadProfileImagesWithURL to fetch profile data from firebase
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadProfileImagesInCacheWithURL(profileImageUrl)
        }
        
        // need x, y, width, height constraints
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(nameLabel)
        
        // need x, y, width, height constraints
        // x anchor
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        // width anchor
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        // y anchor
        nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        // to express the thing that will be and come out in the middle of title instead of original title
        navigationItem.titleView = titleView
    }
    
    func showChatLogForUser(_ user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    @objc func handleLogoutButton() {
        do {
            try Auth.auth().signOut()
            
        } catch let logErr {
            print(logErr)
        }
        
        let loginController = LoginViewController()
        loginController.myMessagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
}


