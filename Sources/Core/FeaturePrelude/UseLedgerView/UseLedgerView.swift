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
		ledgerFactorSource ledger: LedgerFactorSource,
		purpose: Purpose
	) {
		self.init(
			purpose: purpose,
			id: ledger.id.hex(),
			name: ledger.name,
			model: ledger.model.rawValue,
			lastUsedOn: ledger.lastUsedOn,
			addedOn: ledger.addedOn
		)
	}

	var title: String {
		switch purpose {
		case .createAccount:
			return L10n.Signing.UseLedgerPurpose.createAccount
		case .createAuthSigningKey:
			return L10n.Signing.UseLedgerPurpose.createAuthSigningKey
		case .signAuth:
			return L10n.Signing.UseLedgerPurpose.signAuth
		case .signTX:
			return L10n.Signing.UseLedgerPurpose.signTX
		case .importLegacyAccounts:
			return L10n.Signing.UseLedgerPurpose.importLegacyAccounts
		}
	}

	public var body: some View {
		VStack {
			Text(title).textStyle(.body1HighImportance)
			let display = "\(model) - \(name)"
			VPair(heading: L10n.Signing.UseLedgerLabel.ledger, item: display)
			VPair(heading: L10n.Signing.UseLedgerLabel.lastUsed, item: lastUsedOn.ISO8601Format())
			VPair(heading: L10n.Signing.UseLedgerLabel.addedOn, item: addedOn.ISO8601Format())
		}
		.padding()
	}
}
