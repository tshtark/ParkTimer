import SwiftUI

struct AlertSoundPicker: View {
    @Bindable var settings: SettingsManager

    var body: some View {
        List {
            ForEach(AlertSound.allCases, id: \.self) { sound in
                Button {
                    settings.selectedAlertSound = sound
                    AudioManager.shared.preview(sound)
                } label: {
                    HStack {
                        Text(sound.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.selectedAlertSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: "#4ade80"))
                        }
                    }
                }
            }
        }
        .navigationTitle("Alert Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}
