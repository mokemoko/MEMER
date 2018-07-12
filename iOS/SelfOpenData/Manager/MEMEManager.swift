//
//  MEMEManager.swift
//  SelfOpenData
//
//  Created by 浅野　宏明 on 2018/05/20.
//  Copyright © 2018年 akylab. All rights reserved.
//

import MEMELib

final class MEMEManager: NSObject {
    static let shared = MEMEManager()
    
    override private init() {}
    
    weak var delegate: MEMEManagerDelegate?
    
    /// データ送信フラグ
    /// TODO: manager外で判定
    var sendFlg = false
    
    /// 呼び出し10回に1回実行するための判定
    let rand: () -> Bool = ({
        var cnt = 0
        return {
            cnt = (cnt + 1) % 10
            return cnt == 0
        }
    })()
    
    /// 外部定義ファイルから設定値の読み込み
    ///
    /// - Returns: 設定値タプル
    private func readProperties() -> (clientId: String, clientSecret: String)? {
        guard let path = Bundle.main.path(forResource: "MEME-Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, String>,
            let clientId = dict["clientId"],
            let clientSecret = dict["clientSecret"] else {
            return nil
        }
        return (clientId, clientSecret)
    }
    
    func setup() {
        guard let properties = readProperties() else {
            assert(false, "MEME設定値の取得に失敗")
            return
        }
        MEMELib.setAppClientId(properties.clientId, clientSecret: properties.clientSecret)
        MEMELib.sharedInstance().delegate = self
        MEMELib.sharedInstance().setAutoConnect(true)
    }
}

extension MEMEManager: MEMELibDelegate {
    func memeAppAuthorized(_ status: MEMEStatus) {
        print("##### memeAppAuthorized ##### : \(status)")
        MEMELib.sharedInstance().startScanningPeripherals()
    }
    func memePeripheralFound(_ peripheral: CBPeripheral!, withDeviceAddress address: String!) {
        print("##### memePeripheralFound ##### : \(address)")
        MEMELib.sharedInstance().connect(peripheral)
    }
    func memeCommand(_ response: MEMEResponse) {
        print("##### memeCommand ##### : \(response)")
    }
    func memePeripheralConnected(_ peripheral: CBPeripheral!) {
        print("##### memePeripheralConnected #####")
        delegate?.deviceConnected(id: peripheral.identifier.uuidString)
    }
    func memePeripheralDisconnected(_ peripheral: CBPeripheral!) {
        print("##### memePeripheralDisconnected #####")
    }
    func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
        delegate?.dataRecieved(data: data)
        
        // 同期先端末へのデータ送信
        let dict: [String: Double] = [
            "roll": Double(data.roll),
            "pitch": Double(data.pitch),
            "yaw": Double(data.yaw),
            "blinkSpeed": Double(data.blinkSpeed)
        ]
        PeerManager.shared.send(data: NSKeyedArchiver.archivedData(withRootObject: dict))
        
        // TODO: 回数を間引くだけでなく、平均を送るようにする
        guard sendFlg && rand() else {
            return
        }

        FirebaseManager.shared.update(type: .meme, additionalPath: "now", data: [
            "fitError": data.fitError,
            "isWalking": data.isWalking,
            "noiseStatus": data.noiseStatus,
            "powerLeft": data.powerLeft,
            "eyeMoveUp": data.eyeMoveUp,
            "eyeMoveDown": data.eyeMoveDown,
            "eyeMoveLeft": data.eyeMoveLeft,
            "eyeMoveRight": data.eyeMoveRight,
            "blinkSpeed": data.blinkSpeed,
            "blinkStrength": data.blinkStrength,
            "roll": data.roll,
            "pitch": data.pitch,
            "yaw": data.yaw,
            "accX": data.accX,
            "accY": data.accY,
            "accZ": data.accX,
            ])
    }
}

protocol MEMEManagerDelegate: class {
    func deviceConnected(id: String)
    func dataRecieved(data: MEMERealTimeData)
}
