//
//  Form.swift
//  Pods
//
//  Created by Nicolas LELOUP on 15/09/2016.
//
//

import Foundation

// MARK: Protocols

/// Delegate protocol to handle form submitting
public protocol FormDelegate {
  /**
   Triggered when the keybiard return key is touched on the last field.
   */
  func goReturnKeyTouched()
  
  /*
   Returns the first input of a form
   
   - Parameter form: The form
   
   - Return: The first input.
   */
  func getFirstInput(form: Form) -> FormInput
  
  /*
   Returns the following input of a form input
   
   - Parameter form: The form
   - Parameter currentInput: The current input
   
   - Return: If the current input is the last one, nil. If not, the following input.
   */
  func getNextInput(form: Form, currentInput: FormInput) -> FormInput?
}

// MARK: Class
/// UIScrollView child class for forms handling
public class Form: UIScrollView {
  // MARK: Class properties
  /// The original frame of the form
  var originalFrame: CGRect!
  
  /// Flag to stor either it has been scrolled because of keyboard appearing
  var viewScrolledForKeyboard = false
  
  /// The keyboard frame height
  var keyboardViewHeight: CGFloat = 216
  
  /// The stored delegate
  public var formDelegate: FormDelegate!
  
  /// The current input which has been focused
  private var currentInput: FormInput!
  
  /// The form inputs
  public var inputs: [FormInput] = [] {
    didSet {
      handleInputsReturnKeys()
    }
  }
  
  // MARK: Superclass overrides
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required public init(coder: NSCoder) {
    super.init(coder: coder)!
    commonInit()
  }
  
  override public func addSubview(view: UIView) {
    super.addSubview(view)
    
    if let input: FormInput = view as? FormInput {
      input.formInputDelegate = self
      inputs.append(input)
    }
  }
  
  // MARK: Private own methods
  
  /**
   Custom initializer
   */
  private func commonInit() {
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(Form.keyboardShown(_:)),
      name: UIKeyboardDidShowNotification,
      object: nil
    )
    
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(Form.textFieldReturnedFired(_:)),
      name: tfReturnedNotifName,
      object: nil
    )
    
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(Form.textFieldBecameFirstResponder(_:)),
      name: tfBecameFirstResponderNotifName,
      object: nil
    )
    if let _ = formDelegate {
      currentInput = formDelegate.getFirstInput(self)
    }
  }
  
  /**
   Handles return keys type for inputs
   */
  private func handleInputsReturnKeys() {
    for input in inputs {
      if let textField: UITextField = input as? UITextField {
        if textField == inputs.last as? UITextField {
          textField.returnKeyType = .Go
        } else {
          textField.returnKeyType = .Next
        }
      }
    }
  }
  
  /**
   Updates the scrollview frame when keyboard appears.
   Scrolls to make the current field visible.
   */
  private func minimizeScrollingZone(input: FormInput) {
    if (!viewScrolledForKeyboard) {
      viewScrolledForKeyboard = true
      originalFrame = self.frame
      self.translatesAutoresizingMaskIntoConstraints = true
      let newFrame = CGRect(
        x: frame.origin.x,
        y: frame.origin.y,
        width: frame.width,
        height: frame.height - keyboardViewHeight
      )
      self.frame = newFrame
    }
    
    UIView.animateWithDuration(0.2) {
      self.contentOffset = CGPoint(x: 0, y: input.frame.origin.y - self.frame.height/2 + input.frame.height/2)
    }
  }
  
  /**
   Resets the scrolling zone to its original value.
   */
  private func resetScrollingZone() {
    viewScrolledForKeyboard = false
    if let _ = originalFrame {
      self.frame = originalFrame
    }
  }
  
  // MARK: NSNotification listeners
  
  /**
   If input attached to the notification is the last of the form, submit is triggered. If not, focus is given to the following input.
   
   - Parameter notification: the received notification.
   */
  func textFieldReturnedFired(notification: NSNotification) {
    if let textfield = notification.object as? FormInput {
      if isLastInput(textfield) {
        textfield.stopEditing()
        resetScrollingZone()
        if let _ = formDelegate {
          formDelegate.goReturnKeyTouched()
        }
      } else {
        if let _ = formDelegate {
          formDelegate.getNextInput(self, currentInput: currentInput)?.becomeFirstResponder()
        }
      }
    }
  }
  
  /**
   Updates the keyboard height with the right value.
   
   - Parameter notification: the received notification
   */
  func keyboardShown(notification: NSNotification) {
    let info  = notification.userInfo!
    let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
    
    let rawFrame = value.CGRectValue
    let keyboardFrame = self.convertRect(rawFrame, fromView: nil)
    
    keyboardViewHeight = keyboardFrame.height
  }
  
  /**
   Stores the current textfield.
   
   - Parameter notification: the received notification
   */
  func textFieldBecameFirstResponder(notification: NSNotification) {
    if let textfield = notification.object as? FormInput {
      currentInput = textfield
    }
  }
  
  /**
   Checks if the given input is the last one.
   
   - Parameter input: the input to compare
   */
  private func isLastInput(input: FormInput) -> Bool {
    if let _ = formDelegate {
      if let nextInput: FormInput = formDelegate.getNextInput(self, currentInput: currentInput) {
        return false
      }
    }
    
    return true
  }
}

// MARK: Extensions
extension Form: FormInputDelegate {
  public func didEnterEditionMode(input: FormInput) {
    dispatch_async(dispatch_get_main_queue()) {
      self.minimizeScrollingZone(input)
    }
  }
  
  public func didExitEditionMode(input: FormInput) {}
}
