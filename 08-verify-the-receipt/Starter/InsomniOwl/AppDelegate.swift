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
import StoreKit
import SwiftKeychainWrapper

class AppDelegate: NSObject {
  var store: IAPStore!
}

extension AppDelegate: UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    SKPaymentQueue.default().add(self)
    return true
  }
}

extension AppDelegate: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased, .restored:
        completeTransaction(transaction)
      case .failed:
        failedTransaction(transaction)
      case .purchasing:
        print("purchase being processed")
      case .deferred:
        print("pending external action")
      default:
        print("unhandled transaction state")
      }
    }
  }

  private func completeTransaction(_ transaction: SKPaymentTransaction) {
    deliverPurchaseNotification(for: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func failedTransaction(_ transaction: SKPaymentTransaction) {
    if let transactionError = transaction.error as NSError?,
       let localizedDescription = transaction.error?.localizedDescription,
       transactionError.code != SKError.paymentCancelled.rawValue {
      print("transaction error: \(localizedDescription)")
    }
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func deliverPurchaseNotification(for identifier: String?) {
    guard let identifier = identifier else { return }
    if OwlProducts.isConsumable(productIdentifier: identifier) {
      store.addConsumable(productIdentifier: identifier, amount: 3)
    } else {
      store.addPurchase(purchaseIdentifier: identifier)
    }


  }

}
