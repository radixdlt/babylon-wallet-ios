import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var header: Home.Header.State

		public init(
			header: Home.Header.State = .init()
		) {
			self.header = header
		}
	}
}

/*
 public extension Home {
 	struct Account: Equatable {
 		var userGeneratedName: String
 		var systemGeneratedName: String
 		var accountFiatTotalValue: Float
 		var accountCurrency: Currency
 	}
 }
 */

/*
 public extension Home {
 	enum Currency: Equatable {
 		case usd

 		var symbol: String {
 			switch self {
 			case .usd:
 				return "$"
 			}
 		}
 	}
 }
 */
