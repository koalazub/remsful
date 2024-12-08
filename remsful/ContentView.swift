import SwiftUI
import pulsar
import HealthKit

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var updateTrigger = false
    @State private var isSimulated = false
    @State private var simulatedHeartRate: Double = 60.0
    @State private var simulatedRespiratoryRate: Double = 15.0
    @State private var showingHeartRate = true
    @State private var showingInputSheet = false
    @State private var manualInputRate: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            PulseViewRepresentable(duration: 60 / currentRate)
                .ignoresSafeArea()
                .id(updateTrigger)
            
            VStack {
                Spacer()
                
                Text("\(isSimulated ? "Simulated" : "Actual") \(showingHeartRate ? "Heart" : "Respiratory") Rate")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(currentRate, specifier: "%.0f") \(showingHeartRate ? "bpm" : "breaths/min")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .onTapGesture {
                        if isSimulated {
                            manualInputRate = String(format: "%.0f", currentRate)
                            showingInputSheet = true
                        }
                    }
                
                Spacer()
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Rate Type:")
                            .foregroundColor(.white)
                        Spacer()
                        Picker("Rate Type", selection: $showingHeartRate) {
                            Text("Heart").tag(true)
                            Text("Respiratory").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(Color.gray)
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Data Source:")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("Simulate", isOn: $isSimulated)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    
                    Button {
                        Task {
                            await updateRate()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Update Rate")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .task {
            await healthKitManager.requestAuthorization()
        }
        .sheet(isPresented: $showingInputSheet) {
            ManualInputView(rate: $manualInputRate, isHeartRate: showingHeartRate, onSave: saveManualInput)
        }
    }
    
    private var currentRate: Double {
        isSimulated ?
            (showingHeartRate ? simulatedHeartRate : simulatedRespiratoryRate) :
            (showingHeartRate ? healthKitManager.heartRate : healthKitManager.respiratoryRate)
    }
    
    private func updateRate() async {
        if isSimulated {
            if showingHeartRate {
                simulatedHeartRate = Double.random(in: 60...100)
            } else {
                simulatedRespiratoryRate = Double.random(in: 12...20)
            }
        } else {
            if showingHeartRate {
                await healthKitManager.fetchLatestHeartRate()
            } else {
                await healthKitManager.fetchLatestRespiratoryRate()
            }
        }
        updateTrigger.toggle()
    }
    
    private func saveManualInput() {
        if let rate = Double(manualInputRate) {
            if showingHeartRate {
                simulatedHeartRate = rate
            } else {
                simulatedRespiratoryRate = rate
            }
            updateTrigger.toggle()
        }
        showingInputSheet = false
    }
}

struct ManualInputView: View {
    @Binding var rate: String
    let isHeartRate: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter \(isHeartRate ? "Heart" : "Respiratory") Rate")) {
                    TextField("Rate", text: $rate)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Manual Input")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PulseViewRepresentable: UIViewRepresentable {
    var duration: TimeInterval
    
    func makeUIView(context: Context) -> PulseView {
        let pulseView = PulseView(frame: UIScreen.main.bounds)
        updatePulse(pulseView)
        return pulseView
    }
    
    func updateUIView(_ uiView: PulseView, context: Context) {
        updatePulse(uiView)
    }
    
    private func updatePulse(_ pulseView: PulseView) {
        pulseView.stopPulsing()
        let fuchsiaColor = UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0)
        pulseView.startPulsing(duration: duration, repeatCount: .infinity, color: fuchsiaColor)
        print("Pulse updated with duration: \(duration)")
    }
}
