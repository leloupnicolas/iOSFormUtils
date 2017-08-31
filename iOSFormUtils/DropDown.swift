//
//  DropDown.swift
//  application
//
//  Created by Nicolas LELOUP on 25/02/2017.
//  Copyright © 2017 Nicolas LELOUP - Buzznative. All rights reserved.
//

import Foundation
import SBPickerSelector
import UIKit
import UIKitExtensions

protocol DropDownDataSource {
  func controllerForDropDownDisplaying(_ dropDown: DropDown) -> UIViewController

  func valuesForDropDown(_ dropDown: DropDown) -> [String]

  func selectedIndexForDropDown(_ dropDown: DropDown) -> Int?

  func placeholderKeyForDropDown(_ dropDown: DropDown) -> String?

  func isRequired(_ dropDown: DropDown) -> Bool

  func getTextColor() -> UIColor

  func getFontName() -> String

  func getFontSize() -> CGFloat

  func getRightIcon() -> UIImage
}

protocol DropDownDelegate {
  func dropDown(_ dropDown: DropDown!, selectedValue value: String!, index: Int)

  func dropDownDeselectedValue(_ dropDown: DropDown!)
}

public class DropDown: OwnView {
  var dateFormat = "dd/MM/y"

  var delegate: DropDownDelegate!
  var dataSource: DropDownDataSource! {
    didSet {
      updatePlaceholder()
    }
  }

  var picker: SBPickerSelector = SBPickerSelector.picker()
  var values: [String]!
  var currentTextField: FormInput!
  var selectedIndex: Int!

  var mainColor: UIColor = UIColor.blue

  @IBOutlet weak var rightIcon: UIImageView!
  @IBOutlet weak var titleTextField: FormInput!

  override public func loadView() {
    super.loadView()

    picker.delegate = self
    picker.pickerType = SBPickerSelectorType.text
    picker.doneButtonTitle = "OK"
    picker.doneButton?.tintColor = mainColor
    picker.cancelButtonTitle = "Annuler"
    picker.cancelButton?.tintColor = mainColor

    updatePlaceholder()

    reloadData()

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(DropDown.textFieldBecameFirstResponder(_:)),
        name: NSNotification.Name(rawValue: "textFieldBecameFirstResponder"),
        object: nil
    )
  }

  func updatePlaceholder() {
    if let _ = dataSource {
      if let existingPlaceholder = dataSource.placeholderKeyForDropDown(self) {
        updatePlaceholderWithValue(existingPlaceholder)
      }
    }
  }

  func updatePlaceholderWithValue(_ value: String) {
    titleTextField.attributedPlaceholder = NSAttributedString(
        string: value,
        attributes: [
            NSForegroundColorAttributeName: self.dataSource.getTextColor(),
            NSFontAttributeName: UIFont(name: self.dataSource.getFontName(), size: self.dataSource.getFontSize())!
        ]
    )
  }

  func updateSelectedIndex(_ newIndex: Int) {
    selectedIndex = newIndex
    picker.pickerView.selectRow(selectedIndex, inComponent: 0, animated: true)
    if let data: [String] = picker.pickerData as? [String] {
      pickerSelector(picker, selectedValue: data[selectedIndex], index: selectedIndex)
      picker.pickerView(picker.pickerView, didSelectRow: selectedIndex, inComponent: 0)
    }
  }

  func resetValue() {
    titleTextField.text! = ""
  }

  func reloadData() {
    updatePlaceholder()
    if let itsDataSource = dataSource {
      var values: [String] = itsDataSource.valuesForDropDown(self)
      var offset = 0
      if nil != dataSource && !dataSource.isRequired(self) {
        values.insert("-", at: 0)
        offset = 1
      }

      picker.pickerData = values
      if let dataSourceSelectedIndex: Int = itsDataSource.selectedIndexForDropDown(self) {
        updateSelectedIndex(dataSourceSelectedIndex + offset)
      }
    }
  }

  func presentDropDown() {
    if let itsDataSource = dataSource {
      if let textField = currentTextField {
        textField.resignFirstResponder()
      }
      picker.showPickerOver(itsDataSource.controllerForDropDownDisplaying(self))
    }
  }

  @IBAction func mainButtonTouched(_ sender: AnyObject) {
    presentDropDown()
  }

  func textFieldBecameFirstResponder(_ notification: Notification) {
    if let textField: FormInput = notification.object as? FormInput {
      if textField != titleTextField {
        currentTextField = textField
      } else {
        currentTextField = nil
      }
    }
  }
}

extension DropDown: OwnViewProtocol {
  public var viewName: String {
    return "DropDown"
  }
}

extension DropDown: SBPickerSelectorDelegate {
  public func pickerSelector(_ selector: SBPickerSelector!, selectedValue value: String!, index idx: Int) {
    let required = (nil != dataSource && !dataSource.isRequired(self))
    var offset = 0
    if (required && 0 != idx) || !required {
      titleTextField.text = value
      titleTextField.textColor = self.dataSource.getTextColor()
      titleTextField.font = UIFont(name: self.dataSource.getFontName(), size: self.dataSource.getFontSize())
      if required {
        offset = 1
      }

      if let itsDelegate = delegate {
        itsDelegate.dropDown(self, selectedValue: value, index: idx - offset)
        self.selectedIndex = idx - offset
      }
    } else {
      resetValue()

      if let itsDelegate = delegate {
        itsDelegate.dropDownDeselectedValue(self)
        self.selectedIndex = nil
      }
    }
  }

  public func pickerSelector(_ selector: SBPickerSelector!, dateSelected date: Date!) {
    if .date == picker.pickerType {
      if let _ = date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.dateFormat

        titleTextField.text = dateFormatter.string(from: date)
        titleTextField.textColor = self.dataSource.getTextColor()
        titleTextField.font = UIFont(name: self.dataSource.getFontName(), size: self.dataSource.getFontSize())

        if let dateSelf: DateDropDown = self as? DateDropDown {
          if let dateDropDownDelegate: DateDropDownDelegate = dateSelf.dateDropDownDelegate {
            dateDropDownDelegate.dropDown(dateSelf, selectedDate: date)
            dateSelf.selectedDate = date
          }
        }
      }
    }
  }
}
