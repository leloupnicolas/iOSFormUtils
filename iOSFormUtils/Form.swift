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
public protocol ValidatedFormKeyboardDelegate {
  /**
   Triggered when the keybiard return key is touched on the last field.
   */
  func goReturnKeyTouched()
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
  public var keyboardDelegate: ValidatedFormKeyboardDelegate!
  
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
    self.frame = originalFrame
  }
  
  // MARK: NSNotification listeners
  
  /**
   If input attached to the notification is the last of the form, submit is triggered. If not, focus is given to the following input.
   
   - Parameter notification: the received notification.
   */
  func textFieldReturnedFired(notification: NSNotification) {
    if let textfield = notification.object as? FormInput {
      if let index: Int = indexForInput(textfield) {
        if isLastInput(textfield) {
          textfield.stopEditing()
          resetScrollingZone()
          if let _ = keyboardDelegate {
            keyboardDelegate.goReturnKeyTouched()
          }
        } else {
          inputs[index + 1].becomeFirstResponder()
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
   Checks if the given input is the last one.
   
   - Parameter input: the input to compare
   */
  private func isLastInput(input: FormInput) -> Bool {
    return input == inputs.last
  }
  
  /**
   Gives the index of a given input
   
   - Parameter input: the input to get the index.
   */
  private func indexForInput(input: FormInput) -> Int? {
    return inputs.indexOf(input)
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
