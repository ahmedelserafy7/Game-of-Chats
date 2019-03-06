//
//  MessagesViewCell.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/23/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import AVFoundation

class MessagesViewCell: UICollectionViewCell {

    var message: Message?
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.text = "Hey hey, boy"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.isUserInteractionEnabled = false
//        tv.isEditable = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    static let bubbleViewBackground = UIColor(r: 0, g: 137, b: 249)
    let bubbleView: UIView = {
        let bv = UIView()
        bv.layer.cornerRadius = 16
        bv.layer.masksToBounds = true
        bv.translatesAutoresizingMaskIntoConstraints = false
        bv.backgroundColor = bubbleViewBackground
        return bv
    }()
    
    let profileImageView: CustomImageView = {
        let imageView = CustomImageView()
//        imageView.image = #imageLiteral(resourceName: "Bill-Gates")
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

   lazy var messageImageView: CustomImageView = {
        let imageView = CustomImageView()
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomingImageTap)))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let aIV = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aIV.hidesWhenStopped = true
        aIV.translatesAutoresizingMaskIntoConstraints = false
        return aIV
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "play")?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
//        button.tintColor = .white
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var videoPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    func handlePlay() {
        //print("Video play")
        
        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
            videoPlayer = AVPlayer(url: url)
            
            playerLayer = AVPlayerLayer(player: videoPlayer)
            
            playerLayer?.frame = bubbleView.bounds
            bubbleView.layer.addSublayer(playerLayer!)
            
            videoPlayer?.play()
            playButton.isHidden = true
            activityIndicator.startAnimating()
            
            setupGradientView()
            
        }
    }
    
    // to preform cleanup, when reuse cell
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // to cleanup layer, when reuse cell
        playerLayer?.removeFromSuperlayer()
        
        // to kill the audio process in the background
        videoPlayer?.pause()
        
//        activityIndicator.stopAnimating()
    }
    
    func setupGradientView() {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bubbleView.bounds
            gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
            gradientLayer.locations = [0.7,1]
            
            bubbleView.layer.addSublayer(gradientLayer)
    }
    
    var chatLogController: ChatLogController?
    func handleZoomingImageTap() {
        if message?.videoUrl != nil {
            return
        }
        chatLogController?.handleZoomingInImageView(messageImageView)
        
    }
    var bubbleViewWidthAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
       bubbleView.addSubview(messageImageView)
       
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        
        bubbleView.addSubview(playButton)
        // add x, y, width, height constraints anchor
        playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        bubbleView.addSubview(activityIndicator)
        // add x, y, width, height constraints anchor
        activityIndicator.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 44).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        // add some contraints, x, y, w, h by ios 9 constraints
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
//        bubbleViewLeftAnchor?.isActive = false
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleViewWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
            bubbleViewWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        // add some contraints, x, y, w, h by ios 9 constraints
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -6).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor,constant: 6).isActive = true
        textView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
//        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
//        textView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
