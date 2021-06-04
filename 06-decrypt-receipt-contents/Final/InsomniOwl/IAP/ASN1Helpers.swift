///// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import OpenSSL

func readASN1Data(ptr: UnsafePointer<UInt8>, length: Int) -> Data {
  Data(bytes: ptr, count: length)
}

func readASN1Integer(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Int? {
  var type: Int32 = 0
  var xclass: Int32 = 0
  var length: Int = 0
  let intPtr = ptr
  ASN1_get_object(&ptr, &length, &type, &xclass, maxLength)
  guard type == V_ASN1_INTEGER else {
    return nil
  }
  ptr = intPtr
  let integerObject = d2i_ASN1_UINTEGER(nil, &ptr, maxLength)
  let intValue = ASN1_INTEGER_get(integerObject)
  ASN1_INTEGER_free(integerObject)
  return intValue
}

func readASN1String(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> String? {
  var xclass: Int32 = 0
  var length = 0
  var type: Int32 = 0
  var strPointer = ptr
  ASN1_get_object(&strPointer, &length, &type, &xclass, maxLength)
  if type ==  V_ASN1_UTF8STRING {
    let p = UnsafeMutableRawPointer(mutating: strPointer!)
    return String(bytesNoCopy: p, length: length, encoding: .utf8, freeWhenDone: false)
  }
  if type == V_ASN1_IA5STRING {
    let p = UnsafeMutablePointer(mutating: strPointer!)
    return String(bytesNoCopy: p, length: length, encoding: .ascii, freeWhenDone: false)
  }
  return nil
}

func readASN1Date(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Date? {
  var type: Int32 = 0
  var xclass: Int32 = 0
  var length = 0
  var datePointer = ptr
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy-'-'MM'-'dd'T'HH':'mm':'ss'Z'"
  formatter.timeZone = TimeZone(abbreviation: "GMT")
  ASN1_get_object(&datePointer, &length, &type, &xclass, maxLength)
  guard type == V_ASN1_IA5STRING else {
    return nil
  }
  let p = UnsafeMutablePointer(mutating: datePointer!)
  if let dateString = String(bytesNoCopy: p, length: length, encoding: .ascii, freeWhenDone: false) {
    return formatter.date(from: dateString)
  }
  return nil
}
