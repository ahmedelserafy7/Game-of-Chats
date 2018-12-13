//
//  ViewController.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 12/26/17.
//  Copyright © 2017 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    let cellId = "cellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogoutButton))
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleMessages))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        checkIfUserLoggedIn()
//        observeMessages()
//        observeUserMessages()
    }
    
    var messages = [Message]()
    var messageDictionary = [String: Message]()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let userMessagesRef = Database.database().reference().child("user_messages")
        let idChildRef = userMessagesRef.child(uid)
        idChildRef.observe(.childAdded, with: { (snapshot) in
//            print(snapshot)
            let messageId = snapshot.key
            let messagesChildRef = Database.database().reference().child("messages").child(messageId)
            // looke up and search for particular child
            messagesChildRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
//                print(snapshot)
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message()
                    message.setValuesForKeys(dictionary)
                    
                    if let toId = message.toId {
                        // you have message that has value and key of all messages data from dictionary right above that give data to message, and now self.messageDictionary[message.toId!] means you want value and the value will be all message, but you need unique id for message that could appear one cell for two and more message in tableView
                        // to save all messages into dictionary, and by id u can appear one user that has alot of messages in one cell instead of two cells or more for two messages of more
                        // self.messageDictionary[toId] represent message that has only one id to all messages that can appear
                        self.messageDictionary[toId] = message
                        
                        // then give values to messages that look like library that has all books to show
                        self.messages = Array(self.messageDictionary.values)
                        //self.messages.append(message)
                        
                        // delete 'ed' from sorted
                        self.messages.sort(by: { (message1, message2) -> Bool in
                            return message1.messageTime!.intValue > message2.messageTime!.intValue
                        })
                    }
                    
                    //prevent main from getting out to the background thread at every time to fetch data, i need to fetch data just one time and not to crash the app by using DispatchQueue
                    DispatchQueue.main.async(execute: {
                        // to reloade data from firebase
                        self.tableView.reloadData()
                    })
                    //                print(message.textMessage!)
                }


            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    func observeMessages() {
        // to fetch data from firebase to app
        Database.database().reference().child("messages").observe(.childAdded, with: { (snapshot) in
//            print(snapshot!.value)
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                message.setValuesForKeys(dictionary)
                
                if let toId = message.toId {
                    // you have message that has value and key of all messages data from dictionary right above that give data to message, and now self.messageDictionary[message.toId!] means you want value and the value will be all message, but you need unique id for message that could appear one cell for two and more message in tableView
                    // to save all messages into dictionary, and by id u can appear one user that has alot of messages in one cell instead of two cells or more for two messages of more
                    // self.messageDictionary[toId] represent message that has only one id to all messages that can appear
                    self.messageDictionary[toId] = message
                    
                    // then give values to messages that look like library that has all books to show
                    self.messages = Array(self.messageDictionary.values)
                    //self.messages.append(message)
                    
                    // delete 'ed' from sorted
                    self.messages.sort(by: { (message1, message2) -> Bool in
                        return message1.messageTime!.intValue > message2.messageTime!.intValue
                    })
                }
               
                //prevent main from getting out to the background thread at every time to fetch data, i need to fetch data just one time and not to crash the app by using DispatchQueue
                DispatchQueue.main.async(execute: {
                    // to reloade data from firebase
                    self.tableView.reloadData()
                })
//                print(message.textMessage!)
            }
        }, withCancel: nil)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.item]
        cell.message = message
        //cell.textLabel?.text = message.toId
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.item]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let userRef = Database.database().reference().child("users").child(chatPartnerId)
        userRef.observeSingleEvent(of: .value
            , with: { (snapshot) in
                
//                print(snapshot.value)
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                let user = User()
                user.id = chatPartnerId
                user.setValuesForKeys(dictionary)
                self.showChatLogForUser(user: user)
        }, withCancel: nil)
        
//        let message = messages[indexPath.item]
        
//        print("text message: \(message.textMessage!)", "fromId: \(message.fromId)", "toId: \(message.toId)")

    }
    func handleMessages() {
        let friendMsgsController = MyFriendsMessagesController()
        friendMsgsController.myOwnMessgesController = self
        let navController = UINavigationController(rootViewController: friendMsgsController)
        present(navController, animated: true, completion: nil)
//        show(navController, sender: nil)
//        self.navigationController?.pushViewController(navController, animated: true)
    }
    
    func checkIfUserLoggedIn() {
        
        // currentUser: Synchronously gets the cached current user, or null if there is none.
        // uid is nil either currentUser is not existed, or currentUser log out of the application
        if Auth.auth().currentUser?.uid == nil {
            //            handleLogoutButton()
            
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
            let dictionary = snapshot.value as? [String: AnyObject]
            let user = User()
            user.setValuesForKeys(dictionary!)
            self.setupNavBarTitleWithProfileImageView(user: user)
//            self.navigationItem.title = dictionary?["name"] as? String
            //print(snapshot)
        }, withCancel: nil)
    }
    func setupNavBarTitleWithProfileImageView(user: User) {
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
//        navigationItem.title = user.name
        let titleView = UIView()
//        titleView.backgroundColor = .yellow
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
            profileImageView.loadProfileImagesInCacheWithURL(urlString: profileImageUrl)
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
        // width nachor
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        // y anchor
        nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        // to express the thing that will be and come out in the middle of title instead of original title
        navigationItem.titleView = titleView
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChatLog)))
        
    }
   
    func showChatLogForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    func handleLogoutButton() {
        do {
            try Auth.auth().signOut()

        } catch let logErr {
            print(logErr)
        }
        
        let loginController = LoginViewController()
        loginController.myOwnMessages = self
        present(loginController, animated: true, completion: nil)
    }
    
}

