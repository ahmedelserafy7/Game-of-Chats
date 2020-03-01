//
//  LoginViewController.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 12/30/17.
//  Copyright © 2017 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    var myMessagesController: MessagesController?
    
    let inputsContainerView: UIView = {
        let view  = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.textContentType = UITextContentType.oneTimeCode
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
   
    let nameSeperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        return seperatorView
    }()
    
    lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.autocapitalizationType = .none
        tf.textContentType = UITextContentType.oneTimeCode
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        tf.textContentType = UITextContentType.oneTimeCode
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    @objc func handleTextInputChange() {
       
        let isFormValid = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0 
        if isFormValid {
            loginRegisterButton.isEnabled = true
            loginRegisterButton.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        } else {
            loginRegisterButton.isEnabled = false
            loginRegisterButton.backgroundColor = UIColor(white: 1, alpha: 0.3)
        }
        
    }
    
    let emailSeperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        return seperatorView
    }()
    
    let blackView: UIView = {
        let bv = UIView()
        bv.backgroundColor = .black
        bv.layer.cornerRadius = 16
        bv.layer.masksToBounds = true
        bv.translatesAutoresizingMaskIntoConstraints = false
        return bv
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let aI = UIActivityIndicatorView(style: .white)
        aI.hidesWhenStopped = true
        aI.translatesAutoresizingMaskIntoConstraints = false
        return aI
    }()
    
    func setupAuthorizing() {
        
        view.addSubview(blackView)
        blackView.addSubview(activityIndicator)
        
        blackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        blackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        blackView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        blackView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        
        activityIndicator.centerXAnchor.constraint(equalTo: blackView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: blackView.centerYAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register", for: .normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.3)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(handleLoginRegisterButton), for: .touchUpInside)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc func handleLoginRegisterButton() {
        
        setupAuthorizing()
        self.blackView.alpha = 1
        self.activityIndicator.startAnimating()
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLoginButton()
        } else {
            handleRegisterButton()
        }
    }
    
    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleLoginButton() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        
        if email.isEmpty || password.isEmpty {
            
            self.emailTextField.text = nil
            self.passwordTextField.text = nil
            
            blackView.alpha = 0
            activityIndicator.stopAnimating()
            
            self.displayAlert("One of the required fields is missing")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            self.blackView.alpha = 0
            self.activityIndicator.stopAnimating()
            
            if error != nil {
                print(error!)
                
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
                
                self.displayAlert("Couldn't successfully perform this request, please try again..")
                return
            }
            
            self.myMessagesController?.fetchUserWithNavbarTitle()
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "gameofthrones_splash")
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectedImageView)))
        iv.layer.cornerRadius = 15
        iv.layer.masksToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.tintColor = .white
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(handleLoginRegisterSegmentedControl), for: .valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    @objc func handleLoginRegisterSegmentedControl() {
        
        // titleForSegment: return the title of selected segment, title based on SegmentedControlTitle that you pressed on it
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        
        // height of nameTextField
        
        // to setup constraint from the beginning, to remove free space nameTextFieldHeight place
        nameTextFieldHeightAnchor?.isActive = false
        // means multiplier equal zero: to remove textField, and make textField free space
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        // to remove placeholder of "name" of textField
        // nameTextField.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0
        nameTextFieldHeightAnchor?.isActive = true
        
        nameTextField.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0  ? true : false
        
        // the height of emailTextField
        // to setup constraint from the beginning
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
        
        // must add profileImageView to view at viewDidLoad, to conform to IBAction
        view.addSubview(profileImageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
   @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    func setupLoginRegisterSegmentedControl() {
        // need x, y, width, height
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    
    fileprivate func setupInputsContainerView() {
        // need x, y, width, height
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        
        inputsContainerViewHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeperatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeperatorView)
        inputsContainerView.addSubview(passwordTextField)
        inputsContainerView.addSubview(profileImageView)
        
        // need x, y, width, height
        nameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        // need x, y, width, height
        nameSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive  = true
        nameSeperatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        // need x, y, width, height
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        // need x, y, width, height
        emailSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive  = true
        emailSeperatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // need x, y, width, height
        passwordTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive = true
    }
    
    func setupLoginRegisterButton() {
        // need x, y, width, height
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupProfileImageView() {
        // need x, y, width, height
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

