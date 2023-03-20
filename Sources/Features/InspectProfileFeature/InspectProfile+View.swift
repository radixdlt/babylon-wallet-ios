import Prelude
import Profile
import RadixConnectModels
import SecureStorageClient
import SwiftUI

// MARK: - ProfileView
public struct ProfileView: IndentedView {
	public let profile: Profile
	public let indentation: Indentation
	public var secureStorageClient: SecureStorageClient?

	public init(
		profile: Profile,
		indentation: Indentation = .init(),
		secureStorageClient: SecureStorageClient? = nil
	) {
		self.profile = profile
		self.indentation = indentation
		self.secureStorageClient = secureStorageClient
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
				Labeled("Version", value: String(describing: profile.version))

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
					indentation: inOneLevel,
					secureStorageClient: secureStorageClient
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

// MARK: - FactorSourcesView
public struct FactorSourcesView: IndentedView {
	public let factorSources: FactorSources
	public let indentation: Indentation
	public var secureStorageClient: SecureStorageClient?
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
					indentation: inOneLevel,
					secureStorageClient: secureStorageClient
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
	public var secureStorageClient: SecureStorageClient?
	@State private var mnemonicPhraseLoadedFromKeychain: String?
	@State private var mnemonicPassphraseLoadedFromKeychain: String?
}

extension FactorSourceView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Source")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("Kind", value: factorSource.kind.rawValue)
			Labeled("Hint", value: factorSource.hint.rawValue)
			Labeled("Added on", value: factorSource.addedOn.ISO8601Format())
			Labeled("ID", value: String(factorSource.id.hexCodable.hex().mask(showLast: 6)))

			if let mnemonicPhraseLoadedFromKeychain {
				VStack {
					Text("✅ Mnemonic found in keychain ✅")
					Text(mnemonicPhraseLoadedFromKeychain).fontWeight(.semibold)
					if let mnemonicPassphraseLoadedFromKeychain {
						Spacer()
						Text("Bip39 Passphrase:")
						Text("'\(mnemonicPassphraseLoadedFromKeychain)'")
					}
				}
				.padding()
				.border(Color.green, width: 2)
			}

			if let deviceStore = factorSource.storage?.forDevice {
				NextDerivationIndicesPerNetworkView(nextDerivationIndicesPerNetwork: deviceStore.nextDerivationIndicesPerNetwork, indentation: indentation.inOneLevel)
			}
		}
		.padding([.leading], leadingPadding)
		.task {
			#if DEBUG
			if let mnemonic = try? await secureStorageClient?.loadMnemonicByFactorSourceID(factorSource.id, .debugOnlyInspect) {
				self.mnemonicPhraseLoadedFromKeychain = mnemonic.mnemonic.phrase
				self.mnemonicPassphraseLoadedFromKeychain = mnemonic.passphrase
			}
			#endif
		}
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
			Labeled("iCloudProfileSyncEnabled", value: String(describing: security.iCloudProfileSyncEnabled))
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

			Text("Fields")
			ForEach(detailedAuthorizedPersona.fields) { field in
				VStack {
					Labeled("id", value: field.id.description)
					Labeled("kind", value: field.kind.rawValue)
					Labeled("value", value: field.value.rawValue)
				}
			}

			Text("Shared Accounts")
			if let simpleAccounts = detailedAuthorizedPersona.simpleAccounts {
				ForEach(simpleAccounts) { simpleAccount in
					Labeled("displayName", value: simpleAccount.label.rawValue)
					Labeled("address", value: simpleAccount.address.address)
					Labeled("appearanceID", value: simpleAccount.appearanceID.description)
				}
			} else {
				Text("None yet")
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
			if let displayName = entity.displayName {
				Labeled("DisplayName", value: displayName.rawValue)
			}

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
						Labeled(field.kind.rawValue, value: field.value.rawValue)
					}
				}.padding([.leading], indentation.inOneLevel.leadingPadding)
			}
			if let account = self.entity as? Profile.Network.Account {
				Labeled("Account Appearance ID", value: account.appearanceID.description)
			}
		}
		.padding([.leading], leadingPadding)
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
			Text("Genesis factor instance")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			FactorInstanceView(
				factorInstance: unsecuredControl.genesisFactorInstance,
				indentation: inOneLevel
			)
		}
	}
}

// MARK: - FactorInstanceView
public struct FactorInstanceView: IndentedView {
	public let factorInstance: FactorInstance
	public let indentation: Indentation
}

extension FactorInstanceView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Instance")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

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

	public var body: some View {
		HStack(alignment: .top) {
			Text(label)
				.fontWeight(.light)
			Text(value)
				.fontWeight(.bold)
		}
	}
}
