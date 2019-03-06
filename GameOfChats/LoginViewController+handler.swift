//
//  LoginController+handler.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/4/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegisterButton() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("email or password don't exist")
            // get out of return, if email, and password don't exist and return error
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error != nil {
                print(error!)
                // to get out of error, if it doesn't exist error
                return
            }
            
            // successfully authenticated data....
            let uniqueID = UUID().uuidString
            let storagRef = Storage.storage().reference().child("usersProfileImages").child("\(uniqueID).jpg")
            
            // if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
            
            // the proper way to compress the profileImageView
            guard let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) else { return }
            storagRef.putData(uploadData, metadata: nil, completion: { (metaData, error) in
                if error != nil {
                    print(error!)
                }
                
                guard let uid = user?.user.uid else {
                    return
                }
                
                storagRef.downloadURL(completion: { (url, err) in
                    if err != nil {
                        print("Failed to register new user, ", err?.localizedDescription ?? "")
                        return
                    }
                    
                    
                    if let profileImageUrl = url?.absoluteString {
                        
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl] as [String : Any]
                        self.registerUserIntoDatabaseWithUID(uid, values: values as[String: AnyObject])
                        // print(metaData!)
                    }
                    
                })
                
            })
            
            
        }
    }
    
    func registerUserIntoDatabaseWithUID(_ uid: String, values: [String: AnyObject]) {
        //        let ref = Database.database().reference(fromURL: "https://gameofchats-ce67d.firebaseio.com/")
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        
        usersRef.updateChildValues(values, withCompletionBlock: { (err, dataRef) in
            if err != nil {
                print(err!)
                return
            }
            
            //self.myOwnMessages?.fetchUserWithNavbarTitle()
            let user = User(dictionary: values)
            // it's important setter (values keys) match with user parameters, potentially crashes if setter doesn't match with the values keys
            user.setValuesForKeys(values)
            self.myMessagesController?.setupNavBarTitleWithProfileImageView(user)
            //self.myOwnMessages?.navigationItem.title = values["name"] as? String
            self.dismiss(animated: true, completion: nil)
            print("Saved user successfully into firebase db")
        })
    }
    
    func handleSelectedImageView(_ sender: UITapGestureRecognizer) {
        
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        picker.delegate = self
        // print("selected image")
    }
    
    // to control cancel button
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
        print("canceledButton")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPhotoLibrary: UIImage?
        
        if let editingImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPhotoLibrary = editingImage
            // print(editingImage.size)
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPhotoLibrary = originalImage
            // print(originalImage.size)
        }
        if let selectedImage = selectedImageFromPhotoLibrary {
            self.profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
        // print(info)
    }
    
    
}
