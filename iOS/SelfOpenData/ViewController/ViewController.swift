//
//  ViewController.swift
//  SelfOpenData
//
//  Created by 浅野　宏明 on 2018/05/17.
//  Copyright © 2018年 akylab. All rights reserved.
//

import UIKit
import MEMELib

class ViewController: UIViewController {

    @IBOutlet private weak var connectDeviceLabel: UILabel!

    @IBAction private func didTapHealthSend(_ sender: UIButton) {
        HKManager.shared.getAllData()
    }
    
    @IBAction private func didTapMEMESend(_ sender: UIButton) {
        MEMEManager.shared.sendFlg = !MEMEManager.shared.sendFlg
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MEMEManager.shared.delegate = self
    }
}

extension ViewController: MEMEManagerDelegate {
    func deviceConnected(id: String) {
        self.connectDeviceLabel.text = id
    }
    
    func dataRecieved(data: MEMERealTimeData) {
        // display value on screen
    }
}
