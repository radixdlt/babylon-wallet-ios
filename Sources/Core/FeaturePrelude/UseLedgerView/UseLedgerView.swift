import Prelude
import Resources
import SharedModels
import SwiftUI

public struct UseLedgerView: SwiftUI.View {
	public enum Purpose: Sendable, Hashable {
		case createAccount
		case createAuthSigningKey
		case importLegacyAccounts
		case signAuth
		case signTX
	}

	public let purpose: Purpose
	public let id: String
	public let name: String
	public let model: String
	public let lastUsedOn: Date
	public let addedOn: Date

	init(
		purpose: Purpose,
		id: String,
		name: String,
		model: String,
		lastUsedOn: Date,
		addedOn: Date
	) {
		self.purpose = purpose
		self.id = id
		self.name = name
		self.model = model
		self.lastUsedOn = lastUsedOn
		self.addedOn = addedOn
	}

	public init(
		ledgerFactorSource ledger: LedgerHardwareWalletFactorSource,
		purpose: Purpose
	) {
		self.init(
			purpose: purpose,
			id: ledger.id.hex(),
			name: ledger.name ?? "Unnamned",
			model: ledger.model.rawValue,
			lastUsedOn: ledger.lastUsedOn,
			addedOn: ledger.addedOn
		)
	}

	var title: String {
		switch purpose {
		case .createAccount:
			return "Creating account"
		case .createAuthSigningKey:
			return "Creating auth key"
		case .signAuth:
			return "Sign auth challenge"
		case .signTX:
			return "Sign transaction"
		case .importLegacyAccounts:
			return "Import Legacy Accounts"
		}
	}

	public var body: some View {
		VStack {
			Text(title).textStyle(.body1HighImportance)
			let display = "\(model) - \(name)"
			VPair(heading: "Ledger", item: display)
			VPair(heading: "Last used", item: lastUsedOn.ISO8601Format())
			VPair(heading: "Added on", item: addedOn.ISO8601Format())
		}
		.padding()
	}
}
