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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isSending.toggle() }) {
                        Label("Send", systemImage: isSending ? "checkmark.circle.fill" : "plus.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { send() }) {
                        Label("send", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    // sync button
                    Button(action: sync) {
                        Label("sync", systemImage: "arrow.clockwise")
                    }
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
