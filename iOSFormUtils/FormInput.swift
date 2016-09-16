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
  func didEnterEditionMode(input: FormInput)
  func didExitEditionMode(input: FormInput)
}

/// Data source protocol for FormInput
public protocol FormInputDataSource {
  func applyCustomInit(input: FormInput)
}

// MARK: Class
/// UITextfield child class for easy form inputs handling
public class FormInput: UITextField {
  // MARK: Class variables
  public var inputDataSource: FormInputDataSource!
  public var formInputDelegate: FormInputDelegate!
  private var inputAccessory: UIView!
  private var validationHandler: ValidatedFormInput!
  var validationDelegate: ValidatedFormInputDelegate!
  var validationType = ValidatedFormInputType.NoValidation
  
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
  public func commonInit() {
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
  public func stopEditing() {
    NSNotificationCenter.defaultCenter().postNotificationName(tfResignedFirstResponderNotifName, object: self)
    self.resignFirstResponder()
  }
}

// MARK: Extensions
extension FormInput: UITextFieldDelegate {
  public func textFieldDidBeginEditing(textField: UITextField) {
    if let _ = formInputDelegate {
      formInputDelegate.didEnterEditionMode(self)
    }
    if let _ = validationDelegate {
      validationDelegate.didExitErrorMode(self)
    }
    NSNotificationCenter.defaultCenter().postNotificationName(tfBecameFirstResponderNotifName, object: self)
  }
  
  public func textFieldDidEndEditing(textField: UITextField) {
    if let _ = formInputDelegate {
      formInputDelegate.didExitEditionMode(self)
    }
  }
  
  public func textFieldShouldReturn(textField: UITextField) -> Bool {
    NSNotificationCenter.defaultCenter().postNotificationName(tfReturnedNotifName, object: self)
    
    return true;
  }
}

