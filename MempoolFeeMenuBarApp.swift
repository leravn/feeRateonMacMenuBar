// Tiny mempool watcher
// @LazerErik
// Stay tiny 🤏
// Build new new internet on Bitcoin
// OpenOrdinal.dev


import SwiftUI
import Combine

@main
struct MempoolFeeMenuBarApp: App {
    @StateObject private var feeViewModel = FeeViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(feeViewModel)
        } label: {
            Text("\(feeViewModel.feeEmoji) \(feeViewModel.fastestFee) sat/vB")
                .bold()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - ViewModel

class FeeViewModel: ObservableObject {
    @Published var fastestFee: Int = 0
    @Published var halfHourFee: Int = 0
    @Published var hourFee: Int = 0
    @Published var economyFee: Int = 0
    @Published var minimumFee: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    init() {
        fetchFees()
        startTimer()
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchFees()
            }
    }

    func fetchFees() {
        guard let url = URL(string: "https://mempool.space/api/v1/fees/recommended") else {
            print("Invalid URL.")
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: MempoolFees.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error fetching fees:", error)
                    }
                },
                receiveValue: { [weak self] fees in
                    self?.fastestFee = fees.fastestFee
                    self?.halfHourFee = fees.halfHourFee
                    self?.hourFee = fees.hourFee
                    self?.economyFee = fees.economyFee
                    self?.minimumFee = fees.minimumFee
                    self?.objectWillChange.send()
                }
            )
            .store(in: &cancellables)
    }

    /// **Returns a colored emoji based on the fastest fee**
    var feeEmoji: String {
        switch fastestFee {
        case 1...5:
            return "🟢" // Green (Low fee)
        case 6...10:
            return "🔵" // Green (Low fee)
        case 11...30:
            return "🟡" // Yellow (Medium fee)
        case 31...50:
            return "🟠" // Orange (High fee)
        case 51...100:
            return "🔴" // Red (Very high fee)
        default:
            return "🟣" // Purple (Extreme congestion)
        }
    }
}

// MARK: - Model

struct MempoolFees: Codable {
    let fastestFee: Int
    let halfHourFee: Int
    let hourFee: Int
    let economyFee: Int
    let minimumFee: Int
}

// MARK: - View

struct ContentView: View {
    @EnvironmentObject var feeViewModel: FeeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fastest Fee: \(feeViewModel.feeEmoji) \(feeViewModel.fastestFee) sat/vB")
                .bold()

            Text("Half-Hour Fee: \(feeViewModel.halfHourFee) sat/vB")
            Text("Hour Fee: \(feeViewModel.hourFee) sat/vB")
            Text("Economy Fee: \(feeViewModel.economyFee) sat/vB")
            Text("Minimum Fee: \(feeViewModel.minimumFee) sat/vB")

            Divider()

            Button("Refresh Now") {
                feeViewModel.fetchFees()
            }
        }
        .padding()
        .frame(minWidth: 200)
    }
}
