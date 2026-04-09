import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    private static let productID = "com.parktimer.pro"

    var isProUnlocked = false
    var product: Product?
    var purchaseError: String?

    private init() {}

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    /// Check Apple's transaction ledger for a valid Pro entitlement.
    /// Called on every app launch — source of truth, not UserDefaults.
    func checkEntitlements() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "store.proUnlocked") {
            isProUnlocked = true
            return
        }
        #endif
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                isProUnlocked = true
                return
            }
        }
        isProUnlocked = false
    }

    func purchase() async {
        guard let product else {
            purchaseError = "Product not available"
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    isProUnlocked = true
                    purchaseError = nil
                case .unverified:
                    purchaseError = "Purchase could not be verified"
                }
            case .pending:
                purchaseError = "Purchase is pending"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
    }
}
