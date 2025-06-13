//
//  ContentView.swift
//  MQTT_test
//
//  Created by k22036kk on 2025/05/21.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @StateObject private var mqttClient = MQTT.shared
    @StateObject private var locationManager = Location()
    
    @State private var isSending = false
    
    var body: some View {
        Group{
            NavigationSplitView {
                NavigationStack {
                    MessageListView(items: items, onDelete: deleteItems)
                    .onChange(of: mqttClient.receivedMessage) { _, newValue in
                        print("New value: \\(newValue)")
                        withAnimation {
                            let newItem = Item(msg: newValue)
                            modelContext.insert(newItem)
                        }
                    }
                    .onChange(of: locationManager.currentLocation) { _, newValue in
                        guard let location = newValue else { return }
                        
                        if isSending {
                            send(msg: "Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        }
                    }
                    // ここからボタンを追加
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button(action: { isSending.toggle() }) {
                                Label(isSending ? "位置情報送信中" : "位置情報送信", systemImage: isSending ? "location.fill" : "location")
                            }
                            .help("位置情報の自動送信をON/OFFします")
                            
                            Spacer() // 右寄せにするためにSpacerを追加
                            EditButton()
                        }

                        HStack {
                            Button(action: { send() }) {
                                Label("メッセージ送信", systemImage: "paperplane")
                            }
                            .help("MQTTでメッセージを送信します")
                            
                            Button(action: sync) {
                                Label("購読開始", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .help("MQTTの購読を開始します")
                            
                            Button(action: { mqttClient.startRTTTest() }) {
                                Label("RTT計測", systemImage: "timer")
                            }
                            .help("100回のRTT（往復遅延）を計測します")
                        }
                    }
                    .padding() // ボタン群にパディングを追加
                    // ここまでボタンを追加
                }
            } detail: {
                VStack {
                    Text("Select an item")
                    // RTT平均遅延表示
                    if let avg = mqttClient.averageRTT {
                        Text(String(format: "平均RTT: %.2f ms", avg))
                            .font(.headline)
                            .foregroundColor(.blue)
                    } else if mqttClient.rttTestActive {
                        HStack(spacing: 0) {
                            Text("RTT計測中... (")
                            Text("\(mqttClient.rttResults.count)/100")
                            Text(")")
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear() {
            mqttClient.connect()
        }
        .onDisappear() {
            mqttClient.disconnect()
        }
    }
    
    private func send(msg: String = "hello") {
        Task {
            do {
                try await mqttClient.publish(message: msg)
            } catch {
                print("Error publishing message: \(error)")
            }
        }
    }
    
    private func sync() {
        Task {
            do {
                try await mqttClient.subscribe()
            } catch {
                print("Error subscribing: \(error)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct MessageListView: View {
    let items: [Item] // @Query private var items: [Item] から変更
    var onDelete: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    Text("\(item.msg)")
                } label: {
                    Text("\(item.msg)")
                }
            }
            .onDelete(perform: onDelete)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
