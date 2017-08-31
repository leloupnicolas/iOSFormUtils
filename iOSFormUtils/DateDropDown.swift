//
//  DateDropDown.swift
//  application
//
//  Created by Nicolas LELOUP on 25/02/2017.
//  Copyright © 2017 Nicolas LELOUP - Buzznative. All rights reserved.
//

import Foundation
import UIKit

protocol DateDropDownDelegate {
  func dropDown(_ dropDown: DateDropDown!, selectedDate value: Date!)
}

public class DateDropDown: DropDown {
  var selectedDate: Date! {
    didSet {
      if selectedDate != oldValue {
        self.refreshDateView()
      }
    }
  }
  var dateDropDownDelegate: DateDropDownDelegate!

  func refreshDateView() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = self.dateFormat

    titleTextField.text = dateFormatter.string(from: selectedDate)
    if let _ = self.dataSource {
      titleTextField.textColor = self.dataSource.getTextColor()
      titleTextField.font = UIFont(name: self.dataSource.getFontName(), size: self.dataSource.getFontSize())
    }
  }

  override public func loadView() {
    super.loadView()

    picker.pickerType = .date
    picker.onlyDayPicker = true
    picker.datePickerType = .onlyDay
  }
}
