import Foundation
import Profile

// MARK: - AccountRow
/// Namespace for AccountRowFeature
public extension Home {
	enum AccountRow {}
}

public extension Home.AccountRow {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let address: String
		public let name: String?
		public let tokens: [Token]

		public init(
			address: String,
			name: String?,
			tokens: [Token]
		) {
			self.address = address
			self.name = name
			self.tokens = tokens
		}
	}
}

public extension Home.AccountRow.State {
	typealias ID = Profile.Account.Address

	var id: Profile.Account.Address {
		address
	}
}

public extension Home.AccountRow.State {
	init(profileAccount: Profile.Account) {
		self.init(
			address: profileAccount.address,
			name: profileAccount.name,
			tokens: []
		)
	}
}

#if DEBUG
public extension Home.AccountRow.State {
	static let placeholder: Self = .init(profileAccount: .init(address: .init()))
}
#endif

/*
 import Foundation
 import Profile

 // MARK: - Account
 public extension Home.AccountList {
     struct Account: Equatable {
         public let address: String
         public let name: String?
         public let tokens: [Token]

         public init(
             address: String,
             name: String?,
             tokens: [Token]
         ) {
             self.address = address
             self.name = name
             self.tokens = tokens
         }
     }
 }

 // FIXME: fiatTotalValueString
 /*
  public extension Account {
      var fiatTotalValueString: String {
          fiatTotalValue
              .formatted(
                  .currency(code: currency.code)
              )
      }
  }
  */

 #if DEBUG
 public extension Home.AccountList.Account {
     static let placeholder: Self = .checking

     static let checking: Self = .init(
         address: UUID().uuidString,
         name: "Checking",
         tokens: []
     )

     static let savings: Self = .init(
         address: UUID().uuidString,
         name: "Savings",
         tokens: []
     )

     static let shared: Self = .init(
         address: UUID().uuidString,
         name: "Shared",
         tokens: []
     )
 }
 #endif
 */
