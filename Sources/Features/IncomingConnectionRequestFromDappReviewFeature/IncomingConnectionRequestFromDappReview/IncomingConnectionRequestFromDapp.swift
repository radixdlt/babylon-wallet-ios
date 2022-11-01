import Common
import Foundation

// MARK: - IncomingConnectionRequestFromDapp
public struct IncomingConnectionRequestFromDapp: Equatable, Decodable {
	let componentAddress: ComponentAddress
	let name: String?
	let permissions: [IncomingConnectionRequestFromDapp.Permission]
	let numberOfNeededAccounts: NumberOfNeededAccounts

	public init(
		componentAddress: ComponentAddress,
		name: String?,
		permissions: [IncomingConnectionRequestFromDapp.Permission],
		numberOfNeededAccounts: NumberOfNeededAccounts
	) {
		self.componentAddress = componentAddress
		self.name = name
		self.permissions = permissions
		self.numberOfNeededAccounts = numberOfNeededAccounts
	}
}

// MARK: - Convenience
public extension IncomingConnectionRequestFromDapp {
	init(
		request: RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest
	) {
		let numberOfNeededAccounts: NumberOfNeededAccounts
		if let numberOfAddresses = request.numberOfAddresses {
			numberOfNeededAccounts = .exactly(numberOfAddresses)
		} else {
			numberOfNeededAccounts = .atLeastOne
		}

		// TODO: replace hardcoded values with real values
		self.init(
			componentAddress: "deadbeef",
			name: "dApp name",
			permissions: [],
			numberOfNeededAccounts: numberOfNeededAccounts
		)
	}
}

// MARK: IncomingConnectionRequestFromDapp.NumberOfNeededAccounts
public extension IncomingConnectionRequestFromDapp {
	enum NumberOfNeededAccounts: Decodable, Equatable {
		case atLeastOne
		case exactly(Int)
	}
}

// MARK: - Computed Propertie
public extension IncomingConnectionRequestFromDapp {
	var displayName: String {
		name ?? L10n.DApp.unknownName
	}
}

#if DEBUG
public extension IncomingConnectionRequestFromDapp {
	static let placeholder: Self = .init(
		componentAddress: "deadbeef",
		name: "Radaswap",
		permissions: [
			.placeholder1,
			.placeholder2,
//			.placeholder3,
		],
		numberOfNeededAccounts: .exactly(1)
	)
}
#endif
