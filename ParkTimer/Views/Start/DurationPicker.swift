import SwiftUI

struct DurationPicker: View {
    @Binding var minutes: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedHours: Int = 1
    @State private var selectedMinutes: Int = 0

    private let hourOptions = Array(0...8)
    private let minuteOptions = [0, 5, 10, 15, 20, 30, 45]

    var totalMinutes: Int {
        selectedHours * 60 + selectedMinutes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Custom Duration")
                    .font(.headline)

                HStack(spacing: 0) {
                    // Hours picker
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(hourOptions, id: \.self) { h in
                            Text("\(h) hr").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()

                    // Minutes picker
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(minuteOptions, id: \.self) { m in
                            Text("\(m) min").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()
                }
                .frame(height: 180)

                // Summary
                Text(TimeFormatting.durationText(TimeInterval(totalMinutes * 60)))
                    .font(.title3.bold())
                    .foregroundStyle(totalMinutes > 0 ? Color(hex: "#4ade80") : .secondary)

                Button {
                    minutes = totalMinutes
                    onConfirm()
                } label: {
                    Text("Set Duration")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(totalMinutes > 0 ? Color(hex: "#4ade80") : Color(.systemGray4))
                        .foregroundStyle(totalMinutes > 0 ? .black : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(totalMinutes == 0)
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
        .onAppear {
            // Initialize from existing minutes value
            selectedHours = minutes / 60
            selectedMinutes = minuteOptions.min(by: { abs($0 - minutes % 60) < abs($1 - minutes % 60) }) ?? 0
        }
    }
}
