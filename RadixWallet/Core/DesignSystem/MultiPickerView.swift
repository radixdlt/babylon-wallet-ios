struct MultiPickerView: UIViewRepresentable {
	var data: [[String]]
	@Binding var selections: [Int]

	func makeCoordinator() -> MultiPickerView.Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: UIViewRepresentableContext<MultiPickerView>) -> UIPickerView {
		let picker = UIPickerView()
		picker.dataSource = context.coordinator
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIView(_ uiView: UIPickerView, context: UIViewRepresentableContext<MultiPickerView>) {
		for i in 0 ..< selections.count {
			if i < uiView.numberOfComponents {
				uiView.selectRow(selections[i], inComponent: i, animated: false)
			}
		}
	}

	class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
		var parent: MultiPickerView

		init(_ parent: MultiPickerView) {
			self.parent = parent
		}

		func numberOfComponents(in pickerView: UIPickerView) -> Int {
			parent.data.count
		}

		func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
			parent.data[component].count
		}

		func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
			parent.data[component][row]
		}

		func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
			let label = UILabel()
			label.text = parent.data[component][row]
			label.font = .body1Regular
			label.textColor = UIColor(.primaryText)
			label.textAlignment = .center
			return label
		}

		func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
			guard component < parent.selections.count else { return }
			parent.selections[component] = row
		}
	}
}
