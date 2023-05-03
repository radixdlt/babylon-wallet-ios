import EditPersonaFeature
import FeaturePrelude

// MARK: - View

extension PersonaDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let thumbnail: URL?
		let personaName: String
		let isDappPersona: Bool
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

					Button(L10n.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					if viewStore.isDappPersona {
						IfLetStore(store.scope(state: \.accountSection, action: PersonaDetails.Action.view)) {
							AccountSection(store: $0)
								.background(.app.gray5)
						}

						Button(L10n.PersonaDetails.deauthorizePersona) {
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
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
		.sheet(store: store.scope(state: \.$editPersona, action: { .child(.editPersona($0)) })) {
			EditPersona.View(store: $0)
		}
		.alert(store: store.confirmForgetAlert)
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(thumbnail: nil, personaName: personaName, isDappPersona: isDappPersona)
	}

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

private extension PersonaDetails.Store {
	var confirmForgetAlert: AlertPresentationStore<PersonaDetails.ViewAction.ConfirmForgetAlert> {
		scope(state: \.$confirmForgetAlert) { .view(.confirmForgetAlert($0)) }
	}
}

// MARK: - AccountSection

extension PersonaDetails.State {
	var accountSection: AccountSection? {
		switch mode {
		case .general:
			return nil
		case let .dApp(dApp, persona):
			return .init(dAppName: dApp.displayName.rawValue, sharingAccounts: persona.simpleAccounts ?? [])
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
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.PersonaDetails.accountSharingDescription(viewStore.dAppName))
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

					Button(L10n.PersonaDetails.editAccountSharing) {
						viewStore.send(.editAccountSharingTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)
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
					Text(L10n.PersonaDetails.authorizedDappsDescription)
						.textBlock
						.flushedLeft
						.padding(.horizontal, .medium1)

					ForEach(viewStore.state) { dApp in
						Card {
							PlainListRow(title: dApp.displayName) {
								viewStore.send(.dAppTapped(dApp.id))
							} icon: {
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
				personaName: personaName,
				fields: persona.sharedFields ?? []
			)
		case let .general(persona, _):
			return .init(
				dAppInfo: nil,
				personaName: personaName,
				fields: persona.fields
			)
		}
	}

	var dAppInfo: PersonaDetails.View.InfoSection.ViewState.DappInfo? {
		guard case let .dApp(dApp, persona) = mode else { return nil }
		return .init(
			name: dApp.displayName.rawValue,
			isSharingNothing: persona.sharedFields.isNilOrEmpty
		)
	}
}

private extension PersonaDetails.View.InfoSection.ViewState {
	init(dAppInfo: DappInfo?, personaName: String, fields: IdentifiedArrayOf<Profile.Network.Persona.Field>) {
		self.init(
			dAppInfo: dAppInfo,
			personaName: personaName,
			firstName: fields[id: .givenName]?.value.rawValue,
			lastName: fields[id: .familyName]?.value.rawValue,
			emailAddress: fields[id: .emailAddress]?.value.rawValue,
			phoneNumber: fields[id: .phoneNumber]?.value.rawValue
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
			let firstName: String?
			let lastName: String?
			let emailAddress: String?
			let phoneNumber: String?

			struct DappInfo: Equatable {
				let name: String
				let isSharingNothing: Bool
			}
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.PersonaDetails.personaNameHeading, item: viewStore.personaName)

					Separator()

					if let dAppInfo = viewStore.dAppInfo {
						if dAppInfo.isSharingNothing {
							Text(L10n.PersonaDetails.notSharingAnything(dAppInfo.name))
								.textBlock
						} else {
							Text(L10n.PersonaDetails.personaDataSharingDescription(dAppInfo.name))
								.textBlock
						}
					}

					if let firstName = viewStore.firstName {
						VPair(heading: L10n.PersonaDetails.firstNameHeading, item: firstName)
					}

					if let lastName = viewStore.lastName {
						VPair(heading: L10n.PersonaDetails.lastNameHeading, item: lastName)
					}

					if let emailAddress = viewStore.emailAddress {
						VPair(heading: L10n.PersonaDetails.emailAddressHeading, item: emailAddress)
					}

					if let phoneNumber = viewStore.phoneNumber {
						VPair(heading: L10n.PersonaDetails.phoneNumberHeading, item: phoneNumber)
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}
