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
        
        if name.isEmpty || email.isEmpty || password.isEmpty {
            
            self.nameTextField.text = nil
            self.emailTextField.text = nil
            self.passwordTextField.text = nil
            self.profileImageView.image = UIImage(named: "gameofthrones_splash")
            
            blackView.alpha = 0
            activityIndicator.stopAnimating()
            
            self.displayAlert("One of the required fields is missing")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            self.blackView.alpha = 0
            self.activityIndicator.stopAnimating()
            
            if error != nil {
                print(error!)
                
                self.nameTextField.text = nil
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
                
                self.displayAlert("Couldn't successfully perform this request, please try again..")

                // to get out of error, if it doesn't exist error
                return
            }
            
            // successfully authenticated data....
            let uniqueID = UUID().uuidString
            let storagRef = Storage.storage().reference().child("usersProfileImages").child("\(uniqueID).jpg")

            // the proper way to compress the profileImageView
            guard let profileImage = self.profileImageView.image, let uploadData = profileImage.jpegData(compressionQuality: 0.1) else { return }
            
            storagRef.putData(uploadData, metadata: nil, completion: { (metaData, error) in
                if error != nil {
                    print(error!)
                    self.displayAlert("Something went wrong!")
                    return
                }
                
                guard let uid = user?.uid else {
                    return
                }
                
                storagRef.downloadURL(completion: { (url, err) in
                    if err != nil {
                        print("Failed to register new user, ", err?.localizedDescription ?? "")
                        self.displayAlert("Something went wrong!")
                        return
                    }
                    
                    
                    if let profileImageUrl = url?.absoluteString {
                        
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl] as [String : Any]
                        self.registerUserIntoDatabaseWithUID(uid, values: values as[String: AnyObject])
                    }
                    
                })
                
            })
            
            
        }
        
    }
    
    func registerUserIntoDatabaseWithUID(_ uid: String, values: [String: AnyObject]) {
        
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        
        usersRef.updateChildValues(values, withCompletionBlock: { (err, dataRef) in
            if err != nil {
                print(err!)
                self.displayAlert("Couldn't successfully perform this request, please try again..")
                return
            }
            
            let user = User()
            user.id = values["id"] as? String
            user.name = values["name"] as? String
            user.email = values["email"] as? String
            user.profileImageUrl = values["profileImageUrl"] as? String
            // it's important setter (values keys) match with user parameters, potentially crashes if setter doesn't match with the values keys
//            user.setValuesForKeys(values)
            self.myMessagesController?.setupNavBarTitleWithProfileImageView(user)
            self.dismiss(animated: true, completion: nil)
            print("Saved user successfully into firebase db")
        })
    }
    
    @objc func handleSelectedImageView(_ sender: UITapGestureRecognizer) {
        
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
        var selectedImageFromPhotoLibrary: UIImage?
        
        if let editingImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImageFromPhotoLibrary = editingImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            selectedImageFromPhotoLibrary = originalImage
        }
        if let selectedImage = selectedImageFromPhotoLibrary {
            self.profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    
}
