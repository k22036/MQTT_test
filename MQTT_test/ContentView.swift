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
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("\(item.msg)")
                        
                    } label: {
                        Text("\(item.msg)")
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                // 位置情報送信モード切替ボタン
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isSending.toggle() }) {
                        Label(isSending ? "位置情報送信中" : "位置情報送信", systemImage: isSending ? "location.fill" : "location")
                    }
                    .help("位置情報の自動送信をON/OFFします")
                }
                // 編集ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                // メッセージ送信ボタン
                ToolbarItem {
                    Button(action: { send() }) {
                        Label("メッセージ送信", systemImage: "paperplane")
                    }
                    .help("MQTTでメッセージを送信します")
                }
                // MQTT購読（サブスクライブ）ボタン
                ToolbarItem {
                    Button(action: sync) {
                        Label("購読開始", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .help("MQTTの購読を開始します")
                }
            }
            .onChange(of: mqttClient.receivedMessage) { _, newValue in
                print("New value: \(newValue)")
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
        } detail: {
            Text("Select an item")
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
