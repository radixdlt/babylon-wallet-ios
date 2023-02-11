import P2PModels
import Prelude
import Profile
import SwiftUI

// MARK: - ProfileView
public struct ProfileView: IndentedView {
	public let profile: Profile
	public let indentation: Indentation
	public var keychainClient: KeychainClient?

	public init(
		profile: Profile,
		indentation: Indentation = .init(),
		keychainClient: KeychainClient? = nil
	) {
		self.profile = profile
		self.indentation = indentation
		self.keychainClient = keychainClient
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
					perNetwork: profile.perNetwork,
					indentation: inOneLevel
				)

				AppPreferencesView(
					appPreferences: profile.appPreferences,
					indentation: inOneLevel
				)

				FactorSourcesView(
					factorSources: profile.factorSources,
					indentation: inOneLevel,
					keychainClient: keychainClient
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
	public var keychainClient: KeychainClient?
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

			ForEach(factorSources.anyFactorSources, id: \.factorSourceID) { factorSource in
				FactorSourceView(
					factorSource: factorSource,
					indentation: inOneLevel,
					keychainClient: keychainClient
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - FactorSourceView
public struct FactorSourceView: IndentedView {
	public let factorSource: any FactorSourceProtocol
	public let indentation: Indentation
	public var keychainClient: KeychainClient?
	@State private var mnemonicPhraseLoadedFromKeychain: String?
}

extension FactorSourceView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Source")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			if let mnemonicPhraseLoadedFromKeychain {
				VStack {
					Text("✅ Mnemonic found in keychain ✅")
					Text(mnemonicPhraseLoadedFromKeychain).fontWeight(.semibold)
				}
				.padding()
				.border(Color.green, width: 2)
			}

			Labeled("ID", value: String(factorSource.factorSourceID.id.mask(showLast: 6)))
			Labeled("Kind", value: factorSource.factorSourceKind.rawValue)
			Labeled("Created", value: factorSource.creationDate.ISO8601Format())
		}
		.padding([.leading], leadingPadding)
		.task {
			Task {
				if let mnemonic = try? await keychainClient?.loadFactorSourceMnemonic(
					reference: self.factorSource.reference,
					authenticationPrompt: "Load Mnemonic to display for debugging"
				) {
					self.mnemonicPhraseLoadedFromKeychain = mnemonic.phrase
				}
			}
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

			NetworkAndGatewayView(
				networkAndGateway: appPreferences.networkAndGateway,
				indentation: inOneLevel
			)

			P2PClientsView(
				p2pClients: appPreferences.p2pClients,
				indentation: inOneLevel
			)
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - NetworkAndGatewayView
public struct NetworkAndGatewayView: IndentedView {
	public let networkAndGateway: AppPreferences.NetworkAndGateway
	public let indentation: Indentation
}

extension NetworkAndGatewayView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network & Gateway")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("Network Name", value: networkAndGateway.network.name.rawValue)
			Labeled("Network ID", value: networkAndGateway.network.id.description)
			Labeled("Gateway API Base URL", value: networkAndGateway.gatewayAPIEndpointURL.absoluteString)
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

// MARK: - P2PClientsView
public struct P2PClientsView: IndentedView {
	public let p2pClients: P2PClients
	public let indentation: Indentation
}

extension P2PClientsView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("P2PClients")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if p2pClients.isEmpty {
				Text("<None yet>").font(.callout)
			} else {
				ForEach(p2pClients) { p2pClient in
					P2PClientView(
						p2pClient: p2pClient,
						indentation: inOneLevel
					)
				}
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - ConnectedDappsView
public struct ConnectedDappsView: IndentedView {
	public let connectedDapps: [OnNetwork.ConnectedDapp]
	public let indentation: Indentation
	public let getDetailedConnectedDapp: (OnNetwork.ConnectedDapp) -> OnNetwork.ConnectedDappDetailed
}

extension ConnectedDappsView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Connected Dapps")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if connectedDapps.isEmpty {
				Text("<None yet>").font(.callout)
			} else {
				ForEach(connectedDapps) { connectedDapp in
					ConnectedDappView(
						connectedDapp: connectedDapp,
						indentation: inOneLevel,
						authorizedPersonas: getDetailedConnectedDapp(connectedDapp).detailedAuthorizedPersonas
					)
				}
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - ConnectedDappView
public struct ConnectedDappView: IndentedView {
	public let connectedDapp: OnNetwork.ConnectedDapp
	public let indentation: Indentation
	public let authorizedPersonas: IdentifiedArrayOf<OnNetwork.AuthorizedPersonaDetailed>
}

extension ConnectedDappView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Name", value: String(describing: connectedDapp.displayName))
			Labeled("Dapp def address", value: String(describing: connectedDapp.dAppDefinitionAddress))
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
	public let detailedAuthorizedPersona: OnNetwork.AuthorizedPersonaDetailed
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

// MARK: - P2PClientView
public struct P2PClientView: IndentedView {
	public let p2pClient: P2PClient
	public let indentation: Indentation
}

extension P2PClientView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("P2P Client")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("ID", value: String(p2pClient.id.hex().mask(showLast: 6)))
			Labeled("Client Name", value: p2pClient.displayName)
			Labeled("First established", value: p2pClient.firstEstablishedOn.ISO8601Format())
			Labeled("Last used", value: p2pClient.lastUsedOn.ISO8601Format())
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - PerNetworkView
public struct PerNetworkView: IndentedView {
	public let perNetwork: PerNetwork
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
			ForEach(perNetwork.dictionary.keys, id: \.self) { networkID in
				OnNetworkView(
					onNetwork: try! perNetwork.onNetwork(id: networkID),
					indentation: inOneLevel
				)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

// MARK: - OnNetworkView
public struct OnNetworkView: IndentedView {
	public let onNetwork: OnNetwork
	public let indentation: Indentation
}

extension OnNetworkView {
	public var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("ID", value: String(describing: onNetwork.networkID))

			AccountsView(
				entities: onNetwork.accounts.rawValue.elements,
				indentation: inOneLevel
			)

			PersonasView(
				entities: onNetwork.personas.elements,
				indentation: inOneLevel
			)

			ConnectedDappsView(
				connectedDapps: onNetwork.connectedDapps.elements,
				indentation: inOneLevel
			) {
				try! onNetwork.detailsForConnectedDapp($0)
			}
		}
		.padding([.leading], leadingPadding)
	}
}

public typealias AccountsView = EntitiesView<OnNetwork.Account>
public typealias PersonasView = EntitiesView<OnNetwork.Persona>

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
				ForEach(entities, id: \.index) { entity in
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

			Labeled("Index", value: String(describing: entity.index))
			Labeled("Address", value: entity.address.address)
			Labeled("Derivation Path", value: entity.derivationPath.derivationPath)
			switch entity.securityState {
			case let .unsecured(unsecuredControl):
				UnsecuredEntityControlView(
					unsecuredControl: unsecuredControl,
					indentation: inOneLevel
				)
			}

			if let persona = self.entity as? OnNetwork.Persona {
				Group {
					Text("Persona fields")
					ForEach(persona.fields) { field in
						Labeled(field.kind.rawValue, value: field.value.rawValue)
					}
				}.padding([.leading], indentation.inOneLevel.leadingPadding)
			}
			if let account = self.entity as? OnNetwork.Account {
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
				factorInstance: unsecuredControl.genesisFactorInstance.any(),
				indentation: inOneLevel
			)
		}
	}
}

// MARK: - FactorInstanceView
public struct FactorInstanceView: IndentedView {
	public let factorInstance: any FactorInstanceProtocol
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

			Labeled("ID", value: String(factorInstance.factorInstanceID.id.mask(showLast: 6)))
			Labeled("Kind", value: factorInstance.factorInstanceKind.rawValue)
			Labeled("Initialized On", value: factorInstance.initializationDate.ISO8601Format())
			Labeled("Factor Source ID", value: String(factorInstance.factorSourceReference.factorSourceID.id.mask(showLast: 6)))
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
