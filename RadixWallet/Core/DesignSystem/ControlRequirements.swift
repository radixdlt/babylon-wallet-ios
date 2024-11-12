import ComposableArchitecture
import SwiftUI

// MARK: - WithControlRequirements
// TODO: simplify with variadic generics in the future
//
// struct WithControlRequirements<Control: View>: View {
//     [...]
//
//     init<T...>(
//         _ requirements: @autoclosure () -> T?...,
//         forAction action: @escaping (T...) -> Void,
//         @ViewBuilder control: (@escaping () -> Void) -> Control
//     ) {
//         [...]
//     }
// }

struct WithControlRequirements<Control: View>: View {
	@Environment(\.controlState) var controlState

	let action: (() -> Void)?
	let control: Control

	init<A>(
		_ a: @autoclosure () -> A?,
		forAction action: @escaping (A) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = if let a = a() {
			{ action(a) }
		} else {
			nil
		}
		self.action = action
		self.control = control(action ?? {})
	}

	init<A, B>(
		_ a: @autoclosure () -> A?,
		_ b: @autoclosure () -> B?,
		forAction action: @escaping (A, B) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = if let a = a(), let b = b() {
			{ action(a, b) }
		} else {
			nil
		}
		self.action = action
		self.control = control(action ?? {})
	}

	init<A, B>(
		_ a: @autoclosure () -> A?,
		or b: @autoclosure () -> B?,
		forAction action: @escaping (Either<A, B>) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let controlAction: (() -> Void)? = {
			if let a = a() {
				return { action(.left(a)) }
			}

			if let b = b() {
				return { action(.right(b)) }
			}

			return nil
		}()
		self.action = controlAction
		self.control = control(controlAction ?? {})
	}

	init<A, B, C>(
		_ a: @autoclosure () -> A?,
		_ b: @autoclosure () -> B?,
		_ c: @autoclosure () -> C?,
		forAction action: @escaping (A, B, C) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = if let a = a(), let b = b(), let c = c() {
			{ action(a, b, c) }
		} else {
			nil
		}
		self.action = action
		self.control = control(action ?? {})
	}

	var body: some View {
		control.controlState(action == nil ? .disabled : controlState)
	}
}

#if DEBUG
import struct SwiftUINavigation.WithState

struct WithControlRequirements_Previews: PreviewProvider {
	static var previews: some View {
		WithState(initialValue: "") { $name in
			Form {
				TextField("Name", text: $name, prompt: Text("Name"))
			}
			.safeAreaInset(edge: .bottom, spacing: .zero) {
				WithControlRequirements(
					name.nilIfBlank,
					forAction: { name in loggerGlobal.debug("Hello \(name)!") }
				) { action in
					Button("Submit", action: action)
						.buttonStyle(.primaryRectangular)
						.padding()
				}
			}
		}
	}
}
#endif
