import ChooseAccountsFeature
import FeaturePrelude
import ScanQRFeature

// MARK: - ChooseAccount.View
extension ChooseReceivingAccount {
	public struct ViewState: Equatable {
		var manualAccountAddress: String
		var manualAccountAddressFocused: Bool
		var chooseAccounts: ChooseAccounts.State
		var canSelectOwnAccount: Bool
		var validateAccountAddress: AccountAddress?
		var manualAddressHint: Hint?

		init(state: ChooseReceivingAccount.State) {
			manualAccountAddress = state.manualAccountAddress
			chooseAccounts = state.chooseAccounts
			manualAccountAddressFocused = state.manualAccountAddressFocused
			validateAccountAddress = state.validatedAccountAddress

			manualAddressHint = {
				guard !state.manualAccountAddressFocused, !state.manualAccountAddress.isEmpty else {
					return .none
				}

				guard let validateAccountAddress = state.validatedAccountAddress else {
					return .error("Invalid address")
				}

				if state.chooseAccounts.filteredAccounts.contains(where: { $0 == validateAccountAddress }) {
					return .error("Account already added")
				}
				return .none
			}()
			canSelectOwnAccount = manualAccountAddress.isEmpty
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseReceivingAccount>
		@FocusState private var focusedField: Bool

		public init(store: StoreOf<ChooseReceivingAccount>) {
			self.store = store
		}
	}
}

extension ChooseReceivingAccount.View {
	public var body: some View {
		NavigationStack {
			WithViewStore(store, observe: ChooseReceivingAccount.ViewState.init(state:), send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text("Enter an account address manually")
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)

						addressField(viewStore)
						Divider()

						Text("Or choose one of your own accounts")

						ChooseAccounts.View(
							store: store.scope(
								state: \.chooseAccounts,
								action: { .child(.chooseAccounts($0)) }
							)
						)
						.opacity(viewStore.canSelectOwnAccount ? 1.0 : 0.6)
						.disabled(!viewStore.canSelectOwnAccount)
					}
					.padding(.medium3)
				}
				.navigationDestination(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ChooseReceivingAccount.Destinations.State.scanAccountAddress,
					action: ChooseReceivingAccount.Destinations.Action.scanAccountAddress,
					destination: {
						ScanQRCoordinator.View(store: $0).navigationTitle("Scan QR Code")
					}
				)
				.footer { chooseButton(viewStore) }
				.navigationTitle("Choose Receiving Account")
				#if os(iOS)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								ViewStore(store.stateless).send(.view(.closeButtonTapped))
							}
						}
					}

				#endif
			}
		}
	}

	private func addressField(_ viewStore: ViewStoreOf<ChooseReceivingAccount>) -> some View {
		AppTextField(
			placeholder: "Enter or paste address",
			text: viewStore.binding(
				get: \.manualAccountAddress,
				send: { .manualAccountAddressChanged($0) }
			),
			hint: viewStore.manualAddressHint,
			focus: .on(
				true,
				binding: viewStore.binding(
					get: \.manualAccountAddressFocused,
					send: { .focusChanged($0) }
				),
				to: $focusedField
			),
			showClearButton: true,
			innerAccessory: {
				Button {
					viewStore.send(.scanQRCode)
				} label: {
					Image(asset: AssetResource.qrCodeScanner)
				}
			}
		)
		.autocorrectionDisabled()
	}

	private func chooseButton(_ viewStore: ViewStoreOf<ChooseReceivingAccount>) -> some View {
		WithControlRequirements(
			viewStore.chooseAccounts.selectedAccounts?.first?.account,
			or: viewStore.validateAccountAddress,
			forAction: { result in
				viewStore.send(.chooseButtonTapped(result))
			},
			control: { action in
				Button("Choose", action: action)
					.buttonStyle(.primaryRectangular)
			}
		)
	}
}
