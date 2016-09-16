//
//  ValidatedForm.swift
//  application
//
//  Created by Nicolas LELOUP on 09/09/2015.
//  Copyright (c) 2015 Nicolas LELOUP - Buzznative. All rights reserved.
//

import Foundation

// MARK: Class
/// Form class able to validates its fields
public class ValidatedForm: Form {
  
  // MARK: Public own methods
  
  /**
   Checks if all fields are valid
   
   - Return: validation result
   */
  public func validate() -> Bool {
    for input in inputs {
      if (!input.validateFormat()) {
        return false
      }
    }
    
    return true
  }
}
