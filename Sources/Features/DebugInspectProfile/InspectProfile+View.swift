import FeaturePrelude
import Prelude
import Profile
import RadixConnectModels
import SwiftUI

// MARK: - ProfileView
public struct ProfileView: IndentedView {
	public let profile: Profile
	public let indentation: Indentation

	public init(
		profile: Profile,
		indentation: Indentation = .init()
	) {
		self.profile = profile
		self.indentation = indentation
	}
}

// MARK: - Indentation
public struct Indentation {
	public let indentationLevel: Int
	public let pointsToIndentPerLevel: CGFloat

	public init(
		indentationLevel: Int = 1,
		pointsToIndentPerLevel: CGFloat = 2
	) {
		self.indentationLevel = indentationLevel
		self.pointsToIndentPerLevel = pointsToIndentPerLevel
	}

	var inOneLevel: Self {
		.init(indentationLevel: indentationLevel + 1, pointsToIndentPerLevel: pointsToIndentPerLevel)
	}
}

extension Indentation {
	public var leadingPadding: CGFloat {
		CGFloat(indentationLevel) * pointsToIndentPerLevel
	}

	public var spacing: CGFloat {
		CGFloat(
			Double(128) / pow(2.0, Double(indentationLevel))
		)
	}
}

extension ProfileView {
	public var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: indentation.spacing) {
				HeaderView(
					header: profile.header,
					indentation: inOneLevel
				)

				PerNetworkView(
					networks: profile.networks,
					indentation: inOneLevel
				)

				AppPreferencesView(
					appPreferences: profile.appPreferences,
					indentation: inOneLevel
				)

				FactorSourcesView(
					factorSources: profile.factorSources,
					indentation: inOneLevel
				)
			}
		}
	}
}

// MARK: - IndentedView
public protocol IndentedView: SwiftUI.View {
	var indentation: Indentation { get }
}

extension IndentedView {
	public var inOneLevel: Indentation {
		indentation.inOneLevel
	}

	public var leadingPadding: CGFloat {
		indentation.leadingPadding
	}
}

// MARK: - HeaderView
public struct HeaderView: IndentedView {
	public let header: ProfileSnapshot.Header
	public let indentation: Indentation

	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("ID", value: header.id)
			Labeled("Snapshot version", value: header.snapshotVersion)
			CreatingDeviceView(device: header.creatingDevice, indentation: inOneLevel)
			HeaderHintView(hint: header.contentHint, indentation: inOneLevel)
		}
	}
}

// MARK: - CreatingDeviceView
public struct CreatingDeviceView: IndentedView {
	public let device: ProfileSnapshot.Header.UsedDeviceInfo
	public let indentation: Indentation

	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Device ID", value: device.id)
			Labeled("Creation date", value: device.date.ISO8601Format())
			Labeled("Device", value: device.description.rawValue)
		}
	}
}

// MARK: - HeaderHintView
public struct HeaderHintView: IndentedView {
	public let hint: ProfileSnapshot.Header.ContentHint
	public let indentation: Indentation

	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("#Networks", value: hint.numberOfNetworks)
			Labeled("#Accounts", value: hint.numberOfAccountsOnAllNetworksInTotal)
			Labeled("#Personas", value: hint.numberOfPersonasOnAllNetworksInTotal)
		}
	}
}

// MARK: - FactorSourcesView
public struct FactorSourcesView: IndentedView {
	public let factorSources: FactorSources
	public let indentation: Indentation
}

extension FactorSourcesView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Sources")
				.fontWeight(.heavy)
				.textCase(.uppercase)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			ForEach(factorSources) { factorSource in
				FactorSourceView(
					factorSource: factorSource,
					indentation: inOneLevel
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - FactorSourceView
public struct FactorSourceView: IndentedView {
	public let factorSource: FactorSource
	public let indentation: Indentation
}

extension FactorSourceView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Source")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			FactorSourceCommonView(common: factorSource.common)
			switch factorSource {
			case let .device(deviceFactorSource):
				DeviceFactorSouceView(deviceFactorSource: deviceFactorSource)
			case let .ledger(ledgerFactorSource):
				LedgerFactorSourceView(ledgerFactorSource: ledgerFactorSource)
			case let .offDeviceMnemonic(offDeviceMnemonicFactorSource):
				OffDeviceMnemonicFactorSourceView(offDeviceMnemonicFactorSource: offDeviceMnemonicFactorSource)
			}
		}
		.background {
			Color.randomDark(seed: factorSource.id.hexCodable.data)
		}
		.foregroundColor(.white)
		.padding([.leading], leadingPadding)
	}
}

// MARK: - FactorSourceCommonView
public struct FactorSourceCommonView: View {
	public let common: FactorSource.Common
	public var body: some View {
		Labeled("ID", value: common.id)
		Labeled("Added On", value: common.addedOn.ISO8601Format())
		Labeled("LastUsed On", value: common.lastUsedOn.ISO8601Format())
		Labeled("Supported Curves", value: common.cryptoParameters.supportedCurves.map { String(describing: $0) }.joined())
	}
}

// MARK: - DeviceFactorSouceView
public struct DeviceFactorSouceView: View {
	public let deviceFactorSource: DeviceFactorSource
	public var body: some View {
		Labeled("Name", value: deviceFactorSource.hint.name.rawValue)
		Labeled("Model", value: deviceFactorSource.hint.model.rawValue)

		if let nextDerivationIndicesPerNetwork = deviceFactorSource.nextDerivationIndicesPerNetwork {
			NextDerivationIndicesPerNetworkView(
				nextDerivationIndicesPerNetwork: nextDerivationIndicesPerNetwork,
				indentation: .init()
			)
		}
	}
}

// MARK: - LedgerFactorSourceView
public struct LedgerFactorSourceView: View {
	public let ledgerFactorSource: LedgerHardwareWalletFactorSource
	public var body: some View {
		Labeled("Name", value: ledgerFactorSource.hint.name.rawValue)
		Labeled("Model", value: ledgerFactorSource.hint.model.rawValue)
	}
}

// MARK: - OffDeviceMnemonicFactorSourceView
public struct OffDeviceMnemonicFactorSourceView: View {
	public let offDeviceMnemonicFactorSource: OffDeviceMnemonicFactorSource
	public var body: some View {
		Labeled("Word count", value: offDeviceMnemonicFactorSource.bip39Parameters.wordCount)
		Labeled("Language", value: offDeviceMnemonicFactorSource.bip39Parameters.language)
		Labeled("Passphrase?", value: offDeviceMnemonicFactorSource.bip39Parameters.bip39PassphraseSpecified)
		Labeled("Label", value: offDeviceMnemonicFactorSource.hint.label)
	}
}

// MARK: - NextDerivationIndicesPerNetworkView
public struct NextDerivationIndicesPerNetworkView: IndentedView {
	public let nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork
	public let indentation: Indentation

	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Next derivation indices per network")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			ForEach(nextDerivationIndicesPerNetwork.networks) { nextIndices in
				NextDerivationIndicesForNetworkView(nextIndices: nextIndices, indentation: indentation.inOneLevel)
			}
		}
	}
}

// MARK: - NextDerivationIndicesForNetworkView
public struct NextDerivationIndicesForNetworkView: IndentedView {
	public let nextIndices: Profile.Network.NextDerivationIndices
	public let indentation: Indentation
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("NetworkID", value: String(describing: nextIndices.networkID))
			Labeled("    Next index for account", value: String(describing: nextIndices.forAccount))
			Labeled("    Next index for persona", value: String(describing: nextIndices.forIdentity))
		}
	}
}

// MARK: - AppPreferencesView
public struct AppPreferencesView: IndentedView {
	public let appPreferences: AppPreferences
	public let indentation: Indentation
}

extension AppPreferencesView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("App Preferences")
				.fontWeight(.heavy)
				.textCase(.uppercase)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			DisplayView(
				display: appPreferences.display,
				indentation: inOneLevel
			)

			GatewaysView(
				gateways: appPreferences.gateways,
				indentation: inOneLevel
			)

			P2PLinksView(
				p2pLinks: appPreferences.p2pLinks,
				indentation: inOneLevel
			)

			AppSecurityView(
				security: appPreferences.security,
				indentation: inOneLevel
			)
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - GatewaysView
public struct GatewaysView: IndentedView {
	public let gateways: Gateways
	public let indentation: Indentation
}

extension GatewaysView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			ForEach(gateways.all) { gateway in
				GatewayView(
					gateway: gateway,
					isCurrent: self.gateways.current == gateway,
					indentation: inOneLevel
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - GatewayView
public struct GatewayView: IndentedView {
	public let gateway: Radix.Gateway
	public let isCurrent: Bool
	public let indentation: Indentation
}

extension GatewayView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network & Gateway")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("Network Name", value: gateway.network.name.rawValue)
			Labeled("Network ID", value: gateway.network.id.description)
			if isCurrent {
				Text("Is current gateway ✅")
			}
			Labeled("Gateway API Base URL", value: gateway.url.absoluteString)
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - DisplayView
public struct DisplayView: IndentedView {
	public let display: AppPreferences.Display
	public let indentation: Indentation
}

extension DisplayView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Display")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("Ledger Signing Display Mode", value: display.ledgerHQHardwareWalletSigningDisplayMode.rawValue)
			Labeled("Currency", value: display.fiatCurrencyPriceTarget.rawValue)
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - AppSecurityView
public struct AppSecurityView: IndentedView {
	public let security: AppPreferences.Security
	public let indentation: Indentation
}

extension AppSecurityView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("App Security")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("isCloudProfileSyncEnabled", value: String(describing: security.isCloudProfileSyncEnabled))
			Labeled("isDeveloperModeEnabled", value: String(describing: security.isDeveloperModeEnabled))
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - P2PLinksView
public struct P2PLinksView: IndentedView {
	public let p2pLinks: P2PLinks
	public let indentation: Indentation
}

extension P2PLinksView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("P2PLinks")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if p2pLinks.isEmpty {
				Text("<None yet>").font(.callout)
			} else {
				ForEach(p2pLinks) { p2pLinks in
					P2PLinkView(
						p2pLinks: p2pLinks,
						indentation: inOneLevel
					)
				}
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - AuthorizedDappsView
public struct AuthorizedDappsView: IndentedView {
	public let authorizedDapps: Profile.Network.AuthorizedDapps
	public let indentation: Indentation
	public let getDetailedAuthorizedDapp: (Profile.Network.AuthorizedDapp) -> Profile.Network.AuthorizedDappDetailed
}

extension AuthorizedDappsView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Authorized Dapps")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if authorizedDapps.isEmpty {
				Text("<None yet>").font(.callout)
			} else {
				ForEach(authorizedDapps) { authorizedDapp in
					AuthorizedDappView(
						authorizedDapp: authorizedDapp,
						indentation: inOneLevel,
						authorizedPersonas: getDetailedAuthorizedDapp(authorizedDapp).detailedAuthorizedPersonas
					)
				}
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - AuthorizedDappView
public struct AuthorizedDappView: IndentedView {
	public let authorizedDapp: Profile.Network.AuthorizedDapp
	public let indentation: Indentation
	public let authorizedPersonas: IdentifiedArrayOf<Profile.Network.AuthorizedPersonaDetailed>
}

extension AuthorizedDappView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Name", value: String(describing: authorizedDapp.displayName))
			Labeled("Dapp def address", value: String(describing: authorizedDapp.dAppDefinitionAddress))
			ForEach(authorizedPersonas) {
				DappAuthorizedPersonaView(
					detailedAuthorizedPersona: $0,
					indentation: inOneLevel
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - DappAuthorizedPersonaView
public struct DappAuthorizedPersonaView: IndentedView {
	public let detailedAuthorizedPersona: Profile.Network.AuthorizedPersonaDetailed
	public let indentation: Indentation
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Address", value: detailedAuthorizedPersona.identityAddress.address)
			Labeled("Name", value: detailedAuthorizedPersona.displayName.rawValue)

			Text("Shared Fields")
			if let sharedFields = detailedAuthorizedPersona.sharedFields {
				if !sharedFields.isEmpty {
					ForEach(sharedFields) { field in
						VStack {
							Labeled("id", value: field.id.description)
							Labeled("value", value: field.value.rawValue)
						}
					}
				} else {
					Text("None yet")
				}
			} else {
				Text("Never requested")
			}

			Text("Shared Accounts")
			if let simpleAccounts = detailedAuthorizedPersona.simpleAccounts {
				if !simpleAccounts.isEmpty {
					ForEach(simpleAccounts) { simpleAccount in
						Labeled("displayName", value: simpleAccount.label.rawValue)
						Labeled("address", value: simpleAccount.address.address)
						Labeled("appearanceID", value: simpleAccount.appearanceID.description)
					}
				} else {
					Text("None yet")
				}
			} else {
				Text("Never requested")
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - P2PLinkView
public struct P2PLinkView: IndentedView {
	public let p2pLinks: P2PLink
	public let indentation: Indentation
}

extension P2PLinkView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("P2P Client")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("ID", value: String(p2pLinks.id.data.hex().mask(showLast: 6)))
			Labeled("Client Name", value: p2pLinks.displayName)
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - PerNetworkView
public struct PerNetworkView: IndentedView {
	public let networks: Profile.Networks
	public let indentation: Indentation
}

extension PerNetworkView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Per Network")
				.fontWeight(.heavy)
				.textCase(.uppercase)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			ForEach(networks.keys, id: \.self) { networkID in
				ProfileNetworkView(
					network: try! networks.network(id: networkID),
					indentation: inOneLevel
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - ProfileNetworkView
public struct ProfileNetworkView: IndentedView {
	public let network: Profile.Network
	public let indentation: Indentation
}

extension ProfileNetworkView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("ID", value: String(describing: network.networkID))

			AccountsView(
				entities: network.accounts.rawValue.elements,
				indentation: inOneLevel
			)

			PersonasView(
				entities: network.personas.elements,
				indentation: inOneLevel
			)

			AuthorizedDappsView(
				authorizedDapps: network.authorizedDapps,
				indentation: inOneLevel
			) {
				try! network.detailsForAuthorizedDapp($0)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

public typealias AccountsView = EntitiesView<Profile.Network.Account>
public typealias PersonasView = EntitiesView<Profile.Network.Persona>

// MARK: - EntitiesView
public struct EntitiesView<Entity: EntityProtocol>: IndentedView {
	public let entities: [Entity]
	public let indentation: Indentation
}

extension EntitiesView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text(Entity.entityKind == .identity ? "Personas" : "Accounts")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if entities.isEmpty {
				Text("<None yet>")
			} else {
				ForEach(entities, id: \.address) { entity in
					EntityView(
						entity: entity,
						indentation: inOneLevel
					)
				}
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - EntityView
public struct EntityView<Entity: EntityProtocol>: IndentedView {
	public let entity: Entity
	public let indentation: Indentation
}

extension EntityView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("DisplayName", value: entity.displayName.rawValue)

			Labeled("Address", value: entity.address.address)
			switch entity.securityState {
			case let .unsecured(unsecuredControl):
				UnsecuredEntityControlView(
					unsecuredControl: unsecuredControl,
					indentation: inOneLevel
				)
			}

			if let persona = self.entity as? Profile.Network.Persona {
				Group {
					Text("Persona fields")
					ForEach(persona.fields) { field in
						Labeled(field.id.rawValue, value: field.value.rawValue)
					}
				}.padding([.leading], indentation.inOneLevel.leadingPadding)
			}
			if let account = self.entity as? Profile.Network.Account {
				Labeled("Account Appearance ID", value: account.appearanceID.description)
			}
		}
		.foregroundColor(entity.kind == .account ? .white : .black)
		.padding([.leading], leadingPadding)
		.background {
			if let account = entity as? Profile.Network.Account {
				account.appearanceID.gradient
					.brightness(-0.2)
			}
		}
	}
}

// MARK: - UnsecuredEntityControlView
public struct UnsecuredEntityControlView: IndentedView {
	public let unsecuredControl: UnsecuredEntityControl
	public let indentation: Indentation
}

extension UnsecuredEntityControlView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			HierarchicalDeterministicFactorInstanceView(
				description: "Transaction Signing",
				factorInstance: unsecuredControl.transactionSigning,
				indentation: inOneLevel
			)
			if let authenticationSigning = unsecuredControl.authenticationSigning {
				HierarchicalDeterministicFactorInstanceView(
					description: "Auth Signing",
					factorInstance: authenticationSigning,
					indentation: inOneLevel
				)
			}
		}
	}
}

// MARK: - HierarchicalDeterministicFactorInstanceView
public struct HierarchicalDeterministicFactorInstanceView: IndentedView {
	public let description: String
	public let factorInstance: HierarchicalDeterministicFactorInstance
	public let indentation: Indentation
}

extension HierarchicalDeterministicFactorInstanceView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("\(description) factor instance")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("Derivation Path", value: factorInstance.derivationPath.description)
			Labeled("Derivation Scheme", value: factorInstance.derivationPath.scheme.rawValue)
			Labeled("Public Key", value: factorInstance.publicKey.compressedRepresentation.hex)
			Labeled("Curve", value: factorInstance.publicKey.curve.rawValue)
			Labeled("Factor Source ID", value: String(factorInstance.factorSourceID.hexCodable.hex().mask(showLast: 6)))
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - Labeled
public struct Labeled: SwiftUI.View {
	let label: String
	let value: String
	public init(_ label: String, value: String) {
		self.label = label
		self.value = value
	}

	public init<Value>(_ label: String, value: Value) where Value: CustomStringConvertible {
		self.init(label, value: String(describing: value))
	}

	public var body: some View {
		HStack(alignment: .top) {
			Text(label)
				.fontWeight(.light)
				.textSelection(.enabled)
			Text(value)
				.fontWeight(.bold)
				.textSelection(.enabled)
		}
	}
}
