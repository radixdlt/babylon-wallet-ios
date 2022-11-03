import BrowserExtensionsConnectivityClient
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
		addressRequest: RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest,
		from fullRequest: RequestMethodWalletRequest
	) {
		// TODO: replace hardcoded values with real values
		self.init(
			componentAddress: "unknown for E2E", // FIXME: read out from `metadata` once it contains it
			name: fullRequest.metadata.dAppId.map { "'\($0)'" } ?? "<Unknown>",
			permissions: [], // FIXME: update for personas info, post E2E, this init cannot be used then, will need to pass `payloads` array in full...
			numberOfNeededAccounts: .init(int: addressRequest.numberOfAddresses)
		)
	}
}

public extension IncomingConnectionRequestFromDapp.NumberOfNeededAccounts {
	init(int: Int?) {
		self = int.map {
			$0 == 0 ? .atLeastOne : .exactly($0)
		} ?? .atLeastOne
	}
}

// MARK: - IncomingConnectionRequestFromDapp.NumberOfNeededAccounts
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
