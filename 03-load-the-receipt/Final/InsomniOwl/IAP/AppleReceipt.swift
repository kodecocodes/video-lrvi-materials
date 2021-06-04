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

enum ReceiptStatus: String {
  case validationSuccess = "This receipt is valid."
  case noReceiptPresent = "A receipt was not found on this device."
  case unknownFailure = "An unexpected failure occurred during verification."
  case unknownReceiptFormat = "The receipt is not in PKCS7 format."
  case invalidPKCS7Signature = "Invalid PKCS7 Signature."
  case invalidPKCS7Type = "Invalid PKCS7 Type."
  case invalidAppleRootCertificate = "Public Apple root certificate not found."
  case failedAppleSignature = "Receipt not signed by Apple."
  case unexpectedASN1Type = "Unexpected ASN1 Type."
  case missingComponent = "Expected component was not found."
  case invalidBundleIdentifier = "Receipt bundle identifier does not match application bundle identifier."
  case invalidVersionIdentifier = "Receipt version identifier does not match application version."
  case invalidHash = "Receipt failed hash check."
  case invalidExpired = "Receipt has expired."
}

class AppleReceipt {

  var receiptStatus: ReceiptStatus?

  init() {
    guard let payload = loadReceipt() else {
      return
    }
  }

  private func loadReceipt() -> UnsafeMutablePointer<PKCS7>? {
    guard let receiptUrl = Bundle.main.appStoreReceiptURL,
          let receiptData = try? Data(contentsOf: receiptUrl) else {
      receiptStatus = .noReceiptPresent
      return nil
    }
    let receiptBIO = BIO_new(BIO_s_mem())
    let receiptBytes: [UInt8] = .init(receiptData)
    BIO_write(receiptBIO, receiptBytes, Int32(receiptData.count))
    let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
    BIO_free(receiptBIO)
    guard receiptPKCS7 != nil else {
      receiptStatus = .unknownReceiptFormat
      return nil
    }
    guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
      receiptStatus = .invalidPKCS7Signature
      return nil
    }
    let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
    guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
      receiptStatus = .invalidPKCS7Type
      return nil
    }
    return receiptPKCS7
  }

}
