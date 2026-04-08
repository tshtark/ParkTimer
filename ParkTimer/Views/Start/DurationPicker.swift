import SwiftUI

struct DurationPicker: View {
    @Binding var minutes: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let minuteOptions = Array(stride(from: 5, through: 480, by: 5))

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Custom Duration")
                    .font(.headline)

                Picker("Minutes", selection: $minutes) {
                    ForEach(minuteOptions, id: \.self) { min in
                        Text(TimeFormatting.durationText(TimeInterval(min * 60)))
                            .tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)

                Button {
                    onConfirm()
                } label: {
                    Text("Set Duration")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#4ade80"))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
