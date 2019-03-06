//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/11/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // to be specific, when clicking/ pressing on any cell, "showChatlogControlelr" will work and make chatlog.user = user and user will be the actual user that you pressing on, so it has info about user that you pressed, and give it to user
    var user: User? {
        didSet {
            //            navigationItem.title = user?.name
            
            // so you can add some text messages that you wrote in collectionView here in the same place you have info about user, coz this property will work after pressing on cell, so i have insurance about going to chatlogController directly after pressing on cell
            observeMessages()
        }
    }
    var messages = [Message]()
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let userId = user?.id else {
            return
        }
        let userMessagesRef = Database.database().reference().child("user_messages").child(uid).child(userId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageKey = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageKey)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {
                    return
                }
                //                let message = Message(dictionary: dictionary)
                
                //                message.setValuesForKeys(dictionary)
                // "user.id" means the user that i select from tableView and grab user data to "user property right above and give user id to user.id by func showChatLogController" and "toId" for handleSend, and "message.chatPartnerId()" means the user data that be shown / appear on the tableView
                // as soon as two parameters equal to each other, so you could append data into messages array and reloade data
                //                if self.user?.id == message.chatPartnerId() {
                self.messages.append(Message(dictionary: dictionary))
                
                //                    DispatchQueue.main.async(execute: {
                self.collectionView?.reloadData()
                //                        if self.messages.count > 0 {
                // after reloading data, just show the last index at messages array
                let indexPath = NSIndexPath(item: self.messages.count - 1 , section: 0)
                self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                //                        }
                
                //                    })
                //                }
                
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    let cellId = "cellID"
    override func viewDidLoad() {
        super.viewDidLoad()
        //observeMessages()
        
        // to change back button title
        let backItem = UIBarButtonItem()
        backItem.title = user?.name
        navigationController?.navigationBar.topItem?.backBarButtonItem = backItem
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //        collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50, 0)
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(MessagesViewCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        //setupInputsContainerView()
        setupKeyboardWithContainerView()
    }
    
    lazy var messageContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
        
        /*let messageContainerView = UIView()
         messageContainerView.backgroundColor = .white
         messageContainerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
         
         */
        
        
        //        return messageContainerView
    }()
    func handlePickerTap() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(pickerController, animated: true, completion: nil)
        //        print("upload imageView clicked")
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoFileUrl = info[UIImagePickerControllerMediaURL] as? URL{
            handleSelectedVideoWithUrl(videoFileUrl)
            // print(videoFileUrl)
            
        } else {
            handleSelectedImageWithInfo(info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func handleSelectedVideoWithUrl(_ url: URL) {
        
        self.navigationItem.title = "Loading.."
        
        let folderName = "Message'sMovies"
        let fileName = UUID().uuidString + ".mov"
        
        let uploadTask = Storage.storage().reference().child(folderName).child(fileName)
        
        uploadTask.putFile(from: url, metadata: nil) { (metaData, err) in
            if err != nil {
                print(err ?? "")
            }
            
            uploadTask.downloadURL(completion: { (downloadUrl, err) in
                
                if err != nil {
                    print("Failed to store user movie", err ?? "")
                    return
                }
                
                // big mistake absoluteString not absoluteURL
                guard let videoUrl = downloadUrl?.absoluteString else { return }
//                print(videoUrl)
                //DispatchQueue.main.async(execute: {
                if let thumbnailImage = self.handleThumbnailImageWithFileUrl(url) {
                    self.loadMessagesImagesIntoStorage(thumbnailImage, completion: { (imageUrl) in
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
                        
                        self.handleMessageWithProperties(properties)
                        
                    })
                    
                }
                //"imageUrl": imageUrl as AnyObject,
                //})
            })
            
            let progressView = UIProgressView()
            progressView.frame = CGRect(x: 0, y: (self.navigationController?.navigationBar.frame.height)! - 2, width: 600, height: 2)
            progressView.setProgress(0, animated: false)
            let localUrl = uploadTask.write(toFile: url)
            localUrl.observe(.progress) { (snapshot) in
                
                let complete = Float(snapshot.progress!.completedUnitCount)
                let total = Float(snapshot.progress!.totalUnitCount)
                let progress =  (complete / total)
                
                let percentComplete = progress * 100.0
                
                self.navigationController?.navigationBar.addSubview(progressView)
                
                if percentComplete <= 0 {
                    self.navigationItem.title = "0" + "%"
                    progressView.setProgress(0, animated: false)
                }
                
                self.navigationItem.title = String(percentComplete) + "%"
                progressView.progress = progress
                
                progressView.setProgress(progress, animated: true)
            }
            
            localUrl.observe(.failure) { (snapshot) in
                if let err = snapshot.error as? NSError {
                    print(err)
                }
            }
            
            localUrl.observe(.success, handler: { (snapshot) in
                
                UIView.animate(withDuration: 7, delay: 3, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.navigationItem.title = "Done"
                }, completion: { (_) in
                    //                    self.navigationItem.title = ""
                    progressView.setProgress(0, animated: false)
                    localUrl.removeAllObservers(for: .progress)
                    progressView.removeFromSuperview()
                    self.navigationItem.title = ""
                })
            })
            
        }
    }
    
    func handleThumbnailImageWithFileUrl(_ fileUrl: URL)-> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let err {
            print(err)
        }
        return nil
    }
    func handleSelectedImageWithInfo(_ info: [String: Any]) {
        
        var selectedImageViewFromPicker: UIImage?
        
        if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageViewFromPicker = originalImage
        } else if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageViewFromPicker = editedImage
        }
        
        if let selectedImage = selectedImageViewFromPicker {
            loadMessagesImagesIntoStorage(selectedImage, completion: { (imageUrl) in
                self.handleMessagesImagesWithFirebase(imageUrl, selectedImage)
            })
            //            loadMessagesImagesIntoStorage(image: selectedImage)
        }
        //        print(info)
    }
    func loadMessagesImagesIntoStorage(_ image: UIImage, completion:@escaping (_ imageUrl: String)->()) {
        let imageId = UUID().uuidString
        let ref = Storage.storage().reference().child("friend'sMessagesImages").child("\(imageId)")
        
        let uploadCompressionImages = UIImageJPEGRepresentation(image, 0.1)
        ref.putData(uploadCompressionImages!, metadata: nil) { (metadata, error) in
            if error != nil {
                print("failed to upload image into your friend messages, coz: ", error!)
                return
            }
            
            ref.downloadURL(completion: { (url, err) in
                if err != nil {
                    print("failed to store users messages", err?.localizedDescription ?? "")
                    return
                }
                //                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                if let imageUrl = url?.absoluteString {
                    completion(imageUrl)
                    //                self.handleMessagesImagesWithFirebase(imageUrl, image)
                }
            })
            
            
        }
        
    }
    
    
    // as you see, frame starts from the bottom
    override var inputAccessoryView: UIView? {
        get {
            
            return messageContainerView
        }
    }
    // must call this func to make inputAccessoryView available / work
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // to solve memory leak that will occur, when dismiss keyboard, this solution will remove notification for the first time and complete normally
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    // it works too
    /*
     override func viewWillDisappear(_ animated: Bool) {
     super.viewWillAppear(animated)
     NotificationCenter.default.removeObserver(self)
     }
     */
    
    func setupKeyboardWithContainerView() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboadDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        /*
         // send notification, if keyboard will show
         NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow , object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
         */
    }
    func handleKeyboadDidShow() {
        // if it doesn't exist any message or (if there is one message, coz it doesn't exist messages.count = 0), don't use this function
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    func handleKeyboardWillShow(notification: NSNotification) {
        
        //print(notification.userInfo!)
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            // isKeyboardShowing is condition, if isKeyboardShowing = notification.name, so it will be UIKeyboardWillShow
            let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
            self.bottomContainerViewAnchor?.constant = isKeyboardShowing ? -keyboardFrame!.height : 0
            //print(keyboardFrame?.height)
        }
        
        UIView.animate(withDuration: duration!, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { (completed) in
            
        }
        
    }
    /*func handleKeyboardWillHide(notification: NSNotification) {
     
     let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
     
     // 0 considers default value of bottomContainerView
     self.bottomContainerViewAnchor?.constant = 0
     
     UIView.animate(withDuration: duration!, delay: 0, options: .curveEaseOut, animations: {
     self.view.layoutIfNeeded()
     }, completion: nil)
     
     
     }*/
    
    var bottomContainerViewAnchor: NSLayoutConstraint?
    /*
     func setupInputsContainerView() {
     let messageContainerView = UIView()
     // to make messageContainerView obaque
     messageContainerView.backgroundColor = .white
     messageContainerView.translatesAutoresizingMaskIntoConstraints = false
     
     view.addSubview(messageContainerView)
     // by ios 9 constraints need x, y, w, h constraints
     messageContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
     bottomContainerViewAnchor =  messageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
     bottomContainerViewAnchor?.isActive = true
     messageContainerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
     messageContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
     
     let sendButton = UIButton(type: .system)
     sendButton.setTitle("Send", for: .normal)
     sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
     sendButton.translatesAutoresizingMaskIntoConstraints = false
     
     messageContainerView.addSubview(sendButton)
     // by ios 9 constraints, need x, y, w, h constraints
     sendButton.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor).isActive = true
     sendButton.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor).isActive = true
     sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
     sendButton.heightAnchor.constraint(equalTo: messageContainerView.heightAnchor).isActive = true
     
     
     messageContainerView.addSubview(inputTextField)
     
     inputTextField.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor, constant: 8).isActive = true
     inputTextField.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor).isActive = true
     inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
     inputTextField.heightAnchor.constraint(equalTo: messageContainerView.heightAnchor).isActive = true
     
     let seperatorLine = UIView()
     //        seperatorLine.backgroundColor = UIColor(r: 220, g: 220, b: 220)
     seperatorLine.backgroundColor = UIColor(white: 0.5, alpha: 1)
     seperatorLine.translatesAutoresizingMaskIntoConstraints = false
     
     messageContainerView.addSubview(seperatorLine)
     // x, y, w, h consraints
     seperatorLine.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor).isActive = true
     seperatorLine.topAnchor.constraint(equalTo: messageContainerView.topAnchor).isActive = true
     seperatorLine.widthAnchor.constraint(equalTo: messageContainerView.widthAnchor).isActive = true
     seperatorLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
     }
     */
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessagesViewCell
        //        cell.backgroundColor = .yellow
        if self.messages.count > 0 {
            let message = messages[indexPath.item]
            cell.message = message
            
            cell.textView.text = message.textMessage
            cell.chatLogController = self
            if let textMessage = message.textMessage {
                cell.bubbleViewWidthAnchor?.constant = estimatedSizeOfTextAndImageFrame(textMessage).width + 24
                
            } else if message.imageUrl != nil {
                cell.bubbleViewWidthAnchor?.constant = 200
            }
            /*  if message.videoUrl != nil {
             cell.playButton.isHidden = false
             }  else {
             cell.playButton.isHidden = true
             }
             */
            cell.playButton.isHidden = message.videoUrl == nil
            
            setupCell(message, cell: cell)
        }
        
        return cell
    }
    
    func setupCell(_ message: Message, cell: MessagesViewCell) {
        if let userProfileImageView = user?.profileImageUrl {
            cell.profileImageView.loadProfileImagesInCacheWithURL(userProfileImageView)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            // outgoing blue messages
            cell.bubbleView.backgroundColor = MessagesViewCell.bubbleViewBackground
            cell.textView.textColor = .white
            
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
            
            cell.profileImageView.isHidden = true
        } else {
            // incoming gray messages
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.bubbleViewRightAnchor?.isActive = false
            
            cell.profileImageView.isHidden = false
        }
        
        if let messageImage = message.imageUrl {
            cell.messageImageView.loadProfileImagesInCacheWithURL(messageImage)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
            cell.textView.isHidden = true
        } else {
            cell.messageImageView.isHidden = true
            cell.textView.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // you can give it arbitrary value to get rid of optional value
        var height: CGFloat?
        
        let message = messages[indexPath.item]
        
        if let textMessages = message.textMessage {
            height = estimatedSizeOfTextAndImageFrame(textMessages).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            // if h1 / w1 = h2 / w2
            // it means h1 = (h2 / w2) * w1
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        //        } else if let messageImage = messages[indexPath.item].imageUrl{
        //            height = estimatedSizeOfTextAndImage(text: nil, image: messageImage).height + 20
        //        }
        // bounds handle landscape and portrait
        // use bounds to fix problem of collectionView that be affected by inputAccessoryView that be laid out
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height!)
    }
    fileprivate func estimatedSizeOfTextAndImageFrame(_ addTextOrImage: String)-> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        
        return NSString(string: addTextOrImage).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }
    /*
     private func estimatedSizeOfTextAndImage(text: String?, image: String?)-> CGRect {
     
     let size = CGSize(width: 200, height: 1000)
     if let image = image {
     return NSString(string: image).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
     } else {
     return NSString(string: text!).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
     }
     }*/
    func handleSend() {
        
        let properties: [String: AnyObject] = ["textMessage": messageContainerView.inputTextField.text! as AnyObject]
        
        handleMessageWithProperties(properties)
        /*
         let ref = Database.database().reference().child("messages")
         let messageChildRef = ref.childByAutoId()
         let toId = user!.id!
         let fromId = Auth.auth().currentUser!.uid
         let messageTime = Int(NSDate().timeIntervalSince1970)
         let values = ["textMessage": inputTextField.text!, "toId": toId, "fromId": fromId,  as [String : Any]
         //        messageChildRef.updateChildValues(values)
         messageChildRef.updateChildValues(values) { (error, ref) in
         if error != nil {
         print(error!)
         }
         // trasnfering ids between node, so you don't need text anymore
         self.inputTextField.text = nil
         
         let userMessagesRef = Database.database().reference().child("user_messages").child(fromId).child(toId)
         
         // covert messageChildRef that is type of NSObject to string to use it
         let messagesChildKey = messageChildRef.key
         userMessagesRef.updateChildValues([messagesChildKey: 1])
         
         let recipentMessagesRef = Database.database().reference().child("user_messages").child(toId).child(fromId)
         recipentMessagesRef.updateChildValues([messagesChildKey: 1])
         
         }*/
        
        //        print(inputTextField.text)
    }
    
    func handleMessagesImagesWithFirebase(_ imageUrl: String,_ image: UIImage) {
        
        let properties: [String: AnyHashable] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        handleMessageWithProperties(properties as [String : AnyObject])
        
    }
    
    func handleMessageWithProperties(_ properties: [String: AnyObject]) {
        let ref = Database.database().reference().child("messages")
        let messageChildRef = ref.childByAutoId()
        
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        //        let messageTime = Int(Date().timeIntervalSince1970)
        let messageTime = NSNumber(value: Int(Date().timeIntervalSince1970))
        var values = ["toId": toId as AnyObject, "fromId": fromId as AnyObject, "messageTime": messageTime as AnyObject] as [String : AnyObject]
        
        // append properties to values
        // to express key use $0, and to express value user $1
        properties.forEach({values[$0] = $1})
        
        //        messageChildRef.updateChildValues(values)
        messageChildRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
            }
            // trasnfering ids between node, so you don't need text anymore
            self.messageContainerView.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user_messages").child(fromId).child(toId)
            
            // convert messageChildRef that is type of NSObject to string to use it
            let messagesChildKey = messageChildRef.key
            userMessagesRef.updateChildValues([messagesChildKey: 1])
            
            let recipentMessagesRef = Database.database().reference().child("user_messages").child(toId).child(fromId)
            recipentMessagesRef.updateChildValues([messagesChildKey: 1])
        }
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var messageImageView: UIImageView?
    var zoomImageView: UIImageView?
    
    func handleZoomingInImageView(_ messageImageView: UIImageView) {
        // to hide image, when you click imageView, then when zooming out, we 'll unhide it
        self.messageImageView = messageImageView
        self.messageImageView?.isHidden = true
        
        startingFrame = messageImageView.superview?.convert(messageImageView.frame, to: nil)
        //            print(startingFrame)
        
        zoomImageView = UIImageView(frame: startingFrame!)
        //            zoomImageView.backgroundColor = .red
        zoomImageView?.image = messageImageView.image
        zoomImageView?.isUserInteractionEnabled = true
        zoomImageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomingOutImageView)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomImageView!)
            
            self.messageContainerView.isHidden = true
            
            UIView.animate(withDuration: 0.85, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                // h2 = h1/w1 * w2
                let height = (self.startingFrame!.height / self.startingFrame!.width) * keyWindow.frame.width
                
                self.zoomImageView?.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                self.zoomImageView?.center = keyWindow.center
                
                self.blackBackgroundView?.alpha = 1
                
            }, completion: nil)
        }
        
    }
    func handleZoomingOutImageView() {
        
        self.zoomImageView?.frame = startingFrame!
        self.zoomImageView?.layer.cornerRadius = 16
        self.zoomImageView?.layer.masksToBounds = true
        
        
        UIView.animate(withDuration: 0.85, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.blackBackgroundView?.alpha = 0
            //let zoomOutImageView = UIImageView()
            //                zoomOutImageView.frame = self.startingFrame!
            self.messageContainerView.isHidden = false
            
        }) { (completed) in
            self.zoomImageView?.removeFromSuperview()
            self.messageImageView?.isHidden = false
        }
    }
    
    
}




