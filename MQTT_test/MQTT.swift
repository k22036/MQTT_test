//
//  MQTT.swift
//  MQTT_test
//
//  Created by k22036kk on 2025/05/21.
//

import Foundation
import NIO
import MQTTNIO

@MainActor
class MQTT: ObservableObject {
    static let shared = MQTT(host: "10.0.2.209", port: 1883, identifier: "MQTT_test")
    
    var client: MQTTClient
    var host: String
    var port: Int
    var identifier: String
    
    private enum MQTTVersion {
        case v3_1_1, v5_0
    }
    private let version = MQTTVersion.v3_1_1
    
    @Published var receivedMessage: String = ""
    
    init(host: String, port: Int, identifier: String) {
        self.host = host
        self.port = port
        self.identifier = identifier
        self.client = MQTTClient(
            host: host,
            port: port,
            identifier: identifier,
            eventLoopGroupProvider: .shared(.singletonNIOTSEventLoopGroup),
            configuration: .init(version: version == .v5_0 ? .v5_0 : .v3_1_1)
        )
    }
    
    func connect() {
        if version == .v5_0 {
            client.v5.connect().whenComplete { result in
                switch result {
                case .success:
                    print("Connected to MQTT broker")
                case .failure(let error):
                    print("Failed to connect: \(error)")
                }
            }
        } else {
            client.connect().whenComplete { result in
                switch result {
                case .success:
                    print("Connected to MQTT broker")
                case .failure(let error):
                    print("Failed to connect: \(error)")
                }
            }
        }
    }
    
    func disconnect() {
        if version == .v5_0 {
            client.v5.disconnect().whenComplete { result in
                switch result {
                case .success:
                    print("Disconnected from MQTT broker")
                case .failure(let error):
                    print("Failed to disconnect: \(error)")
                }
            }
        } else {
            client.disconnect().whenComplete { result in
                switch result {
                case .success:
                    print("Disconnected from MQTT broker")
                case .failure(let error):
                    print("Failed to disconnect: \(error)")
                }
            }
        }
    }
    
    func subscribe() async throws {
        let topicFilter = "node-to-ios" // Define for reuse and clarity
        
        if version == .v5_0 {
            let info = MQTTSubscribeInfoV5(topicFilter: topicFilter, qos: .exactlyOnce)
            let sub = try await client.v5.subscribe(to: [info])
            print("Subscribed to topic: \(sub.properties)")
        } else {
            let info = MQTTSubscribeInfo(topicFilter: topicFilter, qos: .exactlyOnce)
            let sub = try await client.subscribe(to: [info])
            print("Subscribed to topic: \(sub)")
        }
        
        // 既存リスナーを削除して重複登録を防ぐ (Remove existing listener to prevent duplicates)
        let listenerName = "node-to-ios-listener"
        client.removePublishListener(named: listenerName)
        client.addPublishListener(named: listenerName) { messageResult in
            do {
                let mqttMessage = try messageResult.get() // Extract MQTTMessage from Result
                
                // トピック名を確認してから処理 (Check topic name before processing)
                if mqttMessage.topicName == topicFilter {
                    let msg = String(buffer: mqttMessage.payload) // Assumes UTF-8 string payload.
                    
                    DispatchQueue.main.async {
                        self.receivedMessage = msg
                    }
                    print("Received message: '\(msg)' on topic '\(mqttMessage.topicName)'")
                }
            } catch {
                print("Error receiving message: \(error)")
            }
        }
    }
    
    func publish(message: String) async throws {
        let payload = ByteBufferAllocator().buffer(string: message)
        if version == .v5_0 {
            let pub = try await client.v5.publish(to: "ios-to-node", payload: payload, qos: .exactlyOnce)
            print("Published message: \(pub.debugDescription)")
            print("Published message: \(message)")
        } else {
            let pub: () = try await client.publish(to: "ios-to-node", payload: payload, qos: .exactlyOnce)
            print("Published message: \(pub)")
            print("Published message: \(message)")
        }
    }
}
