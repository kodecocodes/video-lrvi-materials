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

struct PurchaseDetails {
  var quantity: Int?
  var productIdentifier: String?
  var transactionIdentifier: String?
  var originalTransactionIdentifier: String?
  var purchaseDate: Date?
  var originalPurchaseDate: Date?
  var subscriptionExpirationDate: Date?
  var subscriptionIntroductoryPricePeriod: Int?
  var subscriptionCancellationDate: Date?
  var webOrderLineId: Int?

  init?(with pointer: inout UnsafePointer<UInt8>?, payloadLength: Int) {
    let endPointer = pointer!.advanced(by: payloadLength)
    var type: Int32 = 0
    var xclass: Int32 = 0
    var length = 0
    ASN1_get_object(&pointer, &length, &type, &xclass, payloadLength)
    guard type == V_ASN1_SET else {
      return nil
    }
    while pointer! < endPointer {
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_SEQUENCE else {
        return nil
      }
      guard let attributeType = readASN1Integer(ptr: &pointer, maxLength: pointer!.distance(to: endPointer)) else {
        return nil
      }
      guard let _ = readASN1Integer(ptr: &pointer, maxLength: pointer!.distance(to: endPointer)) else {
        return nil
      }
      ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: endPointer))
      guard type == V_ASN1_OCTET_STRING else {
        return nil
      }
      switch attributeType {
      case 1701: // quantity
        var p = pointer
        quantity = readASN1Integer(ptr: &p, maxLength: length)
      case 1702: // product identifier
        var p = pointer
        productIdentifier = readASN1String(ptr: &p, maxLength: length)
      case 1703: // transaction identifier
        var p = pointer
        transactionIdentifier = readASN1String(ptr: &p, maxLength: length)
      case 1704: // purchase data
        var p = pointer
        purchaseDate = readASN1Date(ptr: &p, maxLength: length)
      case 1705: // original transaction identifier
        var p = pointer
        originalTransactionIdentifier = readASN1String(ptr: &p, maxLength: length)
      case 1706: // original purchase date
        var p = pointer
        originalPurchaseDate = readASN1Date(ptr: &p, maxLength: length)
      case 1708: // subscription expiration date
        var p = pointer
        subscriptionExpirationDate = readASN1Date(ptr: &p, maxLength: length)
      case 1711: // web order id
        var p = pointer
        webOrderLineId = readASN1Integer(ptr: &p, maxLength: length)
      case 1712: // subscription cancellation date
        var p = pointer
        subscriptionCancellationDate = readASN1Date(ptr: &p, maxLength: length)
      default:
        break
      }
      pointer = pointer!.advanced(by: length)
    }
  }
}
