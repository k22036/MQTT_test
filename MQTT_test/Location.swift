//
//  Location.swift
//  MQTT_test
//
//  Created by k22036kk on 2025/06/01.
//

import Foundation
import CoreLocation

class Location: NSObject, CLLocationManagerDelegate, ObservableObject {
    var locationManager: CLLocationManager!

    @Published var currentLocation: CLLocation? // 最新の位置情報


    override init() {
        super.init()

        // CLLocationManagerの初期化
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
//        バックグラウンドでのロケーション更新を許可
        locationManager.allowsBackgroundLocationUpdates = true
//        ロケーション更新の自動中断をオフ
        locationManager.pausesLocationUpdatesAutomatically = false

        // 位置情報使用許可をリクエスト（必須）
        locationManager.requestWhenInUseAuthorization()
        
        // 位置情報の更新を開始
        locationManager.startUpdatingLocation() // 位置情報取得の開始
    }
}

// CLLocationManagerDelegateメソッド
extension Location {
    // 位置情報の更新が行われたときに呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 最新の位置情報を取得
        if let location = locations.last {
            currentLocation = location
        }
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
}
