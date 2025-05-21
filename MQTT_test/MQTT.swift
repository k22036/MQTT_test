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
    static let shared = MQTT(host: "10.0.1.10", port: 1883, identifier: "MQTT_test")
    
    var client: MQTTClient
    var host: String
    var port: Int
    var identifier: String
    
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
            configuration: .init(version: .v5_0)
        )
    }
    
    func connect() {
        client.v5.connect().whenComplete { result in
            switch result {
            case .success:
                print("Connected to MQTT broker")
            case .failure(let error):
                print("Failed to connect: \(error)")
            }
        }
    }
    
    func disconnect() {
        client.v5.disconnect().whenComplete { result in
            switch result {
            case .success:
                print("Disconnected from MQTT broker")
            case .failure(let error):
                print("Failed to disconnect: \(error)")
            }
        }
    }
    
    func subscribe() async throws {
        let info = MQTTSubscribeInfoV5(topicFilter: "hello", qos: .exactlyOnce)
        let sub = try await client.v5.subscribe(to: [info])
        print("Subscribed to topic: \(sub)")
        
        client.addPublishListener(named: "hello") { message in
            do {
                let payload = try message.get().payload
                let msg = String(buffer: payload)
                DispatchQueue.main.async {
                    self.receivedMessage = msg
                }
                print("Received message: \(msg)")
            } catch {
                print("Error receiving message: \(error)")
            }
        }
    }
    
    func publish(message: String) throws {
        let payload = ByteBufferAllocator().buffer(string: message)
        _ = try client.v5.publish(to: "hello", payload: payload, qos: .exactlyOnce).wait()
        print("Published message: \(message)")
    }
}
