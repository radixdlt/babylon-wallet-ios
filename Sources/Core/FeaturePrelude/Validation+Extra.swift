@_spi(Validation) import Prelude
import SwiftUI

// MARK: Vanilla SwiftUI Validation

extension Binding {
	@_disfavoredOverload
	public static func validation<Value, Error>(
		_ validation: Binding<Validation<Value, Error>>
	) -> Binding<Value?> {
		.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}

	public static func validation<S: StringProtocol, Error>(
		_ validation: Binding<Validation<S, Error>>
	) -> Binding<S> {
		.validation(validation) ?? ""
	}
}

extension Binding {
	public subscript<V, Error, T>(
		dynamicMember keyPath: KeyPath<Validated<V, Error>, T?>
	) -> T? where Value == Validation<V, Error> {
		wrappedValue.validated?[keyPath: keyPath]
	}
}

#if DEBUG
struct VanillaValidationPreview: PreviewProvider {
	@MainActor
	struct VanillaValidationView: View {
		@State
		@Validation<String, String>(
			onNil: "Cannot be nil",
			rules: [
				.if(\.isEmpty, error: "Cannot be empty"),
				.if(\.isBlank, error: "Cannot be blank"),
			]
		)
		var name: String? = nil

		var body: some View {
			VStack(alignment: .leading) {
				TextField(
					"Name",
					text: .validation($name),
					prompt: Text("Name")
				)
				.textFieldStyle(.roundedBorder)

				if let error = $name.errors?.first {
					Text(error)
						.foregroundColor(.red)
						.font(.footnote)
				}
			}
			.padding()
		}
	}

	static var previews: some View {
		VanillaValidationView()
	}
}
#endif

// MARK: TCA Validation

import ComposableArchitecture

extension ViewStore {
	public func validation<Value, Error>(
		get: @escaping (ViewState) -> Validation<Value, Error>,
		send valueToAction: @escaping (Value?) -> ViewAction
	) -> Binding<Value?> {
		.validation(self.binding(get: get, send: { valueToAction($0.rawValue) }))
	}

	public func validation<S: StringProtocol, Error>(
		get: @escaping (ViewState) -> Validation<S, Error>,
		send valueToAction: @escaping (S) -> ViewAction
	) -> Binding<S> {
		.validation(self.binding(get: get, send: { valueToAction($0.rawValue ?? "") }))
	}
}

#if DEBUG
struct TCAValidationPreview: PreviewProvider {
	struct TCAValidation: Sendable, ReducerProtocol {
		struct State: Hashable {
			@Validation<String, String>(
				onNil: "Cannot be nil",
				rules: [
					.if(\.isEmpty, error: "Cannot be empty"),
					.if(\.isBlank, error: "Cannot be blank"),
				]
			)
			var name: String? = nil
		}

		enum Action: Equatable {
			case nameTextFieldChanged(String)
		}

		struct ViewState: Equatable {
			@Validation<String, String> var name: String?

			init(state: State) {
				self._name = state.$name
			}
		}

		func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case let .nameTextFieldChanged(name):
				state.name = name
				return .none
			}
		}

		@MainActor
		struct View: SwiftUI.View {
			private let store: StoreOf<TCAValidation>

			init(store: StoreOf<TCAValidation>) {
				self.store = store
			}

			var body: some SwiftUI.View {
				WithViewStore(store, observe: ViewState.init(state:)) { viewStore in
					VStack(alignment: .leading) {
						TextField(
							"Name",
							text: viewStore.validation(
								get: \.$name,
								send: { .nameTextFieldChanged($0) }
							),
							prompt: Text("Name")
						)
						.textFieldStyle(.roundedBorder)

						if let error = viewStore.$name.errors?.first {
							Text(error)
								.foregroundColor(.red)
								.font(.footnote)
						}
					}
					.padding()
				}
			}
		}
	}

	static var previews: some View {
		TCAValidation.View(
			store: Store(
				initialState: TCAValidation.State(),
				reducer: TCAValidation()
			)
		)
	}
}
#endif
