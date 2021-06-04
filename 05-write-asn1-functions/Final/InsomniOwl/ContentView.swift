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

import SwiftUI
import StoreKit

struct ContentView: View {

  @EnvironmentObject var store: IAPStore

  var body: some View {
    NavigationView {
      List {
        ForEach(store.products, id: \.self) { product in
          ZStack {
            ProductRow(product: product)
            if !OwlProducts.isConsumable(productIdentifier: product.productIdentifier) {
              NavigationLink(destination: OwlDLCView(product: product)) {
                EmptyView()
              }
              .frame(width: 0)
              .opacity(0)
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("Insomni Owl")
      .navigationBarItems(trailing: Button("Restore") {
        store.restorePurchases()
      })
      .onAppear {
        store.requestProducts()
      }
    }
  }

  init()  {
    UINavigationBar.appearance().setBackgroundImage(UIImage(named: "Background-StaryNight"), for: UIBarMetrics.default)
    UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    UINavigationBar.appearance().tintColor = .white
  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(IAPStore(productsIDs: OwlProducts.productIDsNonConsumables.union(OwlProducts.productIDsConsumables)))
  }
}

struct ProductRow: View {

  @EnvironmentObject var store: IAPStore
  @State var isPresented = false

  let product: SKProduct
  let price: String

  init(product: SKProduct) {
    self.product = product
    let formatter = NumberFormatter()
    formatter.locale = product.priceLocale
    formatter.numberStyle = .currency
    price = formatter.string(from: product.price) ?? ""
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: nil) {
        Text("\(product.localizedTitle) - \(price)")
        Text(product.localizedDescription)
      }
      Spacer()
      if OwlProducts.isConsumable(productIdentifier: product.productIdentifier) {
        if store.consumableAmountFor(productIdentifier: product.productIdentifier) > 0 {
          Button {
            isPresented = true
          } label: {
            Image(systemName: "\(store.consumableAmountFor(productIdentifier: product.productIdentifier)).circle")
              .font(Font.system(.largeTitle))
          }
        } else {
          PurchaseButton(product: product)
        }
      } else {
        if store.isPurchased(product.productIdentifier) {
          OwnedView()
        } else {
          PurchaseButton(product: product)
        }
      }
    }
    .padding()
    .alert(isPresented: $isPresented) { () -> Alert in
      let purchaseOwl = Alert.Button.default(Text("Yes")) {
        let randomOwl = OwlProducts.fetchRandomUnownedProduct(ownedProducts: store.purchasedProducts)
        store.decrementConsumable(productIdentifier: product.productIdentifier)
        store.addPurchase(purchaseIdentifier: randomOwl)
      }
      return Alert(title: Text("Unlock Random Owl?"), message: Text("Do you wish to unlock a random owl?"), primaryButton: purchaseOwl, secondaryButton: .cancel(Text("No")))
    }
  }
}

struct OwnedView: View {

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    Image(systemName: "checkmark")
      .padding(10)
      .foregroundColor(colorScheme == .light ? .black : .white)
      .overlay(
        Circle()
          .stroke(colorScheme == .light ? Color.black : Color.white, lineWidth: 2)
      )
  }

}

struct PurchaseButton: View {

  @EnvironmentObject var store: IAPStore
  let product: SKProduct

  var body: some View {
    HStack {
      Image(systemName: "cart")
      Text("Buy")
    }
    .onTapGesture {
      store.buyProduct(product: product)
    }
    .padding(10)
    .foregroundColor(.yellow)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.yellow, lineWidth: 2)
    )

  }

}


