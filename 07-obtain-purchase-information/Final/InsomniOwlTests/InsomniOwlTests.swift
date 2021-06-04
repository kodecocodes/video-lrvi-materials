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

import XCTest
import StoreKitTest
import SwiftKeychainWrapper
@testable import InsomniOwl

class InsomniOwlTests: XCTestCase {

  var products = [SKProduct]()

  override func setUpWithError() throws {
    if products.count > 0 {
      return
    }
    let session = try SKTestSession(configurationFileNamed: "Configuration")
    session.disableDialogs = true
    session.clearTransactions()
    let store = IAPStore(productsIDs: OwlProducts.productIDsNonConsumables)
    store.requestProducts()
    let loadProductsExpectation = expectation(description: "load products")
    let result = XCTWaiter.wait(for: [loadProductsExpectation], timeout: 1.0)
    if result == XCTWaiter.Result.timedOut {
      products = store.products
    }
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testIAPStore_buyProduct() {
    let product = products.first!
    KeychainWrapper.standard.removeAllKeys()
    XCTAssert(KeychainWrapper.standard.integer(forKey: product.productIdentifier) == nil)
    let store = IAPStore(productsIDs: OwlProducts.productIDsNonConsumables)
    store.buyProduct(product: product)

    let purchaseExpectation = expectation(description: "test after a second")
    let result = XCTWaiter.wait(for: [purchaseExpectation], timeout: 1.0)
    if result == XCTWaiter.Result.timedOut {
      let isOwned = KeychainWrapper.standard.bool(forKey: product.productIdentifier)
      XCTAssert(isOwned != nil && isOwned! == true)
    }

  }

}
