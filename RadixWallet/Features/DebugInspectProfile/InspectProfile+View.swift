import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ProfileView
struct ProfileView: IndentedView {
	let profile: Profile
	let indentation: Indentation

	init(
		profile: Profile,
		indentation: Indentation = .init()
	) {
		self.profile = profile
		self.indentation = indentation
	}
}

// MARK: - Indentation
struct Indentation {
	let indentationLevel: Int
	let pointsToIndentPerLevel: CGFloat

	init(
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
	var leadingPadding: CGFloat {
		CGFloat(indentationLevel) * pointsToIndentPerLevel
	}

	var spacing: CGFloat {
		CGFloat(
			Double(128) / pow(2.0, Double(indentationLevel))
		)
	}
}

extension ProfileView {
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: indentation.spacing) {
				HeaderView(
					header: profile.header,
					indentation: inOneLevel
				)

				PerNetworkView(
					networks: profile.networks.asIdentified(),
					indentation: inOneLevel
				)

				AppPreferencesView(
					appPreferences: profile.appPreferences,
					indentation: inOneLevel
				)

				FactorSourcesView(
					factorSources: profile.factorSources.asIdentified(),
					indentation: inOneLevel
				)
			}
		}
	}
}

// MARK: - IndentedView
protocol IndentedView: SwiftUI.View {
	var indentation: Indentation { get }
}

extension IndentedView {
	var inOneLevel: Indentation {
		indentation.inOneLevel
	}

	var leadingPadding: CGFloat {
		indentation.leadingPadding
	}
}

// MARK: - HeaderView
struct HeaderView: IndentedView {
	let header: Profile.Header
	let indentation: Indentation

	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("ID", value: header.id)
			Labeled("Snapshot version", value: header.snapshotVersion.rawValue)
			CreatingDeviceView(device: header.creatingDevice, indentation: inOneLevel)
			HeaderHintView(hint: header.contentHint, indentation: inOneLevel)
		}
	}
}

// MARK: - CreatingDeviceView
struct CreatingDeviceView: IndentedView {
	let device: DeviceInfo
	let indentation: Indentation

	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Device ID", value: device.id)
			Labeled("Creation date", value: device.date.ISO8601Format())
			Labeled("Device", value: device.description)
		}
	}
}

// MARK: - HeaderHintView
struct HeaderHintView: IndentedView {
	let hint: ContentHint
	let indentation: Indentation

	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("#Networks", value: hint.numberOfNetworks)
			Labeled("#Accounts", value: hint.numberOfAccountsOnAllNetworksInTotal)
			Labeled("#Personas", value: hint.numberOfPersonasOnAllNetworksInTotal)
		}
	}
}

// MARK: - FactorSourcesView
struct FactorSourcesView: IndentedView {
	let factorSources: FactorSources
	let indentation: Indentation
}

extension FactorSourcesView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Factor Sources")
				.fontWeight(.heavy)
				.textCase(.uppercase)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			ForEach(factorSources) { factorSource in
				DebugInspectFactorSourceView(
					factorSource: factorSource,
					indentation: inOneLevel
				)
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - DebugInspectFactorSourceView
struct DebugInspectFactorSourceView: IndentedView {
	let factorSource: FactorSource
	let indentation: Indentation
}

extension DebugInspectFactorSourceView {
	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text("Factor Source")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("ID", value: factorSource.id)

			switch factorSource {
			case let .device(deviceFactorSource):
				DeviceFactorSouceView(deviceFactorSource: deviceFactorSource)
			case let .ledger(ledgerFactorSource):
				LedgerFactorSourceView(ledgerFactorSource: ledgerFactorSource)
			default: fatalError("DISCREPANCY: Found non .device | .ledger factor source. A real world user cannot possible have this.")
			}
			FactorSourceCommonView(common: factorSource.common)
		}
		.background {
			Color.randomDark(seed: factorSource.id.description.data(using: .utf8)!)
		}
		.foregroundColor(.primaryText)
		.padding(.leading, leadingPadding)
		.overlay {
			if factorSource.isExplicitMain {
				RoundedRectangle(cornerRadius: 4)
					.stroke(.green, lineWidth: 10)
			}
		}
	}
}

// MARK: - FactorSourceCommonView
struct FactorSourceCommonView: View {
	let common: FactorSourceCommon
	var body: some View {
		Labeled("Added On", value: common.addedOn.ISO8601Format())
		Labeled("LastUsed On", value: common.lastUsedOn.ISO8601Format())
		Labeled("Supported Curves", value: common.cryptoParameters.supportedCurves.map { String(describing: $0) }.joined(separator: ", "))
		Labeled("Supported Derivation", value: common.cryptoParameters.supportedDerivationPathSchemes.map { String(describing: $0) }.joined(separator: ", "))
	}
}

// MARK: - DeviceFactorSouceView
struct DeviceFactorSouceView: View {
	let deviceFactorSource: DeviceFactorSource
	var isMain: Bool { deviceFactorSource.common.flags.contains(.main) }
	var body: some View {
		Labeled("Is Main?", value: isMain)
			.fontWeight(.heavy)
		Labeled("Name", value: deviceFactorSource.hint.label)
		Labeled("Device Name", value: deviceFactorSource.hint.deviceName)
		Labeled("Model", value: deviceFactorSource.hint.model)
	}
}

// MARK: - LedgerFactorSourceView
struct LedgerFactorSourceView: View {
	let ledgerFactorSource: LedgerHardwareWalletFactorSource
	var body: some View {
		Labeled("Name", value: ledgerFactorSource.hint.label)
		Labeled("Model", value: ledgerFactorSource.hint.model.rawValue)
	}
}

// MARK: - AppPreferencesView
struct AppPreferencesView: IndentedView {
	let appPreferences: AppPreferences
	let indentation: Indentation
}

extension AppPreferencesView {
	var body: some View {
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
				savedGateways: appPreferences.gateways,
				indentation: inOneLevel
			)

			AppSecurityView(
				security: appPreferences.security,
				indentation: inOneLevel
			)
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - GatewaysView
struct GatewaysView: IndentedView {
	let savedGateways: SavedGateways
	let indentation: Indentation
}

extension GatewaysView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			ForEach(savedGateways.all) { gateway in
				GatewayView(
					gateway: gateway,
					isCurrent: savedGateways.current == gateway,
					indentation: inOneLevel
				)
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - GatewayView
struct GatewayView: IndentedView {
	let gateway: Gateway
	let isCurrent: Bool
	let indentation: Indentation
}

extension GatewayView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network & Gateway")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("Network Name", value: gateway.network.logicalName)
			Labeled("Network ID", value: gateway.network.id.description)
			if isCurrent {
				Text("Is current gateway ✅")
			}
			Labeled("Gateway API Base URL", value: gateway.url.absoluteString)
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - DisplayView
struct DisplayView: IndentedView {
	let display: AppDisplay
	let indentation: Indentation
}

extension DisplayView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Display")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("Currency", value: display.fiatCurrencyPriceTarget.rawValue)
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - AppSecurityView
struct AppSecurityView: IndentedView {
	let security: Security
	let indentation: Indentation
}

extension AppSecurityView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("App Security")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			Labeled("isCloudProfileSyncEnabled", value: String(describing: security.isCloudProfileSyncEnabled))
			Labeled("isDeveloperModeEnabled", value: String(describing: security.isDeveloperModeEnabled))
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - AuthorizedDappsView
struct AuthorizedDappsView: IndentedView {
	let authorizedDapps: AuthorizedDapps
	let indentation: Indentation
	let getDetailedAuthorizedDapp: (AuthorizedDapp) -> AuthorizedDappDetailed?
}

extension AuthorizedDappsView {
	var body: some View {
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
						authorizedPersonas: getDetailedAuthorizedDapp(authorizedDapp)?.detailedAuthorizedPersonas.asIdentified()
					)
				}
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - AuthorizedDappView
struct AuthorizedDappView: IndentedView {
	let authorizedDapp: AuthorizedDapp
	let indentation: Indentation
	let authorizedPersonas: DetailedAuthorizedPersonas?
}

extension AuthorizedDappView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Name", value: String(describing: authorizedDapp.displayName))
			Labeled("Dapp def address", value: String(describing: authorizedDapp.dAppDefinitionAddress))

			if let authorizedPersonas {
				ForEach(authorizedPersonas) {
					DappAuthorizedPersonaView(
						detailedAuthorizedPersona: $0,
						indentation: inOneLevel
					)
				}
			} else {
				Text("No authorized personas")
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - DappAuthorizedPersonaView
struct DappAuthorizedPersonaView: IndentedView {
	let detailedAuthorizedPersona: AuthorizedPersonaDetailed
	let indentation: Indentation
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("Address", value: detailedAuthorizedPersona.identityAddress)
			Labeled("Name", value: detailedAuthorizedPersona.displayName.rawValue)

			Text("Shared Fields")
			Group {
				let sharedPersonaData = detailedAuthorizedPersona.sharedPersonaData

				if let name = sharedPersonaData.name {
					Text("Name")
					Labeled(L10n.AuthorizedDapps.PersonaDetails.givenName, value: name.value.givenNames)
					Labeled(L10n.AuthorizedDapps.PersonaDetails.nickname, value: name.value.nickname)
					Labeled(L10n.AuthorizedDapps.PersonaDetails.nameFamily, value: name.value.familyName)
					Labeled("id", value: name.id)
				}

				Text("Emails")
				ForEach(sharedPersonaData.emailAddresses.collection) { email in
					Labeled("Value", value: email.value.email)
					Labeled("id", value: email.id)
				}

				Text("Phonenumbers")
				ForEach(sharedPersonaData.phoneNumbers.collection) { phone in
					Labeled("Value", value: phone.value.number)
					Labeled("id", value: phone.id)
				}
			}

			Text("Shared Accounts")
			if let simpleAccounts = detailedAuthorizedPersona.simpleAccounts {
				if !simpleAccounts.isEmpty {
					ForEach(simpleAccounts) { simpleAccount in
						Labeled("displayName", value: simpleAccount.displayName.rawValue)
						Labeled("address", value: simpleAccount.address.address)
						Labeled("appearanceID", value: simpleAccount.appearanceId.description)
					}
				} else {
					Text("None yet")
				}
			} else {
				Text("Never requested")
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - PerNetworkView
struct PerNetworkView: IndentedView {
	let networks: ProfileNetworks
	let indentation: Indentation
}

extension PerNetworkView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Per Network")
				.fontWeight(.heavy)
				.textCase(.uppercase)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			ForEach(networks, id: \.self) { network in
				ProfileNetworkView(
					network: network,
					indentation: inOneLevel
				)
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - ProfileNetworkView
struct ProfileNetworkView: IndentedView {
	let network: ProfileNetwork
	let indentation: Indentation
}

extension ProfileNetworkView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("Network")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("ID", value: String(describing: network.id))

			AccountsView(
				areHidden: false,
				entities: network.getAccounts().elements,
				indentation: inOneLevel
			)

			AccountsView(
				areHidden: true,
				entities: network.getHiddenAccounts().elements,
				indentation: inOneLevel
			)

			PersonasView(
				areHidden: false,
				entities: network.getPersonas().elements,
				indentation: inOneLevel
			)

			PersonasView(
				areHidden: true,
				entities: network.getHiddenPersonas().elements,
				indentation: inOneLevel
			)

			AuthorizedDappsView(
				authorizedDapps: network.authorizedDapps.asIdentified(),
				indentation: inOneLevel
			) {
				try? network.detailsForAuthorizedDapp($0)
			}
		}
		.padding(.leading, leadingPadding)
	}
}

typealias AccountsView = EntitiesView<Account>
typealias PersonasView = EntitiesView<Persona>

// MARK: - EntitiesView
struct EntitiesView<Entity: EntityProtocol>: IndentedView {
	let areHidden: Bool
	let entities: [Entity]
	let indentation: Indentation
}

extension EntitiesView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			if areHidden {
				Text("HIDDEN")
					.fontWeight(.heavy)
			}
			Text(Entity.kind == .persona ? "Personas" : "Accounts")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)
			if entities.isEmpty {
				Text("<None yet>")
			} else {
				ForEach(entities, id: \.address) { entity in
					EntityView(
						isHidden: areHidden,
						entity: entity,
						indentation: inOneLevel
					)
				}
			}
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - EntityView
struct EntityView<Entity: EntityProtocol>: IndentedView {
	let isHidden: Bool
	let entity: Entity
	let indentation: Indentation
}

extension EntityView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Labeled("DisplayName", value: entity.displayName.rawValue)
			Labeled("Address", value: entity.address.address)

			if let factorInstance = entity.unsecuredControllingFactorInstance {
				UnsecuredEntityControlView(
					unsecuredControl: UnsecuredEntityControl(transactionSigning: factorInstance, provisionalSecurifiedConfig: nil),
					indentation: inOneLevel
				)
			}

			Group {
				if let persona = self.entity as? Persona {
					Text("Persona fields")
					ForEach(persona.personaData.entries, id: \.self) { entry in
						Labeled("id:\(entry.id)", value: String(describing: entry.value))
					}
				}
			}
			.padding(.leading, indentation.inOneLevel.leadingPadding)

			if let account = self.entity as? Account {
				Labeled("Account Appearance ID", value: account.appearanceID.description)
			}
		}
		.foregroundColor(isHidden ? .white : (entity.entityKind == .account ? .white : .black))
		.padding(.leading, leadingPadding)
		.background {
			if isHidden {
				Color.gray
			} else {
				if let account = entity as? Account {
					account.appearanceID.gradient
						.brightness(-0.2)
				}
			}
		}
	}
}

// MARK: - UnsecuredEntityControlView
struct UnsecuredEntityControlView: IndentedView {
	let unsecuredControl: UnsecuredEntityControl
	let indentation: Indentation
}

extension UnsecuredEntityControlView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			HierarchicalDeterministicFactorInstanceView(
				description: "Transaction Signing",
				factorInstance: unsecuredControl.transactionSigning,
				indentation: inOneLevel
			)
		}
	}
}

// MARK: - HierarchicalDeterministicFactorInstanceView
struct HierarchicalDeterministicFactorInstanceView: IndentedView {
	let description: String
	let factorInstance: HierarchicalDeterministicFactorInstance
	let indentation: Indentation
}

extension HierarchicalDeterministicFactorInstanceView {
	var body: some View {
		VStack(alignment: .leading, spacing: indentation.spacing) {
			Text("\(description) factor instance")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			Labeled("Derivation Path", value: factorInstance.derivationPath.description)
			Labeled("Key", value: factorInstance.publicKey.publicKey.hex)
			Labeled("Curve", value: factorInstance.publicKey.curve.description)
			Labeled("Factor Source ID", value: String(factorInstance.factorSourceID.description.mask(showLast: 6)))
		}
		.padding(.leading, leadingPadding)
	}
}

// MARK: - Labeled
struct Labeled: SwiftUI.View {
	let label: String
	let value: String
	init(_ label: String, value: String) {
		self.label = label
		self.value = value
	}

	init(_ label: String, value: some CustomStringConvertible) {
		self.init(label, value: String(describing: value))
	}

	var body: some View {
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
