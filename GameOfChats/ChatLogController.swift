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
            // so you can add some text messages that you wrote in collectionView here in the same place you have info about user, coz this property will work after pressing on cell, so i have insurance about going to chatlogController directly after pressing on cell
            observeMessages()
        }
    }
    var messages = [Message]()
    func observeMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid, let userId = user?.id else { return }
        let userMessagesRef = Database.database().reference().child("user_messages").child(uid).child(userId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageKey = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageKey)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {
                    return
                }
                
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.toId = dictionary["toId"] as? String
                message.textMessage = dictionary["textMessage"] as? String
                message.messageTime = dictionary["messageTime"] as? NSNumber
                
                message.imageUrl = dictionary["imageUrl"] as? String
                message.imageHeight = dictionary["imageHeight"] as? NSNumber
                message.imageWidth = dictionary["imageWidth"] as? NSNumber
                
                message.videoUrl = dictionary["videoUrl"] as? String
                
                self.messages.append(message)
                
                self.collectionView?.reloadData()
                // after reloading data, just show the last index at messages array
                let indexPath = NSIndexPath(item: self.messages.count - 1 , section: 0)
                self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    let cellId = "cellID"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // to change back button title
        let backItem = UIBarButtonItem()
        backItem.title = user?.name
        navigationController?.navigationBar.topItem?.backBarButtonItem = backItem
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(MessagesViewCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        setupKeyboardWithContainerView()
    }
    
    lazy var messageContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    @objc func handlePickerTap() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoFileUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
            handleSelectedVideoWithUrl(videoFileUrl)
            
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

                if let thumbnailImage = self.handleThumbnailImageWithFileUrl(url) {
                    self.loadMessagesImagesIntoStorage(thumbnailImage, completion: { (imageUrl) in
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
                        
                        self.handleMessageWithProperties(properties)
                        
                    })
                    
                }
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
                if let err = snapshot.error as NSError? {
                    print(err)
                }
            }
            
            localUrl.observe(.success, handler: { (snapshot) in
                
                UIView.animate(withDuration: 7, delay: 3, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.navigationItem.title = "Done"
                }, completion: { (_) in
                    
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
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let err {
            print(err)
        }
        return nil
    }
    func handleSelectedImageWithInfo(_ info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageViewFromPicker: UIImage?
        
        if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageViewFromPicker = originalImage
        } else if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            selectedImageViewFromPicker = editedImage
        }
        
        if let selectedImage = selectedImageViewFromPicker {
            loadMessagesImagesIntoStorage(selectedImage, completion: { (imageUrl) in
                self.handleMessagesImagesWithFirebase(imageUrl, selectedImage)
            })
         
        }
    }
    func loadMessagesImagesIntoStorage(_ image: UIImage, completion:@escaping (_ imageUrl: String)->()) {
        let imageId = UUID().uuidString
        let ref = Storage.storage().reference().child("friend'sMessagesImages").child("\(imageId)")
        
        guard let uploadCompressionImages = image.jpegData(compressionQuality: 0.1) else { return }
    
        ref.putData(uploadCompressionImages, metadata: nil) { (metadata, error) in
            if error != nil {
                print("failed to upload image into your friend messages, coz: ", error!)
                return
            }
            
            ref.downloadURL(completion: { (url, err) in
                if err != nil {
                    print("failed to store users messages", err?.localizedDescription ?? "")
                    return
                }
                
                if let imageUrl = url?.absoluteString {
                    completion(imageUrl)
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
    
    func setupKeyboardWithContainerView() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboadDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
    }
    @objc func handleKeyboadDidShow() {
        // if it doesn't exist any message or (if there is one message, coz it doesn't exist messages.count = 0), don't use this function
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    func handleKeyboardWillShow(notification: NSNotification) {
        
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            // isKeyboardShowing is condition, if isKeyboardShowing = notification.name, so it will be UIKeyboardWillShow
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            self.bottomContainerViewAnchor?.constant = isKeyboardShowing ? -keyboardFrame!.height : 0
        }
        
        UIView.animate(withDuration: duration!, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { (completed) in
            
        }
        
    }
    
    var bottomContainerViewAnchor: NSLayoutConstraint?
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessagesViewCell
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
        
        // bounds handle landscape and portrait
        // use bounds to fix problem of collectionView that be affected by inputAccessoryView that be laid out
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height!)
    }
    fileprivate func estimatedSizeOfTextAndImageFrame(_ addTextOrImage: String)-> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        
        return NSString(string: addTextOrImage).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }
    
    @objc func handleSend() {
        
        let properties: [String: AnyObject] = ["textMessage": messageContainerView.inputTextField.text! as AnyObject]
        
        handleMessageWithProperties(properties)
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
        let messageTime = NSNumber(value: Int(Date().timeIntervalSince1970))
        var values = ["toId": toId as AnyObject, "fromId": fromId as AnyObject, "messageTime": messageTime as AnyObject] as [String : AnyObject]
        
        // append properties to values
        // to express key use $0, and to express value user $1
        properties.forEach({values[$0] = $1})
        
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
        
        zoomImageView = UIImageView(frame: startingFrame!)
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
    @objc func handleZoomingOutImageView() {
        
        self.zoomImageView?.frame = startingFrame!
        self.zoomImageView?.layer.cornerRadius = 16
        self.zoomImageView?.layer.masksToBounds = true
        
        
        UIView.animate(withDuration: 0.85, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.blackBackgroundView?.alpha = 0
            self.messageContainerView.isHidden = false
            
        }) { (completed) in
            self.zoomImageView?.removeFromSuperview()
            self.messageImageView?.isHidden = false
        }
    }
    
    
}




