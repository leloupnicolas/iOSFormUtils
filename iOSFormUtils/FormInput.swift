//
//  ValidatedInput.swift
//  application
//
//  Created by Nicolas LELOUP on 18/09/2015.
//  Copyright © 2015 Nicolas LELOUP - Buzznative. All rights reserved.
//

// MARK: Constants
let tfBecameFirstResponderNotifName = "textFieldBecameFirstResponder"
let tfResignedFirstResponderNotifName = "textFieldResignedFirstResponder"
let tfReturnedNotifName = "textFieldReturned"

// MARK: Protocols

/// Delegate protocol for FormInput
public protocol FormInputDelegate {
  func didEnterEditionMode(_ input: FormInput)
  func didExitEditionMode(_ input: FormInput)
}

/// Data source protocol for FormInput
public protocol FormInputDataSource {
  func applyCustomInit(_ input: FormInput)
}

// MARK: Class
/// UITextfield child class for easy form inputs handling
open class FormInput: UITextField {
  // MARK: Class variables
  open var inputDataSource: FormInputDataSource!
  open var formInputDelegate: FormInputDelegate!
  fileprivate var inputAccessory: UIView!
  fileprivate var validationHandler: ValidatedFormInput!
  open var validationDelegate: ValidatedFormInputDelegate!
  open var validationDataSource: ValidatedFormInputDataSource!
  
  // MARK: Superclass overrides
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.commonInit()
  }
  
  required public init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
    self.commonInit()
  }
  
  // MARK: Public own methods
  
  /**
   Main initializer
   */
  open func commonInit() {
    self.delegate = self
    self.validationHandler = self
    
    if let _ = inputDataSource {
      inputDataSource.applyCustomInit(self)
    }
  }
  
  // MARK: Public own methods
  
  /**
   Stops the current edition.
   */
  open func stopEditing() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: tfResignedFirstResponderNotifName), object: self)
    self.resignFirstResponder()
  }
}

// MARK: Extensions
extension FormInput: UITextFieldDelegate {
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    if let _ = formInputDelegate {
      formInputDelegate.didEnterEditionMode(self)
    }
    if let _ = validationDelegate {
      validationDelegate.didExitErrorMode(self)
    }
    NotificationCenter.default.post(name: Notification.Name(rawValue: tfBecameFirstResponderNotifName), object: self)
  }
  
  public func textFieldDidEndEditing(_ textField: UITextField) {
    if let _ = formInputDelegate {
      formInputDelegate.didExitEditionMode(self)
    }
  }
  
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    NotificationCenter.default.post(name: Notification.Name(rawValue: tfReturnedNotifName), object: self)
    
    return true;
  }
}

