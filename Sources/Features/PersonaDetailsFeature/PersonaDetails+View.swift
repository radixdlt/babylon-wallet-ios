import CreateAuthKeyFeature
import EditPersonaFeature
import FeaturePrelude

// MARK: - View

extension PersonaDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<PersonaDetails>

		public init(store: StoreOf<PersonaDetails>) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let thumbnail: URL?
		let personaName: String
		let isDappPersona: Bool

		#if DEBUG
		public var canCreateAuthKey: Bool
		#endif // DEBUG
	}
}

// MARK: - Body

extension PersonaDetails.View {
	public var body: some View {
		ScrollView(showsIndicators: false) {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					PersonaThumbnail(viewStore.thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoSection(store: store.actionless)

					#if DEBUG
					VStack {
						Button("Create & Upload Auth Key") {
							viewStore.send(.createAndUploadAuthKeyButtonTapped)
						}
						.controlState(viewStore.canCreateAuthKey ? .enabled : .disabled)
						.buttonStyle(.secondaryRectangular)
					}
					.padding(.top, .large3)
					#endif

					Button(L10n.AuthorizedDapps.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					if viewStore.isDappPersona {
						IfLetStore(store.scope(state: \.accountSection, action: PersonaDetails.Action.view)) {
							AccountSection(store: $0)
								.background(.app.gray5)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.removeAuthorization) {
							viewStore.send(.deauthorizePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					} else {
						IfLetStore(store.scope(state: \.dAppsSection, action: PersonaDetails.Action.view)) {
							DappsSection(store: $0)
								.background(.app.gray5)
						}
					}
				}
				.navigationTitle(viewStore.personaName)
				#if os(iOS)
					.navigationBarTitleDisplayMode(.inline)
				#endif
					.onAppear {
						viewStore.send(.appeared)
					}
			}
		}
		.navigationDestination(
			store: store.destination,
			state: /PersonaDetails.Destination.State.dAppDetails,
			action: PersonaDetails.Destination.Action.dAppDetails,
			destination: { SimpleAuthDappDetails.View(store: $0) }
		)
		.sheet(
			store: store.destination,
			state: /PersonaDetails.Destination.State.editPersona,
			action: PersonaDetails.Destination.Action.editPersona,
			content: { EditPersona.View(store: $0) }
		)
		.sheet(
			store: store.destination,
			state: /PersonaDetails.Destination.State.createAuthKey,
			action: PersonaDetails.Destination.Action.createAuthKey,
			content: { CreateAuthKey.View(store: $0) }
		)
		.alert(
			store: store.destination,
			state: /PersonaDetails.Destination.State.confirmForgetAlert,
			action: PersonaDetails.Destination.Action.confirmForgetAlert
		)
	}
}

private extension StoreOf<PersonaDetails> {
	var destination: PresentationStoreOf<PersonaDetails.Destination> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	#if DEBUG
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona,
			canCreateAuthKey: canCreateAuthKey
		)
	}
	#else
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona
		)
	}
	#endif

	var personaName: String {
		switch mode {
		case let .general(persona, _):
			return persona.displayName.rawValue
		case let .dApp(_, persona):
			return persona.displayName.rawValue
		}
	}

	var isDappPersona: Bool {
		switch mode {
		case .general:
			return false
		case .dApp:
			return true
		}
	}
}

// MARK: - AccountSection

extension PersonaDetails.State {
	var accountSection: AccountSection? {
		switch mode {
		case .general:
			return nil
		case let .dApp(dApp, persona):
			return .init(dAppName: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName, sharingAccounts: persona.simpleAccounts ?? [])
		}
	}

	struct AccountSection: Equatable {
		let dAppName: String
		let sharingAccounts: OrderedSet<Profile.Network.AccountForDisplay>
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		let store: Store<PersonaDetails.State.AccountSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: identity) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.AuthorizedDapps.PersonaDetails.accountSharingDescription(viewStore.dAppName))
						.textBlock
						.flushedLeft
						.padding(.vertical, .medium2)
						.padding(.horizontal, .medium1)

					VStack(spacing: .medium3) {
						ForEach(viewStore.sharingAccounts) { account in
							SmallAccountCard(
								account.label.rawValue,
								identifiable: .address(.account(account.address)),
								gradient: .init(account.appearanceID)
							)
							.cornerRadius(.small1)
						}
					}
					.padding(.horizontal, .medium3)

					//	FIXME: Uncomment and enable the functionality
					//	Button(L10n.AuthorizedDapps.PersonaDetails.editAccountSharing) {
					//		viewStore.send(.editAccountSharingTapped)
					//	}
					//	.buttonStyle(.secondaryRectangular)
					//	.padding(.vertical, .large3)
				}
			}
		}
	}
}

// MARK: - DappsSection

extension PersonaDetails.State {
	var dAppsSection: DappsSection? {
		switch mode {
		case let .general(_, dApps):
			return dApps.isEmpty ? nil : dApps
		case .dApp:
			return nil
		}
	}

	typealias DappsSection = IdentifiedArrayOf<PersonaDetails.State.DappInfo>
}

// MARK: - PersonaDetails.View.DappsSection
extension PersonaDetails.View {
	@MainActor
	struct DappsSection: View {
		let store: Store<PersonaDetails.State.DappsSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium1) {
					Text(L10n.AuthorizedDapps.PersonaDetails.authorizedDappsHeading)
						.textBlock
						.flushedLeft
						.padding(.horizontal, .medium1)

					ForEach(viewStore.state) { dApp in
						Card {
							viewStore.send(.dAppTapped(dApp.id))
						} contents: {
							PlainListRow(title: dApp.displayName) {
								DappThumbnail(.known(dApp.thumbnail))
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
			.padding(.vertical, .medium2)
		}
	}
}

// MARK: - InfoSection

private extension PersonaDetails.State {
	var infoSectionViewState: PersonaDetails.View.InfoSection.ViewState {
		switch mode {
		case let .dApp(_, persona: persona):
			return .init(
				dAppInfo: dAppInfo,
				personaName: persona.displayName.rawValue,
				personaData: persona.sharedPersonaData
			)
		case let .general(persona, _):
			return .init(
				dAppInfo: nil,
				personaName: persona.displayName.rawValue,
				personaData: persona.personaData
			)
		}
	}

	var dAppInfo: PersonaDetails.View.InfoSection.ViewState.DappInfo? {
		guard case let .dApp(dApp, persona) = mode else { return nil }
		return .init(
			name: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
			isSharingNothing: persona.sharedPersonaData.entries.isEmpty
		)
	}
}

// MARK: - PersonaDetails.View.InfoSection
extension PersonaDetails.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppInfo: DappInfo?
			let personaName: String
			let companyName: String?
			let fullName: String?
			let dateOfBirth: Date?
			let emailAddresses: [String]?
			let phoneNumbers: [String]?
			let urls: [String]?
			let postalAddresses: [PersonaData.PostalAddress]?
			let creditCards: [PersonaData.CreditCard]?

			struct DappInfo: Equatable {
				let name: String
				let isSharingNothing: Bool
			}

			init(
				dAppInfo: DappInfo?,
				personaName: String,
				personaData: PersonaData?
			) {
				self.dAppInfo = dAppInfo
				self.personaName = personaName
				self.fullName = personaData?.name?.value.formatted
				self.emailAddresses = personaData?.emailAddresses.map(\.value.email)
				self.phoneNumbers = personaData?.phoneNumbers.map(\.value.number)

				self.dateOfBirth = personaData?.dateOfBirth?.value.date
				self.companyName = personaData?.companyName?.value.name
				self.urls = personaData?.urls.map(\.value.url)
				self.postalAddresses = personaData?.postalAddresses.map(\.value)
				self.creditCards = personaData?.creditCards.map(\.value)

				// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
				// we do not forget to handle it here.
				switch PersonaData.Entry.Kind.fullName {
				case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
				}
			}
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading, item: viewStore.personaName)

					Separator()

					if let dAppInfo = viewStore.dAppInfo {
						if dAppInfo.isSharingNothing {
							Text(L10n.AuthorizedDapps.PersonaDetails.notSharingAnything(dAppInfo.name))
								.textBlock
						} else {
							Text(L10n.AuthorizedDapps.PersonaDetails.personalDataSharingDescription(dAppInfo.name))
								.textBlock
						}
					}

					if let fullName = viewStore.fullName {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.fullName,
							item: fullName
						)
						Separator()
					}

					if let phoneNumber = viewStore.phoneNumbers?.first {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.phoneNumber,
							item: phoneNumber
						)
						Separator()
					}

					if let emailAddress = viewStore.emailAddresses?.first {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.emailAddress,
							item: emailAddress
						)
						Separator()
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}

// FIXME: Remove and make settings use stacks

// MARK: - SimpleDappDetails

extension SimpleAuthDappDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let title: String
		let description: String?
		let domain: URL?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let fungibles: [State.Resources.ResourceDetails]?
		let nonFungibles: [State.Resources.ResourceDetails]?
		let associatedDapps: [State.AssociatedDapp]?
		let personas: [Persona]
	}

	public struct Persona: Sendable, Hashable, Identifiable {
		public let id: Profile.Network.Persona.ID
		public let thumbnail: URL?
		public let displayName: String
	}
}

// MARK: - Body

extension SimpleAuthDappDetails.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					DappThumbnail(.known(viewStore.thumbnail), size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					FungiblesList(store: store)

					NonFungiblesListList(store: store)

					Personas(personas: viewStore.personas)
						.background(.app.gray5)
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.navigationTitle(viewStore.title)
			}
		}
	}
}

// MARK: - Extensions

private extension SimpleAuthDappDetails.State {
	var viewState: SimpleAuthDappDetails.ViewState {
		.init(
			title: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
			description: metadata?.description,
			domain: metadata?.claimedWebsites?.first,
			thumbnail: metadata?.iconURL,
			address: dApp.dAppDefinitionAddress,
			fungibles: resources?.fungible,
			nonFungibles: resources?.nonFungible,
			associatedDapps: associatedDapps,
			personas: dApp.detailedAuthorizedPersonas.map {
				.init(id: $0.id, thumbnail: nil, displayName: $0.displayName.rawValue)
			}
		)
	}
}

// MARK: Child Views

extension SimpleAuthDappDetails.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<SimpleAuthDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					Separator()

					if let description = viewStore.description {
						Text(description)
							.textBlock
							.flushedLeft

						Separator()
					}

					HStack(spacing: 0) {
						Text(L10n.AuthorizedDapps.DAppDetails.dAppDefinition)
							.sectionHeading

						Spacer(minLength: 0)

						AddressView(.address(.account(viewStore.address)))
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)
					}

					if let domain = viewStore.domain {
						Text(L10n.AuthorizedDapps.DAppDetails.website)
							.sectionHeading
						Button(domain.absoluteString) {
							viewStore.send(.openURLTapped(domain))
						}
						.buttonStyle(.url)
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large2)
			}
		}
	}

	@MainActor
	struct FungiblesList: View {
		let store: StoreOf<SimpleAuthDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.fungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.tokens, elements: viewStore.state, title: \.name) { resource in
					TokenThumbnail(.known(resource.iconURL), size: .small)
				}
			}
		}
	}

	@MainActor
	struct NonFungiblesListList: View {
		let store: StoreOf<SimpleAuthDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.nonFungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.nfts, elements: viewStore.state, title: \.name) { resource in
					NFTThumbnail(resource.iconURL, size: .small)
				}
			}
		}
	}

	@MainActor
	struct ListWithHeading<Element: Identifiable, Icon: View>: View {
		let heading: String
		let elements: [Element]?
		let title: (Element) -> String
		let icon: (Element) -> Icon

		var body: some View {
			if let elements, !elements.isEmpty {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(heading)
						.sectionHeading
						.padding(.horizontal, .medium1)

					ForEach(elements) { element in
						Card {
							PlainListRow(title: title(element), accessory: nil) {
								icon(element)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
				.padding(.bottom, .medium1)
			}
		}
	}

	@MainActor
	struct Personas: View {
		let personas: [SimpleAuthDappDetails.Persona]

		var body: some View {
			if personas.isEmpty {
				Text(L10n.AuthorizedDapps.DAppDetails.noPersonasHeading)
					.sectionHeading
					.flushedLeft
					.padding(.horizontal, .medium1)
					.padding(.vertical, .small2)
			} else {
				Text(L10n.AuthorizedDapps.DAppDetails.personasHeading)
					.sectionHeading
					.flushedLeft
					.padding(.horizontal, .medium1)
					.padding(.vertical, .small2)

				Separator()
					.padding(.bottom, .small2)

				ForEach(personas) { persona in
					Card {
						PlainListRow(title: persona.displayName, accessory: nil) {
							PersonaThumbnail(persona.thumbnail)
						}
					}
					.padding(.horizontal, .medium3)
				}
			}
		}
	}
}
