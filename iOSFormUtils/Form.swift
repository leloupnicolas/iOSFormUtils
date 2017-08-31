//
//  Form.swift
//  Pods
//
//  Created by Nicolas LELOUP on 15/09/2016.
//
//

import Foundation
import SnapKit

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
  func getFirstInput(_ form: Form) -> FormInput
  
  /*
   Returns the following input of a form input
   
   - Parameter form: The form
   - Parameter currentInput: The current input
   
   - Return: If the current input is the last one, nil. If not, the following input.
   */
  func getNextInput(_ form: Form, currentInput: FormInput) -> FormInput?
}

// MARK: Class
/// UIScrollView child class for forms handling
open class Form: UIScrollView {
  // MARK: Class properties
  /// The original frame of the form
  var originalFrame: CGRect!
  
  /// Flag to stor either it has been scrolled because of keyboard appearing
  var viewScrolledForKeyboard = false
  
  /// The keyboard frame height
  var keyboardViewHeight: CGFloat = 216
  var currentOffSet: CGFloat = 0
  
  /// The stored delegate
  public var formDelegate: FormDelegate!
  
  /// The current input which has been focused
  fileprivate var currentInput: FormInput! {
    didSet {
      minimizeScrollingZone(currentInput)
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
  
  override open func addSubview(_ view: UIView) {
    super.addSubview(view)
    
    if let input: FormInput = view as? FormInput {
      input.formInputDelegate = self
    }
  }
  
  // MARK: Private own methods
  
  /**
   Custom initializer
   */
  fileprivate func commonInit() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Form.keyboardShown(_:)),
      name: NSNotification.Name.UIKeyboardDidShow,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Form.textFieldReturnedFired(_:)),
      name: NSNotification.Name(rawValue: tfReturnedNotifName),
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Form.textFieldResignedFirstResponderFired(_:)),
      name: NSNotification.Name(rawValue: tfResignedFirstResponderNotifName),
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Form.textFieldBecameFirstResponder(_:)),
      name: NSNotification.Name(rawValue: tfBecameFirstResponderNotifName),
      object: nil
    )
    if let _ = formDelegate {
      currentInput = formDelegate.getFirstInput(self)
    }
  }
  
  public func reloadData() {
    if let _ = formDelegate {
      currentInput = formDelegate.getFirstInput(self)
    }
    self.handleInputsReturnKeys()
    self.resetScrollingZone()
  }
  
  /**
   Handles return keys type for inputs
   */
  private func handleInputsReturnKeys() {
    let inputs = getOrderedInputs()
    for input in inputs {
      if let input: FormInput = input as? FormInput, nil == input.formInputDelegate {
        input.formInputDelegate = self
      }

      if let textField: UITextField = input as? UITextField {
        if textField == inputs.last as? UITextField {
          textField.returnKeyType = .go
        } else {
          textField.returnKeyType = .next
        }
      }
    }
  }
  
  /**
   Updates the scrollview frame when keyboard appears.
   Scrolls to make the current field visible.
   */
  fileprivate func minimizeScrollingZone(_ input: FormInput) {
    if (!viewScrolledForKeyboard) {
      viewScrolledForKeyboard = true
      self.snp.updateConstraints({ (maker) in
        maker.bottom.equalTo(self.superview!.snp.bottom).offset(-keyboardViewHeight)
      })
      self.layoutIfNeeded()
    }
 
    let offSetToScroll = input.frame.origin.y - self.frame.height/2 + input.frame.height/2
    if 0 < offSetToScroll {
      UIView.animate(withDuration: 0.2, animations: {
        self.contentOffset = CGPoint(x: 0, y: min(offSetToScroll, self.contentSize.height - self.frame.height + input.frame.height/2))
      })
    }
  }
  
  /**
   Resets the scrolling zone to its original value.
   */
  open func resetScrollingZone() {
    viewScrolledForKeyboard = false
    self.snp.updateConstraints({ (maker) in
      maker.bottom.equalTo(self.superview!.snp.bottom)
    })
  }
  
  // MARK: NSNotification listeners
  
  /**
   If input attached to the notification is the last of the form, submit is triggered. If not, focus is given to the following input.
   
   - Parameter notification: the received notification.
   */
  func textFieldReturnedFired(_ notification: Notification) {
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
   Scrolling zone is layered with its original when text field resigned first respnder.

   - Parameter notification: the received notification.
   */
  func textFieldResignedFirstResponderFired(_ notification: Notification) {
    resetScrollingZone()
  }
  
  /**
   Updates the keyboard height with the right value.
   
   - Parameter notification: the received notification
   */
  func keyboardShown(_ notification: Notification) {
    let info  = (notification as NSNotification).userInfo!
    let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]! as AnyObject
    
    let rawFrame = value.cgRectValue
    let keyboardFrame = self.convert(rawFrame!, from: nil)
    
    keyboardViewHeight = keyboardFrame.height
  }
  
  /**
   Stores the current textfield.
   
   - Parameter notification: the received notification
   */
  func textFieldBecameFirstResponder(_ notification: Notification) {
    if let textfield = notification.object as? FormInput {
      currentInput = textfield
    }
  }
  
  /**
   Checks if the given input is the last one.
   
   - Parameter input: the input to compare
   */
  fileprivate func isLastInput(_ input: FormInput) -> Bool {
    if let _ = formDelegate {
      if let nextInput: FormInput = formDelegate.getNextInput(self, currentInput: currentInput) {
        return false
      }
    }
    
    return true
  }
  
  /**
   Gets the ordered inputs of the form
   
   - Return: the ordered inputs
   */
  func getOrderedInputs() -> [FormInput] {
    var inputs: [FormInput] = []
    if let _ = formDelegate {
      var inputToAdd: FormInput? = formDelegate.getFirstInput(self)
      while nil != inputToAdd {
        inputs.append(inputToAdd!)
        inputToAdd = formDelegate.getNextInput(self, currentInput: inputToAdd!)
      }
    }
    
    return inputs
  }
}

// MARK: Extensions
extension Form: FormInputDelegate {
  public func didEnterEditionMode(_ input: FormInput) {
    DispatchQueue.main.async {
      self.minimizeScrollingZone(input)
    }
  }
  
  public func didExitEditionMode(_ input: FormInput) {}
}
